#!/bin/bash
set -euo pipefail

# Always run this reviewed script, including when validating a historical tag.
tag=${1:?Usage: scripts/validate-release.sh x.y.z output-directory}
output=${2:?Output directory is required}
[[ "$tag" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || {
  echo 'Release tag must be x.y.z without a v prefix or leading zeroes.' >&2; exit 1;
}
root=$(cd "$(dirname "$0")/.." && pwd)
notes="$root/releases/$tag.md"
[[ -s "$notes" ]] && [[ -n "$(tr -d '[:space:]' < "$notes")" ]] || {
  echo "Missing authored release notes: releases/$tag.md" >&2; exit 1;
}
remote=https://github.com/REGALITECH/leeep-ios-sdk.git
refs=$(git ls-remote --exit-code "$remote" "refs/tags/$tag" "refs/tags/$tag^{}")
sha=$(printf '%s\n' "$refs" | awk '$2 ~ /\^\{\}$/ {print $1; found=1} END {if (!found) print first} NR==1 {first=$1}')
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo 'Remote tag did not resolve to one SHA.' >&2; exit 1; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R "$root/scripts/release-consumer/." "$work/"
sed -i '' "s/__VERSION__/$tag/g" "$work/ReleaseSmoke.xcodeproj/project.pbxproj"
mkdir -p "$output"
output=$(cd "$output" && pwd)
xcodebuild -version
xcodebuild -resolvePackageDependencies -project "$work/ReleaseSmoke.xcodeproj" \
  -scheme ReleaseSmoke -clonedSourcePackagesDirPath "$work/packages"
python3 - "$work" "$tag" "$sha" <<'PY'
import json, pathlib, plistlib, subprocess, sys
work, tag, sha = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
resolved = work / 'ReleaseSmoke.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
pins = json.loads(resolved.read_text())['pins']
assert len(pins) == 1 and pins[0]['identity'] == 'leeep-ios-sdk', pins
assert pins[0]['state']['version'] == tag and pins[0]['state']['revision'] == sha, pins
checkout = work / 'packages/checkouts/leeep-ios-sdk'
assert subprocess.check_output(['git', '-C', str(checkout), 'rev-parse', 'HEAD'], text=True).strip() == sha
bundle = checkout / 'leeep-ios-sdk.xcframework'
info = plistlib.loads((bundle / 'Info.plist').read_bytes())
variants = set()
for library in info['AvailableLibraries']:
    assert library['SupportedPlatform'] == 'ios', library
    variant = library.get('SupportedPlatformVariant', 'device')
    variants.add(variant)
    assert 'arm64' in library['SupportedArchitectures'], library
    assert library['LibraryPath'] == 'LeeepIosSdk.framework', library
    framework = bundle / library['LibraryIdentifier'] / library['LibraryPath']
    for name in ('LeeepIosSdk', 'Info.plist', 'Modules/module.modulemap'):
        assert (framework / name).is_file(), framework / name
assert variants == {'device', 'simulator'}, variants
PY
xcodebuild -project "$work/ReleaseSmoke.xcodeproj" -scheme ReleaseSmoke \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$work/derived" -clonedSourcePackagesDirPath "$work/packages" \
  -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO build
cp "$notes" "$output/release-notes.md"
cp "$work/ReleaseSmoke.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" "$output/Package.resolved"
python3 - "$output/validation.json" "$tag" "$sha" <<'PY'
import json, pathlib, sys
pathlib.Path(sys.argv[1]).write_text(json.dumps({'tag': sys.argv[2], 'sha': sys.argv[3]}, indent=2) + '\n')
PY
printf 'Validated %s at %s\n' "$tag" "$sha"
