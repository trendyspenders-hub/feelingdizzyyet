#requires -Version 7.0
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Build-Windows.ps1 must run on Windows, locally or through GitHub Actions.' }
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$config = Get-Content 'build-config.json' -Raw | ConvertFrom-Json
if ($config.installerVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Installer version must be numeric major.minor.patch.' }
$archive = Join-Path $root $config.sourceArchive
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $config.sourceSHA256) { throw 'Source ZIP checksum mismatch. Review the archive before changing the configured SHA-256.' }
$build = Join-Path $root 'build'
$dist = Join-Path $root 'dist'
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force $build,$dist,(Join-Path $build 'logs') | Out-Null
$inputDir = Join-Path $build 'input'
if (Test-Path $inputDir) { Remove-Item $inputDir -Recurse -Force }
Expand-Archive -LiteralPath $archive -DestinationPath $inputDir
$legacy = Join-Path $inputDir 'Feeling Dizzy Yet Windows'
$verification = Join-Path $legacy 'Verification'
& node (Join-Path $verification 'run-tests.js') 2>&1 | Tee-Object -FilePath (Join-Path $build 'logs/behavior-tests.log')
if ($LASTEXITCODE -ne 0) { throw 'Source behavior tests failed.' }
$payload = Join-Path $build 'payload'
if (Test-Path $payload) { Remove-Item $payload -Recurse -Force }
Copy-Item (Join-Path $legacy 'payload') $payload -Recurse
# The native setup replaces the old CMD/VBS launcher; it does not execute those scripts.
Get-ChildItem $payload -File | Where-Object { $_.Extension -in '.vbs','.cmd' } | Remove-Item
if (Test-Path (Join-Path $build 'Examples')) { Remove-Item (Join-Path $build 'Examples') -Recurse -Force }
Copy-Item (Join-Path $legacy 'Examples') (Join-Path $build 'Examples') -Recurse -Force
Copy-Item (Join-Path $root 'NATIVE-INSTALL.md') (Join-Path $build 'NATIVE-INSTALL.md') -Force
$nativeGuide = Get-Content (Join-Path $root 'NATIVE-INSTALL.md') -Raw
$nativeHtml = '<!doctype html><meta charset="utf-8"><title>Feeling Dizzy Yet - Installation</title><style>body{font:16px/1.6 Arial;max-width:900px;margin:40px auto;padding:24px;background:#15191f;color:#f4f1e8}pre{white-space:pre-wrap;font:inherit}</style><pre>' + [System.Net.WebUtility]::HtmlEncode($nativeGuide) + '</pre>'
[IO.File]::WriteAllText((Join-Path $build 'NATIVE-INSTALL.html'), $nativeHtml)
# Replace the AE panel's guide with instructions for the native setup and the actual editing workflow.
$guide = Get-Content (Join-Path $legacy 'INSTALLATION.md') -Raw
$nativeWindows = @'
### Windows installation
Run FeelingDizzyYetSetup.exe (the filename includes its version and unsigned status). Choose components and an existing AE preferences version, or skip registration to keep manual files. Restart AE and open Window > Feeling Dizzy Yet. Use Windows Installed Apps to uninstall. Read NATIVE-INSTALL.md in the installed folder. The native setup does not use VBScript. Existing legacy CMD/VBS installations remain separate; do not use their uninstall shortcut to manage this native installation.

