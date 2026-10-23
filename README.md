# Feeling Dizzy Yet - Windows cloud build kit

This project builds a real, unsigned Windows EXE on a GitHub-hosted Windows runner. You can set it up from your Mac. The native Inno Setup wizard replaces the previous CMD/VBScript installer.

**Current status:** build configuration prepared; a target repository is still needed to run it. No compiled EXE or successful Windows CI run is claimed by this ZIP.

## Easiest next step
Create an empty **private** GitHub repository named `feeling-dizzy-yet`, initialize it with a README, and send its URL back in the chat. If the connected GitHub app can access it, the prepared files can be committed there and the workflow started. If the repository is not visible, grant the ChatGPT GitHub app access in your GitHub installation settings. Repository creation itself is not available through the currently connected tools.

Do not upload this project into an unrelated existing app repository. No existing repository has been changed.

## Manual setup from your Mac, if preferred
1. Create the private repository above. Private repositories keep this preview source out of public search. Check the GitHub account's available Actions quota; no paid service is enabled by this kit.
2. Extract this build kit. In GitHub choose **Add file > Upload files** and upload its visible files and folders into the repository root, not the enclosing directory. Include installer, scripts, source, tests, packages, build-config.json and the guides.
3. The actual workflow lives at `.github/workflows/windows-installer.yml`. Finder may hide `.github`; press **Command + Shift + period** to show hidden files. For a reliable browser-only alternative, use GitHub **Add file > Create new file**, enter `.github/workflows/windows-installer.yml`, and paste the contents of the visible `windows-installer.yml` copy included in this kit. Commit it to main.
4. Open **Actions > Build Feeling Dizzy Yet Windows installer > Run workflow**. A qualifying push to main also starts a run.
5. Open the run. If it succeeds, scroll to **Artifacts** and download `FeelingDizzyYet-Windows-<run number>`.
6. Extract the artifact. It contains the unsigned Setup.exe, SHA256SUMS.txt, BUILD_REPORT.json, installation notes and test logs. If a step fails, inspect compiler.log or the displayed Actions error rather than distributing the build.

## What the Windows job does
- Verify the included source archive SHA-256 against build-config.json.
- Extract the existing audited runtime and rerun all 77 behavior checks using Node 22.
- Create native installer content without running the old VBS/CMD setup.
- Compile installer/FeelingDizzyYet.iss using Inno Setup 6 on windows-2022.
- Install into an isolated temporary path, deploy into simulated AE version 99.0 preferences, verify an update, uninstall and check previous panel restoration.
- Retain EXE, SHA-256, build report and logs as a downloadable artifact for 14 days.

The workflow has read-only repository permissions, does not publish a GitHub release, uses no signing/API secrets, and is not triggered from pull requests. It does not connect to Adobe accounts or install Adobe.

## Premiere packaging boundary
The default build includes developer source; it does not falsely label that source as a registered Premiere plugin. To add a proper package, use Adobe UXP Developer Tool on your Mac to package the Premiere source into a real `.ccx`, then put it at `packages/FeelingDizzyYet-Premiere.ccx`. The build checks the identity/host in its root manifest. The installer can then offer to open the CCX in Adobe Creative Cloud, where the user completes Adobe's installation prompts. Adobe authenticity, registration and rendering are not CI-tested.

No automatic Adobe packaging, Marketplace approval, code signing, signing certificate or live Claude/OpenAI connection is included. See NATIVE-INSTALL.md for user-facing behavior and acceptance limits.

## Build locally on Windows, if you later have access
Install Node.js 22, PowerShell 7 and Inno Setup 6, then run `pwsh -File scripts/Build-Windows.ps1` from this directory. The smoke-test script refuses ordinary local execution unless `-AllowLocalSmokeTest` is explicitly supplied; it creates a simulated AE 99.0 preferences directory and its own native setup state.

## Update the source later
Replace source/Feeling_Dizzy_Yet_Windows_Installer.zip with the intended complete source package. Review its content, set its SHA-256 in build-config.json, and increment installerVersion. Keep the stable AppId for in-place updates. Do not edit the archive checksum merely to silence an unexplained mismatch.

## Primary references
- https://github.com/actions/runner-images/blob/main/images/windows/Windows2022-Readme.md
- https://docs.github.com/en/actions/tutorials/store-and-share-data
- https://jrsoftware.org/ishelp/topic_setup_privilegesrequired.htm
- https://developer.adobe.com/uxp/guides/how-to/distribution/package/
- https://developer.adobe.com/premiere-pro/uxp/plugins/distribution/install/
