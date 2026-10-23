# Feeling Dizzy Yet - native Windows setup

Installer 0.8.0 / Premiere panel 0.2.0 / AE panel 0.7.0.

## Install
1. Run the EXE produced by the workflow: `FeelingDizzyYetSetup-0.8.0-unsigned.exe`.
2. Read the development-preview notice. Choose After Effects, Premiere, or both.
3. Choose an existing After Effects preferences version, or leave Skip selected to retain manual-install files only. Close AE before continuing. If the version is absent, open AE once, close it, and rerun setup.
4. Restart AE. Open **Window > Feeling Dizzy Yet**. Choose **Automatic Multicam** or tool 102.
5. Premiere is handled as described below. A successful Windows setup does not by itself prove that Premiere registered the plugin.

No administrator elevation or VBScript is requested by the native setup. Default location: `%LOCALAPPDATA%\Programs\Feeling Dizzy Yet`. Windows Installed Apps contains an uninstall entry. The installer does not disable security features, launch Adobe, or install Adobe for you.

## Premiere
This kit currently includes developer source, not a production CCX.

Without a real Adobe CCX: use Adobe UXP Developer Tool 2.2+ to load the installed `Premiere Edition/plugin/manifest.json` into Premiere 25.6+. Enable host developer mode, restart Premiere, and choose Load & Watch in UDT. Open Window > UXP Plugins > Feeling Dizzy Yet.

If an authentic `packages/FeelingDizzyYet-Premiere.ccx` is added before building, the EXE includes it and offers an unchecked finish-page option to open it in Adobe Creative Cloud. The user completes Adobe's installation prompts. The CI smoke test does not perform CCX registration. The build checks the package structure and identity, not Adobe authenticity or Marketplace approval. Never rename a source ZIP to `.ccx`.

A CCX can be packaged on a Mac using Adobe UXP Developer Tool; owning a Windows computer is not required for that packaging step. Signed Windows EXE distribution is a separate step.

## Multicam editing
Cameras and isolated microphone WAVs must already share synchronized zero. Analysis happens inside Adobe; the removed HTML studio is not used.

Premiere: select ordinary camera media in the Project panel, open Automatic Multicam Editor, load cameras, choose microphone WAVs and an aligned 48 kHz/16-bit master mix, analyze, review and Create First Cut. Premiere imports an internal recovery XML into a new sequence. Existing grades, graphics and edits are not copied; the result is editable segments, not a native switchable multicam source.

AE: select synchronized camera layers, leaving master audio/graphics unselected. Open Automatic Multicam, map isolated WAVs to cameras, analyze, review and create a duplicate composition with timed camera cuts. Use simple unparented 2D camera layers without remapping, solo or mattes. The original comp is preserved.

2-8 speaker microphones plus optional separate wide camera. Use the included 20-second examples at 1280x720, 30 fps; default camera change is 10.5 seconds. The demo master is intentionally silent. Review real podcast sync, cut choices, audio routing, framing and rendered results.

## Updates, backups and uninstall
Existing matching AE panel files are backed up before replacement, outside the installed app folder: `%LOCALAPPDATA%\FeelingDizzyYetBackups`. The native uninstall preserves another copy, removes its tracked files and attempts to restore the pre-install AE panel/companion. Backups remain for manual recovery. Close AE before updating or uninstalling. Switching the registered AE preferences version requires uninstalling the native setup first.

The earlier CMD/VBS package is a separate installation. Do not use its uninstall shortcut to manage this native setup. A developer-loaded Premiere entry must also be unloaded in UXP Developer Tool. A CCX installed through Adobe must be uninstalled through Adobe's plugin management; removing this EXE does not unregister that Adobe-managed package.

## Testing and signing status
The source's 77 behavior checks have been rerun locally. PowerShell grammar and local workflow/package checks are recorded in LOCAL_CHECKS.txt in the build kit. Native EXE compilation and install/update/uninstall checks run only after the GitHub workflow is started. Until a successful run is available, those tests are pending.

The EXE is unsigned and its filename says so. Publisher verification and code signing have not been configured. CI uses a clean Windows runner with simulated AE preferences; no Adobe installation is present. Adobe UI, CCX installation, real audio, rendered output, permissions failures and locked-file recovery still need human acceptance testing before public release.
