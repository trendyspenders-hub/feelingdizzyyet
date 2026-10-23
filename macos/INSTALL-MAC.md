# Feeling Dizzy Yet - Mac installation

Read BUILD_REPORT.json beside the downloaded DMG to check its status. A filename containing UNSIGNED-PREVIEW is not Apple Developer ID signed or notarized. Preview app bundles have only a local ad-hoc signature and can be blocked by Gatekeeper. No installer disables macOS security settings.

1. Open the DMG.
2. For Premiere, double-click FeelingDizzyYet-Premiere.ccx and complete Adobe Creative Cloud's installation prompts. Restart Premiere and open Window > UXP Plugins > Feeling Dizzy Yet. This CCX was generated using Adobe's open-source packaging code; actual Adobe installation/editing remains unverified.
3. For After Effects, close AE and open Install Feeling Dizzy Yet.app. Select the existing AE preferences version, then Install After Effects. Restart AE and open Window > Feeling Dizzy Yet.
4. If no preferences version is listed, open and close AE once, then try again. Matching existing panel files are retained in a backup folder inside the chosen ScriptUI Panels directory.

Manual AE alternative: copy both Feeling Dizzy Yet.jsx and the FeelingDizzyYet companion folder from Manual After Effects Install into your AE Scripts/ScriptUI Panels folder. Keep them together and restart AE.

The native installer is a universal Apple Silicon/Intel executable for macOS 11+. That deployment target does not certify every Adobe/OS combination. GitHub tests the compiled copy/rollback routines on one macOS runner. Adobe loading, layout, editing, audio sync, permission-denial recovery and rendered output remain untested.

Automatic Multicam runs inside Adobe. In Premiere, load synchronized camera Project items, map isolated microphone WAVs, provide the aligned 48 kHz/16-bit master mix, analyze, review and Create First Cut. Premiere imports an internal recovery XML into a new sequence. In AE, select synchronized camera layers, leave master audio/graphics unselected, open Automatic Multicam/tool 102, map microphone WAVs and create cuts in a duplicate composition. Use simple unparented 2D cameras, no solo/mattes/remapping, at 100% stretch. Review all edits. No automatic sync or live Claude/OpenAI connection is included.

Examples contain two 20-second cameras/microphones: 1280x720, 30 fps. The default change is at 10.5 seconds. The demo master is intentionally silent.

To remove the AE panel, close AE and remove only Feeling Dizzy Yet.jsx and its FeelingDizzyYet companion folder from the selected ScriptUI Panels directory. Restore a chosen matching pair from its backup folder if needed. Remove the Premiere CCX through Adobe plugin management. The app installs per user without administrator authorization; there is no separate Mac uninstaller app in this preview.
