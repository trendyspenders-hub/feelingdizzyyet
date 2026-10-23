#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'macOS runner required'; exit 1; }
mkdir -p build/mac/logs
python3 - <<'PY'
import pathlib,json,hashlib,zipfile,shutil,plistlib
root=pathlib.Path.cwd(); c=json.loads((root/'build-config.json').read_text()); archive=root/c['sourceArchive']
assert hashlib.sha256(archive.read_bytes()).hexdigest()==c['sourceSHA256']
dest=root/'build/mac/input';shutil.rmtree(dest,ignore_errors=True)
with zipfile.ZipFile(archive) as z:z.extractall(dest)
stage=root/'build/mac/stage';shutil.rmtree(stage,ignore_errors=True);stage.mkdir()
legacy=dest/'Feeling Dizzy Yet Windows'; ae=legacy/'payload/After Effects'
app=stage/'Install Feeling Dizzy Yet.app'; resources=app/'Contents/Resources';resources.mkdir(parents=True)
(app/'Contents/MacOS').mkdir()
shutil.copytree(ae,resources/'After Effects')
shutil.copy(ae/'FeelingDizzyYet/brand/FeelingDizzyYet.icns',resources/'FeelingDizzyYet.icns')
shutil.copy(ae/'FeelingDizzyYet/brand/FeelingDizzyYet.icns',stage/'.VolumeIcon.icns')
shutil.copytree(ae,stage/'Manual After Effects Install')
shutil.copytree(legacy/'Examples',stage/'Examples')
shutil.copy(root/'packages/FeelingDizzyYet-Premiere.ccx',stage/'FeelingDizzyYet-Premiere.ccx')
shutil.copy(root/'macos/INSTALL-MAC.md',stage/'INSTALL-MAC.md')
# Replace platform-specific help left in the shared source with Mac instructions.
helptext=(root/'macos/INSTALL-MAC.md').read_text()
import html
helphtml='<meta charset="utf-8"><title>Feeling Dizzy Yet</title><pre style="white-space:pre-wrap;font:16px/1.6 Arial">'+html.escape(helptext)+'</pre>'
for p in [resources/'After Effects/FeelingDizzyYet',stage/'Manual After Effects Install/FeelingDizzyYet']:
 (p/'START_HERE.html').write_text(helphtml)
 (p/'MULTICAM_README.md').write_text(helptext)
plist={'CFBundleExecutable':'FeelingDizzyYetInstaller','CFBundleIdentifier':'studio.feelingdizzyyet.macinstaller','CFBundleName':'Feeling Dizzy Yet Installer','CFBundleDisplayName':'Feeling Dizzy Yet Installer','CFBundlePackageType':'APPL','CFBundleShortVersionString':c['installerVersion'],'CFBundleVersion':c['installerVersion'],'CFBundleIconFile':'FeelingDizzyYet.icns','LSMinimumSystemVersion':'11.0','NSHighResolutionCapable':True}
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(plist))
PY
sdk=$(xcrun --sdk macosx --show-sdk-path)
for arch in arm64 x86_64; do
  xcrun swiftc -O -sdk "$sdk" -target "$arch-apple-macosx11.0" -framework AppKit macos/Installer.swift -o "build/mac/installer-$arch"
done
xcrun lipo -create build/mac/installer-arm64 build/mac/installer-x86_64 -output 'build/mac/stage/Install Feeling Dizzy Yet.app/Contents/MacOS/FeelingDizzyYetInstaller'
chmod 755 'build/mac/stage/Install Feeling Dizzy Yet.app/Contents/MacOS/FeelingDizzyYetInstaller'
'build/mac/stage/Install Feeling Dizzy Yet.app/Contents/MacOS/FeelingDizzyYetInstaller' --self-test | tee build/mac/logs/native-installer-tests.txt
node 'build/mac/input/Feeling Dizzy Yet Windows/Verification/run-tests.js' | tee build/mac/logs/source-tests.txt
