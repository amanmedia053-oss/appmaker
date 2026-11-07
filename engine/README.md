# AppMaker offline APK build engine

This engine packages one AppMaker project as a separate, standalone Flutter Android reading app. The generated app embeds the project's text in its APK and works without network access.

## Input format

Save one project as UTF-8 JSON, for example:

```json
{
  "name": "زما د شعرونو ټولګه",
  "category": "شعرونه",
  "createdAt": "2026-11-07T10:00:00",
  "books": [
    {"title": "لومړی شعر", "body": "دلته د شعر متن لیکل کېږي."}
  ]
}
```

## Build

From the repository root:

```bash
python3 tools/build_project.py \
  --input my_project.json \
  --output dist \
  --application-id com.example.mycollection
```

The APK is copied to `dist/<project-name>.apk`.

## Offline requirements and limitations

- Install Flutter, a compatible JDK, Android SDK, platform-tools, build-tools, and Gradle support before going offline.
- Run dependency resolution once while connected so Flutter's SDK and all required artifacts are cached. The build script itself uses `flutter pub get --offline` and `flutter build apk --offline`.
- The build machine must have enough RAM and disk space for Android compilation.
- This is a local build engine for a computer with the Android toolchain. A normal Flutter app cannot invoke Flutter/Gradle to compile a second APK directly inside an ordinary Android phone. Making that happen on-device would require bundling/maintaining a very large native toolchain and is not implemented here.
- The mobile app now exports a selected project as a JSON file through Android's share sheet and can import a compatible JSON project file offline. This moves project data between the phone and the computer CLI, but does not compile an APK on the phone.
- APK signing currently uses Flutter's standard debug/release build configuration. Configure a private release keystore before distributing production apps; never commit keystore files or passwords.
