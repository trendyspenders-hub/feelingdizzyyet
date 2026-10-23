#requires -Version 7.0
[CmdletBinding()]
param([switch]$AllowLocalSmokeTest)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Windows is required.' }
if (-not $AllowLocalSmokeTest -and ($env:GITHUB_ACTIONS -ne 'true')) { throw 'Run on an ephemeral GitHub runner, or explicitly opt into a local smoke test with -AllowLocalSmokeTest.' }
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$config = Get-Content 'build-config.json' -Raw | ConvertFrom-Json
$exe = Join-Path $root "dist/FeelingDizzyYetSetup-$($config.installerVersion)-unsigned.exe"
$logs = Join-Path $root 'build/logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$ae = Join-Path $env:APPDATA 'Adobe/After Effects/99.0'
$panelDir = Join-Path $ae 'Scripts/ScriptUI Panels'
$tempBase = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
$target = Join-Path $tempBase 'Feeling Dizzy Yet smoke install'
$reg = 'HKCU:\Software\FeelingDizzyYet\NativeSetup'
if ((Test-Path $ae) -or (Test-Path $target) -or (Test-Path $reg)) { throw 'Smoke-test target/state already exists. Refusing to touch an existing installation.' }
function Run-Setup([string]$Program, [string[]]$Options) {
    $p = Start-Process -FilePath $Program -ArgumentList $Options -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "Installer process returned $($p.ExitCode): $Program" }
}
function Require([bool]$Value, [string]$Message) { if (-not $Value) { throw $Message } }
$results = [Collections.Generic.List[string]]::new()
try {
    New-Item -ItemType Directory -Force (Join-Path $panelDir 'FeelingDizzyYet') | Out-Null
    'original-before-native-setup' | Set-Content (Join-Path $panelDir 'Feeling Dizzy Yet.jsx')
    'original-companion' | Set-Content (Join-Path $panelDir 'FeelingDizzyYet/original-marker.txt')
    $argsList = @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/AEVERSION=99.0','/COMPONENTS=aftereffects,premiere',"/DIR=`"$target`"",('/LOG="{0}"' -f (Join-Path $logs 'install.log')))
    Run-Setup $exe $argsList
    Require (Test-Path (Join-Path $target 'Premiere Edition/plugin/manifest.json')) 'Premiere source missing.'
    Require (Test-Path (Join-Path $panelDir 'FeelingDizzyYet/scripts/102_Automatic_Multicam_Editor.jsx')) 'AE native multicam missing.'
    Require ((Get-Content (Join-Path $panelDir 'Feeling Dizzy Yet.jsx') -Raw) -match 'Automatic Multicam') 'Wrong AE panel installed.'
    $sourceCCX = Join-Path $root $config.ccxPath
    if (Test-Path $sourceCCX) {
        $installedCCX = Join-Path $target 'Premiere Edition/FeelingDizzyYet-Premiere.ccx'
        Require (Test-Path $installedCCX) 'Premiere CCX missing from native installation.'
        Require ((Get-FileHash $installedCCX).Hash -eq (Get-FileHash $sourceCCX).Hash) 'Installed Premiere CCX checksum mismatch.'
        Write-Host 'PASS: included CCX copied byte-for-byte; Adobe registration not exercised.'
    }
    $backup = (Get-ItemProperty $reg).OriginalBackup
    Require ((Get-Content (Join-Path $backup 'Feeling Dizzy Yet.jsx') -Raw) -match 'original-before-native-setup') 'Original AE panel backup missing.'
    $results.Add('PASS: fresh EXE install copied runtime, registered test AE panel and preserved original files.')
    Run-Setup $exe $argsList
    Require ((Get-ItemProperty $reg).OriginalBackup -eq $backup) 'Update lost the original recovery location.'
    Require (Test-Path (Join-Path $panelDir 'FeelingDizzyYet/scripts/102_Automatic_Multicam_Editor.jsx')) 'Update lost native multicam.'
    $results.Add('PASS: repeat install/update retains original backup and expected runtime.')
    $uninstaller = Get-ChildItem $target -Filter 'unins*.exe' | Select-Object -First 1
    Require ($null -ne $uninstaller) 'Native uninstaller missing.'
    Run-Setup $uninstaller.FullName @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/LOG="{0}"' -f (Join-Path $logs 'uninstall.log')))
    Require ((Get-Content (Join-Path $panelDir 'Feeling Dizzy Yet.jsx') -Raw) -match 'original-before-native-setup') 'Uninstall did not restore previous AE panel.'
    Require (Test-Path (Join-Path $panelDir 'FeelingDizzyYet/original-marker.txt')) 'Uninstall lost original companion files.'
    Require (-not (Test-Path (Join-Path $panelDir 'FeelingDizzyYet/scripts/102_Automatic_Multicam_Editor.jsx'))) 'Uninstall left the new multicam file.'
    Require (-not (Test-Path (Join-Path $target 'Premiere Edition/plugin/manifest.json'))) 'Uninstall left installed source.'
    $results.Add('PASS: native uninstall removed new files and restored previous AE panel/companion.')
    $results.Add('NOT TESTED: Adobe runtime, audio/render, production CCX installation, signing and Windows desktop UX.')
    $reportPath = Join-Path $root 'dist/BUILD_REPORT.json'
    $report = Get-Content $reportPath -Raw | ConvertFrom-Json -AsHashtable
    $report['installerSmokeTestPassed'] = $true
    $report['installerSmokeTestScope'] = 'Fresh install, repeat install and uninstall against simulated AE preferences; no Adobe runtime'
    $report | ConvertTo-Json | Set-Content $reportPath -Encoding utf8
    $results | Set-Content (Join-Path $root 'dist/INSTALLER_TEST_RESULTS.txt')
    $results | ForEach-Object { Write-Host $_ }
} finally {
    # Preserve failed install/state for this ephemeral runner's logs; never delete unrelated profiles.
    if ($results.Count -ge 3) { Remove-Item $ae -Recurse -Force }
}
