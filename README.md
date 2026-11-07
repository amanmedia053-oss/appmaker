# AppMaker

A beautiful, offline-first Flutter starter for creating content-based app projects.

## Current milestone
- Pashto right-to-left interface.
- Create local app projects: books, poetry, educational, magazine, and personal collections.
- Add and read writing entries inside each project.
- Project data is stored on-device with SharedPreferences.
- No account, username, sign-in, Firebase, or network service is needed for normal use.

## Build the AppMaker Android APK
The GitHub Actions workflow builds the AppMaker application itself and uploads the APK as a workflow artifact.

1. Open the **Actions** tab.
2. Select **Build AppMaker Android APK**.
3. Run the workflow, or push a commit to `main`.
4. Download the APK from the completed workflow's **Artifacts** section.

## Important: per-project APK generation
This first milestone is the offline project/content builder. It does **not** yet generate a separate Android APK for every user-created project.

A true fully-offline APK generator running on an Android phone needs a local Android build toolchain (JDK, Android SDK/build-tools, Gradle, a template project, signing flow, and substantial device storage/RAM). Flutter alone cannot compile another Android app from Dart code at runtime. The next engineering milestone must implement and validate that build engine, or use a desktop build companion. The current UI labels this feature as not yet active rather than pretending it works.

## Run locally
```bash
flutter create . --platforms=android --org com.appmaker
flutter pub get
flutter run
```

## Tech
- Flutter / Dart
- SharedPreferences for local persistence


## Offline APK build engine

A first local build engine is available in `tools/build_project.py` with a standalone reading-app template in `engine/flutter_template`. It packages one project JSON file into its own Android APK using a locally installed Flutter and Android SDK toolchain. See [engine/README.md](engine/README.md) for the input format and commands.

**Current limitation:** the mobile AppMaker app does not yet export its locally stored projects to JSON automatically, and a normal Flutter Android app cannot compile another APK directly on-device without a very large bundled native build toolchain. The current engine therefore runs on a computer with the toolchain installed; it can build offline after all SDK and dependency artifacts have been cached.
