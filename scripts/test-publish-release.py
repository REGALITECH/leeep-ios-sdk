#!/usr/bin/env python3
"""Exercise publication decisions with no network access or real releases."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('publish-release.sh')
SHA = 'a' * 40


def release(tag, *, draft=False, prerelease=False):
    return {'tag_name': tag, 'draft': draft, 'prerelease': prerelease}


class PublishReleaseTests(unittest.TestCase):
    def run_publish(self, pages, *, tag='0.13.1', api_error=False, move_at=0, raw=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'bin').mkdir()
            validated = root / 'validated'
            validated.mkdir()
            (validated / 'validation.json').write_text(json.dumps({'tag': tag, 'sha': SHA}))
            (validated / 'release-notes.md').write_text('Reviewed release notes')
            (root / 'pages.json').write_text(json.dumps(pages) if raw is None else raw)
            stubs = {
                'gh': '''import json, os, pathlib, sys
root = pathlib.Path(os.environ['MOCK_ROOT'])
args = sys.argv[1:]
if args[0] == 'api':
    if '/releases/tags/' in args[-1]:
        print('HTTP 404: drafts are not returned by this endpoint', file=sys.stderr)
        sys.exit(1)
    assert args == ['api', '--paginate', '--slurp', 'repos/example/sdk/releases?per_page=100'], args
    if os.environ['MOCK_API_ERROR'] == '1':
        print('HTTP 503', file=sys.stderr)
        sys.exit(1)
    print((root / 'pages.json').read_text())
elif args[:2] == ['release', 'create']:
    with (root / 'creates.jsonl').open('a') as file:
        file.write(json.dumps(args) + '\\n')
else:
    raise AssertionError(args)
''',
                'git': '''import os, pathlib
root = pathlib.Path(os.environ['MOCK_ROOT'])
counter = root / 'git-count'
count = int(counter.read_text()) + 1 if counter.exists() else 1
counter.write_text(str(count))
move_at = int(os.environ['MOCK_MOVE_AT'])
sha = 'b' * 40 if move_at and count >= move_at else 'a' * 40
print(sha + '\\trefs/tags/' + os.environ['MOCK_TAG'])
''',
            }
            for name, source in stubs.items():
                stub = root / 'bin' / name
                stub.write_text(f'#!{sys.executable}\n' + source)
                stub.chmod(0o755)
            env = dict(os.environ, PATH=str(root / 'bin') + os.pathsep + os.environ['PATH'],
                       GH_REPO='example/sdk', GH_TOKEN='test-token',
                       GITHUB_STEP_SUMMARY=str(root / 'summary'), MOCK_ROOT=str(root),
                       MOCK_API_ERROR=str(int(api_error)), MOCK_MOVE_AT=str(move_at), MOCK_TAG=tag)
            result = subprocess.run(['/bin/bash', str(SCRIPT), str(validated)],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=15)
            calls = root / 'creates.jsonl'
            creates = [json.loads(line) for line in calls.read_text().splitlines()] if calls.exists() else []
            return result, creates

    def test_draft_on_second_page_stops_even_when_tag_lookup_would_be_404(self):
        result, creates = self.run_publish([[release('0.13.0')], [release('0.13.1', draft=True)]])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('existing draft', result.stderr)
        self.assertEqual(creates, [])

    def test_published_release_on_second_page_is_unchanged(self):
        result, creates = self.run_publish([[release('0.12.0')], [release('0.13.1')]])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(creates, [])

    def test_lookup_and_schema_errors_never_publish(self):
        cases = [dict(api_error=True), dict(raw='not json'), dict(pages={'message': 'error'}),
                 dict(pages=[[{'tag_name': '0.13.1', 'prerelease': False}]]),
                 dict(pages=[[release('0.13.1', draft='false')]])]
        for case in cases:
            with self.subTest(case=case):
                options = dict(pages=[[]])
                options.update(case)
                result, creates = self.run_publish(**options)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(creates, [])

    def test_explicit_latest_policy(self):
        cases = [('0.13.1', [[]], True),
                 ('0.10.0', [[release('0.9.9')]], True),
                 ('0.12.0', [[release('0.13.1')]], False),
                 ('0.13.1', [[release('0.99.0', draft=True), release('0.20.0', prerelease=True),
                              release('v9.0.0')]], True)]
        for tag, pages, latest in cases:
            with self.subTest(tag=tag, pages=pages):
                result, creates = self.run_publish(pages, tag=tag)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(creates), 1)
                self.assertIn('--latest=' + str(latest).lower(), creates[0])
                self.assertIn('--verify-tag', creates[0])
                self.assertEqual(creates[0][2], tag)

    def test_tag_moved_before_or_during_lookup_never_publishes(self):
        for move_at in (1, 2):
            with self.subTest(move_at=move_at):
                result, creates = self.run_publish([[]], move_at=move_at)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Remote tag changed', result.stderr)
                self.assertEqual(creates, [])


if __name__ == '__main__':
    unittest.main()
