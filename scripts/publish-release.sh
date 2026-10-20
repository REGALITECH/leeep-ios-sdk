#!/bin/bash
set -euo pipefail

validated=${1:?Usage: scripts/publish-release.sh validated-release-directory}
: "${GH_REPO:?GH_REPO is required}"
tag=$(jq -er '.tag | select(type == "string")' "$validated/validation.json")
expected=$(jq -er '.sha | select(type == "string")' "$validated/validation.json")
[[ "$tag" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || exit 1
[[ "$expected" =~ ^[0-9a-f]{40}$ ]] || exit 1

verify_tag() {
  local refs actual
  refs=$(git ls-remote --exit-code "https://github.com/$GH_REPO.git" "refs/tags/$tag" "refs/tags/$tag^{}")
  actual=$(printf '%s\n' "$refs" | awk '$2 ~ /\^\{\}$/ {print $1; found=1} END {if (!found) print first} NR==1 {first=$1}')
  [[ "$actual" == "$expected" ]] || { echo 'Remote tag changed after validation.' >&2; exit 1; }
}
verify_tag
releases=$(mktemp)
trap 'rm -f "$releases"' EXIT
# The tag-specific endpoint omits drafts. The authenticated list includes them.
gh api --paginate --slurp "repos/$GH_REPO/releases?per_page=100" > "$releases"
decision=$(python3 - "$tag" "$releases" <<'PY'
import json, pathlib, re, sys
tag, path = sys.argv[1:]
pages = json.loads(pathlib.Path(path).read_text())
if not isinstance(pages, list) or not pages or any(not isinstance(page, list) for page in pages):
    raise ValueError('Expected paginated release lists')
releases = [release for page in pages for release in page]
for release in releases:
    if (not isinstance(release, dict)
            or not isinstance(release.get('tag_name'), str) or not release['tag_name']
            or type(release.get('draft')) is not bool
            or type(release.get('prerelease')) is not bool):
        raise ValueError('Invalid release response')
matching = [release for release in releases if release['tag_name'] == tag]
if any(release['draft'] for release in matching):
    print('draft')
elif matching:
    print('published')
else:
    pattern = r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
    versions = [tuple(map(int, release['tag_name'].split('.'))) for release in releases
                if not release['draft'] and not release['prerelease']
                and re.fullmatch(pattern, release['tag_name'])]
    print('true' if all(tuple(map(int, tag.split('.'))) > version for version in versions) else 'false')
PY
)
case "$decision" in
  published)
    echo "Release $tag is already published; leaving it unchanged." >> "$GITHUB_STEP_SUMMARY"
    exit 0
    ;;
  draft)
    echo 'An existing draft must be reviewed manually; it will not be edited.' >&2
    exit 1
    ;;
  true|false) ;;
  *) echo 'Invalid release decision.' >&2; exit 1 ;;
esac
verify_tag
gh release create "$tag" --repo "$GH_REPO" --verify-tag --latest="$decision" \
  --title "iOS SDK $tag" --notes-file "$validated/release-notes.md"
