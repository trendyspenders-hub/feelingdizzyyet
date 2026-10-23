# Feeling Dizzy Yet

Native Windows installer and Adobe editing tools.

## Download the Windows installer

**[Download the successful Windows build](https://github.com/trendyspenders-hub/feelingdizzyyet/actions/runs/40029545289/artifacts/12534107837)**

Extract the artifact ZIP and run `FeelingDizzyYetSetup-0.8.1-unsigned.exe` on Windows. It includes installation notes, SHA-256 checksums, a build report and installer test results. GitHub artifact downloads require signing in and this artifact expires November 6, 2026. Run the workflow again to generate a new artifact.

**[View the successful build and logs](https://github.com/trendyspenders-hub/feelingdizzyyet/actions/runs/40029545289)**

## Verified on the GitHub Windows runner

- All 77 source behavior checks passed.
- The native EXE compiled successfully.
- Fresh installation, repeat installation/update, uninstall and restoration of previous AE panel files passed against simulated AE preferences.
- Downloaded artifact and EXE checksums verified.

The installer is unsigned. Adobe loading, actual editing/audio/rendering, desktop UI appearance and production Premiere CCX registration remain untested. A passing installer test is not Adobe compatibility certification.

## Mac DMG and Apple signing

[Mac unsigned-preview build](https://github.com/trendyspenders-hub/feelingdizzyyet/actions/runs/40030416277) passed compilation, native staged-copy/rollback tests and DMG integrity checks. It contains a universal Intel/Apple Silicon AE installer, the Premiere CCX, manual AE files and examples. It is not Apple Developer ID signed or notarized; actual Adobe editing remains untested.

[Apple signing setup](macos/APPLE-SIGNING.md) explains the five GitHub Secrets needed from the account owner. Run **Build and sign Feeling Dizzy Yet Mac DMG** manually with **signed-notarized** only after adding them. Missing credentials or failed Apple checks stop the signed release; there is no silent unsigned fallback. The default and automatic mode is **unsigned-preview**.

## What gets installed

The per-user Inno Setup wizard installs the After Effects panel and 102 numbered tools, with optional registration into an existing AE preferences version. Existing panel files are backed up; uninstall preserves a copy and attempts to restore the pre-install panel. The native installer does not use VBScript and does not request administrator elevation.

Premiere includes FeelingDizzyYet-Premiere.ccx, generated using Adobe's unmodified open-source UXP packaging code. The artifact ZIP includes the standalone CCX, and the Windows EXE also installs it. On Mac, open the CCX in Adobe Creative Cloud. On Windows, select the optional finish-page action or open the installed CCX. Complete Adobe's prompts, then restart Premiere and check Window > UXP Plugins. Actual Adobe installation remains untested; packaging is not Adobe certification. See packages/CCX_BUILD_REPORT.json for provenance and host-validation limits.

Automatic Multicam Editor runs inside Adobe. Premiere creates editable segments by internal XML import; AE creates timed cuts in a duplicate composition. Cameras and isolated microphone WAVs must already be synchronized. Output is a first-pass edit, not native switchable multicam angles. No live Claude/OpenAI connection is included.

See [installation instructions](NATIVE-INSTALL.md).

## Rebuild from your Mac

Open **Actions > Build Feeling Dizzy Yet Windows installer > Run workflow**. GitHub runs Windows for you. A successful run offers the EXE under Artifacts; diagnostic logs are retained separately. A failed installer smoke test does not publish the EXE artifact.

The workflow uses read-only repository permissions, no signing/API secrets and no pull-request trigger. No GitHub release is published automatically.

## Build configuration

- `installer/FeelingDizzyYet.iss`: native setup and recovery logic.
- `scripts/Build-Windows.ps1`: checksum, source tests, staging and compilation.
- `scripts/Test-Installer.ps1`: isolated install/update/uninstall test.
- `build-config.json`: source archive checksum and installer version.
- `source/Feeling_Dizzy_Yet_Windows_Installer.zip`: audited editing runtime and fixtures.

To update source, review and replace the archive, update its checksum and increment installerVersion. Keep the installer AppId stable for in-place updates.

For a local Windows build, install Node.js 22, PowerShell 7 and Inno Setup 6, then run `pwsh -File scripts/Build-Windows.ps1`. The smoke test is intended for ephemeral GitHub runners and requires explicit opt-in for local execution.
