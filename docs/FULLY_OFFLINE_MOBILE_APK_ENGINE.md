# Fully offline on-device APK generation

## Required product behaviour
AppMaker must create a separate installable APK on the same Android device, without making network requests at runtime. Project editing and storage remain local. The APK is saved in app-specific storage and installation is handed to Android's Package Installer; Android still displays its normal user confirmation.

## Architecture decision
Do not attempt to bundle a complete Flutter/JDK/Android-SDK/Gradle toolchain and run it from a normal Android app. That would be extremely large, difficult to maintain, and constrained by Android process/storage/exec rules.

Instead use a precompiled, minimal Android reader template:
1. During the AppMaker release build, compile the standalone template APK and package it as an asset inside AppMaker. This is a build-time preparation step; the installed AppMaker must not download it.
2. AppMaker serializes a selected local project to JSON.
3. A native Android component copies the embedded template APK to private temporary storage, replaces only the designated project-data asset, and signs the resulting APK using an app-managed signing key.
4. Verify the package signature and output before exposing the APK.
5. Save the APK in app-specific external files storage and expose it through Android's package-install flow using a content URI and FileProvider.
6. Show progress, cancellation, storage checks, clear errors, and a share/export option.

## Critical security and compatibility requirements
- Never install silently or bypass Android's package-installer confirmation.
- Never request broad storage access when app-specific storage and the Storage Access Framework are sufficient.
- The signing key must be generated locally and stored using Android Keystore where supported. The same key must be retained for updates to generated apps; losing it means future APKs cannot update existing installs with the same package ID.
- Each generated app needs a stable, validated application ID. Do not permit path traversal or arbitrary ZIP entry names.
- Re-signing an APK is not equivalent to merely changing a ZIP entry. The implementation must remove old signature metadata, create a valid new signature, and verify it. Prefer a maintained signing implementation; do not invent a partial APK v2/v3 signer.
- A generated app's package ID must be unique. The user must be able to choose a new ID or use a stable ID for updates.
- Validate on real devices across supported Android versions, including Android 10 (the user's currently reported device family) and newer versions.
- Keep template and AppMaker versions compatible. Template APK must be rebuilt whenever its manifest, resources, SDK settings, or reader code changes.

## Release build pipeline
The release workflow should:
1. Build the template APK from `engine/flutter_template`.
2. Verify that the APK contains the expected project-data placeholder and is installable.
3. Copy it into the AppMaker Android assets as a packaged offline template.
4. Build AppMaker.
5. Run unit/instrumentation tests for project serialization, template extraction, signature verification, and installer intent creation.
6. Publish the AppMaker APK only when all checks pass.

The workflow may need network access on the developer/build machine to fetch pinned build dependencies. This does not imply that the installed AppMaker uses the internet. For a strictly air-gapped release machine, all pinned dependencies and SDK components must first be supplied in a local cache.

## Current implementation status
This document is an architecture specification, not a claim that the mobile engine is implemented. The current Flutter app stores projects locally, and the Python CLI builds APKs on a computer with Flutter and Android SDK installed. The mobile app now has offline JSON project export/import to bridge project data to the existing computer CLI. The mobile template packaging, safe APK mutation/signing, Android installer bridge, and real-device validation are still required.