'@
$guide = [regex]::Replace($guide, '(?s)### Windows installation.*?(?=### Mac installation)', $nativeWindows)
$guide = $guide.Replace('Install Adobe UXP Developer Tool 2.2 or later.', 'If no Adobe-packaged CCX was supplied, install Adobe UXP Developer Tool 2.2 or later.')
$html = '<!doctype html><meta charset="utf-8"><title>Feeling Dizzy Yet</title><style>body{background:#15191f;color:#f4f1e8;font:16px/1.6 Arial;max-width:900px;margin:40px auto;padding:24px}pre{white-space:pre-wrap;font:inherit}h1{color:#cafa6b}</style><h1>Feeling Dizzy Yet</h1><pre>' + [System.Net.WebUtility]::HtmlEncode($guide) + '</pre>'
[IO.File]::WriteAllText((Join-Path $payload 'After Effects/FeelingDizzyYet/START_HERE.html'), $html)
[IO.File]::WriteAllText((Join-Path $payload 'After Effects/FeelingDizzyYet/MULTICAM_README.md'), $guide)
[IO.File]::WriteAllText((Join-Path $payload 'Premiere Edition/README.md'), $guide)
$ccx = Join-Path $root $config.ccxPath
$hasCCX = Test-Path $ccx
if ($hasCCX) {
    # A ZIP renamed to .ccx is not sufficient. Supply an authentic UDT-created package.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($ccx)
    try {
        $entry = $zip.GetEntry('manifest.json')
        if ($null -eq $entry) { throw 'Supplied CCX has no root manifest.json. Package it through Adobe UXP Developer Tool.' }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        if ($manifest.id -ne 'studio.feelingdizzyyet.premiere' -or $manifest.host.app -ne 'premierepro') { throw 'CCX identity/host does not match Feeling Dizzy Yet Premiere.' }
    } finally { $zip.Dispose() }
}
$notice = @"
FEELING DIZZY YET - NATIVE WINDOWS SETUP $($config.installerVersion)

This is an unsigned development build. Windows may display an unknown-publisher warning.
After Effects: choose an existing preferences version or keep a manual-install copy.
Premiere Adobe-packaged CCX included: $hasCCX
Without a CCX, Premiere files require Adobe UXP Developer Tool. Copying source does not register the plugin.

Multicam runs inside Adobe. Premiere creates editable cuts through an internal XML import. AE creates a duplicate composition. Cameras/WAVs must already be synchronized. No live Claude/OpenAI connection is included.

CI installation checks do not test Adobe editing, rendering, sound or real Premiere plugin registration.
Existing matching AE files are backed up before replacement. Native uninstall preserves another copy and attempts to restore the pre-install AE panel. Backups stay in Local AppData/FeelingDizzyYetBackups.
"@
[IO.File]::WriteAllText((Join-Path $build 'INSTALLER-NOTICE.txt'), $notice, [Text.UTF8Encoding]::new($true))
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
if (-not (Test-Path $iscc)) { throw 'Inno Setup 6 was not found. Install it on this Windows machine or use the windows-2022 GitHub runner.' }
$argsList = @("/DAppVersion=$($config.installerVersion)")
if ($hasCCX) { $argsList += '/DIncludeCCX' }
$argsList += (Join-Path $root 'installer/FeelingDizzyYet.iss')
& $iscc @argsList 2>&1 | Tee-Object -FilePath (Join-Path $build 'logs/compiler.log')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }
$exe = Join-Path $dist "FeelingDizzyYetSetup-$($config.installerVersion)-unsigned.exe"
if (-not (Test-Path $exe)) { throw 'Compiler returned without the expected EXE.' }
$signature = Get-AuthenticodeSignature $exe
if ($signature.Status -ne 'NotSigned') { throw 'Unexpected signature status; review this build before labeling it unsigned.' }
$hash = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $([IO.Path]::GetFileName($exe))" | Set-Content (Join-Path $dist 'SHA256SUMS.txt') -Encoding ascii
Copy-Item (Join-Path $root 'NATIVE-INSTALL.md') $dist -Force
@{
    installerVersion = $config.installerVersion
    sourceSHA256 = $config.sourceSHA256
    exeSHA256 = $hash
    authenticode = 'NotSigned'
    premiereCCXIncluded = $hasCCX
    premiereInstallMode = $(if ($hasCCX) { 'User opens authentic CCX in Adobe Creative Cloud; Adobe registration remains untested' } else { 'Developer source only; Adobe UXP Developer Tool required' })
    adobeRuntimeTested = $false
    compiler = (Get-Item $iscc).VersionInfo.FileVersion
    commit = $env:GITHUB_SHA
    builtAtUTC = [DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json | Set-Content (Join-Path $dist 'BUILD_REPORT.json') -Encoding utf8
Write-Host "Compiled $exe"
