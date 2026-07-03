# Building ASCII Fluid

The app is a single self-contained web app (`index.html` + `fonts/`) that also
ships as a native Android APK via [Capacitor](https://capacitorjs.com/).

`index.html` at the repo root is the **source of truth** — it runs as-is in any
browser and is what GitHub Pages serves. The Android project wraps a synced copy.

```
index.html            ← the app (open directly, or served by Pages)
fonts/                ← bundled woff2 fonts (+ OFL licenses)
scripts/sync-www.mjs  ← copies index.html + fonts → www/  (Capacitor webDir)
capacitor.config.json ← app id / name / webDir
android/              ← generated native project (gradle → APK)
```

## Run the web app

Just open `index.html`, or serve the folder:

```bash
npx serve .        # or: python3 -m http.server
```

Device-tilt gravity needs a **secure context** (https or localhost) and a real
device with an orientation sensor; on desktop the rest works, tilt is a no-op.

## Build the Android APK

### Prerequisites
- **JDK 17** (Gradle/AGP are not compatible with JDK 24+). A portable Temurin 17
  works without touching your system Java.
- **Android SDK**: `platform-tools`, `platforms;android-34`, `build-tools;34.0.0`.
- **Node 18+**.

This repo was bootstrapped with `scripts/setup-android.sh`, which installs a
portable JDK 17 to `~/jdk17` and the SDK to `~/Android/Sdk` (no root required):

```bash
bash scripts/setup-android.sh
```

### One-line build

```bash
export JAVA_HOME="$HOME/jdk17"
export ANDROID_HOME="$HOME/Android/Sdk"
npm run apk
```

`npm run apk` = sync `www/` → `npx cap copy android` → `./gradlew assembleDebug`.
The debug APK lands at:

```
android/app/build/outputs/apk/debug/app-debug.apk
```

Install on a connected device:

```bash
~/Android/Sdk/platform-tools/adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

### Open in Android Studio instead

```bash
npm run open      # sync + npx cap open android
```

Android Studio will handle the SDK/licenses for you; then Build → Build APK,
or Run ▶ onto a device.

## npm scripts

| script          | does                                                        |
|-----------------|-------------------------------------------------------------|
| `npm run sync`  | copy `index.html` + `fonts/` into `www/`                    |
| `npm run copy`  | sync, then `npx cap copy android`                           |
| `npm run open`  | copy, then open the Android project in Android Studio       |
| `npm run apk`   | copy, then `gradlew assembleDebug` → debug APK              |

## Release build (signed)

The `assembleDebug` output is signed with the debug key (fine for sideloading).
For a Play-ready release, create a keystore and configure
`android/app/build.gradle` signingConfigs, then `./gradlew assembleRelease`
(or `bundleRelease` for an `.aab`). See the Capacitor
[Android deployment guide](https://capacitorjs.com/docs/android/deploying-to-google-play).

## Native shell customizations

`android/app/src/main/java/com/voyd/asciifluid/MainActivity.java` enables
immersive fullscreen, keep-screen-on, and draws under the display cutout.
Theme/splash are dark (`#0a0c09`) via `res/values/styles.xml` + `colors.xml`.
`capacitor.config.json` sets `androidScheme: https` so the DeviceOrientation
(tilt/gravity) API runs in a secure context inside the WebView.
