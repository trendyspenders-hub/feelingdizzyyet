# Apple signing setup - account owner steps

The GitHub workflow is prepared, but a trusted Apple signature cannot be issued without your Apple Developer credentials. No signing credentials are stored in this repository. An ad-hoc signature is not Developer ID signing and cannot replace Apple's certificate or notarization.

## What you supply

1. An active Apple Developer Program membership. Apple lists US$99 per membership year, or local currency where available. Enrollment/identity verification and any purchase must be completed by the account owner.
2. A **Developer ID Application** certificate and its matching private key, exported from Keychain Access as a password-protected `.p12`. Apple Development, Apple Distribution and Developer ID Installer are different certificate types; this app/DMG workflow uses Developer ID Application.
3. Your Apple Developer Team ID, your Apple Account email and an app-specific password for notarization. Use an app-specific password, not your ordinary Apple Account password.

## Get the certificate

Use Apple's account instructions to create a Developer ID Application certificate. If a certificate-signing request is requested, create it in Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority; save it to disk and upload it to Apple's Developer account. Download and install Apple's issued certificate on the Mac where that request's private key was created. Under My Certificates, confirm the certificate expands to show the matching private key. Export the certificate/private key pair as a `.p12` and choose a strong export password. An Apple-issued `.cer` alone is not enough to sign in GitHub.

The account holder may need to create the Developer ID certificate or grant the appropriate account access. Keep the private key under your control.

## Put credentials into GitHub Secrets

Open https://github.com/trendyspenders-hub/feelingdizzyyet/settings/secrets/actions and use New repository secret for each name below. Do not put passwords, `.p12` files, `.p8` keys or private keys in source files, issues or this chat.

| Secret name | Value |
| --- | --- |
| APPLE_CERTIFICATE_P12_BASE64 | Base64 text of the exported certificate/private-key `.p12` |
| APPLE_CERTIFICATE_PASSWORD | The `.p12` export password |
| APPLE_ID | Apple Account email authorized for notarization |
| APPLE_TEAM_ID | The matching Apple Developer Team ID |
| APPLE_APP_SPECIFIC_PASSWORD | App-specific password created in your Apple Account's Sign-In and Security settings |

On your Mac, copy the certificate's base64 directly to the clipboard with `base64 -i /path/to/your-certificate.p12 | pbcopy`, then paste only into the matching GitHub secret field. This encoding is not encryption; keep the original file and encoded text private.

## Run the signing workflow

Open Actions > Build and sign Feeling Dizzy Yet Mac DMG > Run workflow. Choose **signed-notarized**. The default **unsigned-preview** option does not use the credentials or claim Apple trust.

For a signed release the job:
- Imports the certificate into a temporary runner keychain and checks the Developer ID identity against your Team ID.
- Signs the compiled universal installer with hardened runtime and a secure timestamp.
- Submits the app to Apple's notary service, requires Accepted, staples the ticket and checks Gatekeeper assessment.
- Builds/signs the DMG, notarizes it, staples/validates its ticket and checks its signature/Gatekeeper assessment.
- Publishes a signed-notarized artifact only if all steps succeed.
- Restores the runner keychain search list and deletes the temporary keychain/certificate file when the release script exits.

A missing secret, wrong certificate, rejected submission or failed verification stops the signed release. There is no automatic downgrade to unsigned. Apple's service can take time; rejected jobs retain diagnostic JSON logs. Notarization is Apple's malware/security check, not verification of Adobe editing behavior.

The workflow does not publish a public GitHub Release automatically. Review the artifact and its BUILD_REPORT.json before distribution. This repository is public; keep all signing material only in GitHub Secrets or your local Keychain.

## Primary instructions
- https://developer.apple.com/help/account/certificates/create-developer-id-certificates
- https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- https://developer.apple.com/help/account/membership/program-enrollment/
- https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications
