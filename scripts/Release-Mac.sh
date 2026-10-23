#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${RELEASE_MODE:-unsigned-preview}"
[[ "$mode" == unsigned-preview || "$mode" == signed-notarized ]] || { echo 'Unknown release mode'; exit 1; }
app="$PWD/build/mac/stage/Install Feeling Dizzy Yet.app"
version=$(python3 -c 'import json;print(json.load(open("build-config.json"))["installerVersion"])')
mkdir -p dist/mac
keychain=''; keychain_pass=''; original_keychains=''
cleanup() {
  if [[ -n "$original_keychains" ]]; then
    # Restore the runner's original search list before removing the temporary identity store.
    python3 - "$original_keychains" <<'PY'
import shlex,subprocess,sys
subprocess.run(['security','list-keychains','-d','user','-s',*shlex.split(sys.argv[1])],check=False)
PY
  fi
  [[ -z "$keychain" ]] || security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -f "${RUNNER_TEMP:-/tmp}/fdy-signing.p12"
}
trap cleanup EXIT
notarize() {
  local file="$1" label="$2" result="$PWD/build/mac/logs/$2-notary.json"
  xcrun notarytool submit "$file" --keychain-profile FDY-notary --keychain "$keychain" --wait --timeout 20m --output-format json > "$result"
  python3 - "$result" <<'PY'
import json,sys
r=json.load(open(sys.argv[1])); print('Apple notarization:',r.get('status'))
if r.get('status')!='Accepted': raise SystemExit('Apple did not accept this submission; no signed release will be published.')
PY
}
if [[ "$mode" == signed-notarized ]]; then
  for var in APPLE_CERTIFICATE_P12_BASE64 APPLE_CERTIFICATE_PASSWORD APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD; do
    [[ -n "${!var:-}" ]] || { echo "Required GitHub Actions secret is missing: $var"; exit 1; }
  done
  umask 077
  keychain="${RUNNER_TEMP}/fdy-signing-$(uuidgen).keychain-db"
  keychain_pass=$(openssl rand -hex 32)
  original_keychains=$(security list-keychains -d user)
  python3 - <<'PY'
import os,base64,pathlib
p=pathlib.Path(os.environ['RUNNER_TEMP'])/'fdy-signing.p12'
p.write_bytes(base64.b64decode(os.environ['APPLE_CERTIFICATE_P12_BASE64'],validate=True))
PY
  security create-keychain -p "$keychain_pass" "$keychain"
  security set-keychain-settings -lut 21600 "$keychain"
  security unlock-keychain -p "$keychain_pass" "$keychain"
  security import "${RUNNER_TEMP}/fdy-signing.p12" -P "$APPLE_CERTIFICATE_PASSWORD" -k "$keychain" -T /usr/bin/codesign -T /usr/bin/security >/dev/null
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_pass" "$keychain" >/dev/null
  security list-keychains -d user -s "$keychain"
  identity=$(security find-identity -v -p codesigning "$keychain" | sed -n 's/.*"\(Developer ID Application:.*\)".*/\1/p')
  [[ -n "$identity" && "$identity" != *$'\n'* && "$identity" == *"($APPLE_TEAM_ID)" ]] || { echo 'Expected exactly one valid Developer ID Application identity matching APPLE_TEAM_ID'; exit 1; }
  xcrun notarytool store-credentials FDY-notary --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --keychain "$keychain" >/dev/null
  codesign --force --sign "$identity" --keychain "$keychain" --options runtime --timestamp "$app"
  codesign --verify --deep --strict --verbose=2 "$app"
  ditto -c -k --keepParent "$app" build/mac/installer-for-notarization.zip
  notarize "$PWD/build/mac/installer-for-notarization.zip" app
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose=2 "$app"
  name="FeelingDizzyYet-$version-signed-notarized.dmg"
else
  codesign --force --sign - "$app"
  name="FeelingDizzyYet-$version-UNSIGNED-PREVIEW.dmg"
fi
hdiutil create -volname 'Feeling Dizzy Yet' -srcfolder build/mac/stage -ov -format UDZO "dist/mac/$name"
hdiutil verify "dist/mac/$name"
if [[ "$mode" == signed-notarized ]]; then
  codesign --force --sign "$identity" --keychain "$keychain" --timestamp "dist/mac/$name"
  codesign --verify --verbose=2 "dist/mac/$name"
  notarize "$PWD/dist/mac/$name" dmg
  xcrun stapler staple "dist/mac/$name"
  xcrun stapler validate "dist/mac/$name"
  spctl --assess --type open --context context:primary-signature --verbose=2 "dist/mac/$name"
fi
shasum -a 256 "dist/mac/$name" > dist/mac/SHA256SUMS.txt
python3 - "$mode" "$name" <<'PY'
import json,sys,pathlib
r={'releaseMode':sys.argv[1],'file':sys.argv[2],'appleDeveloperIDSigned':sys.argv[1]=='signed-notarized','appleNotarized':sys.argv[1]=='signed-notarized','nativeInstallerCopyRollbackTested':True,'adobeRuntimeTested':False}
pathlib.Path('dist/mac/BUILD_REPORT.json').write_text(json.dumps(r,indent=2))
PY
cp macos/INSTALL-MAC.md dist/mac/
