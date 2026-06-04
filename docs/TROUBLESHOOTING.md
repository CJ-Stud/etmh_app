# ETMH — Troubleshooting

Common errors and exactly what to do about them. Search this page
(Ctrl/Cmd-F) for the error message you're seeing.

---

## "Konfigurasi Firebase belum lengkap" (the friendly error screen)

**What it means:** Either `lib/firebase_options.dart` is still the
placeholder, or its values don't match your Firebase project.

**Fix:** Re-run from the project root:

```bash
flutterfire configure
```

…and pick the right Firebase project. Then hot-restart the app
(`R` in the `flutter run` terminal).

---

## `Could not resolve the package 'firebase_ai'`

**Cause:** You're on an old Flutter SDK that pre-dates the `firebase_ai`
package, or your `pubspec.yaml` was edited.

**Fix:**

```bash
flutter --version           # must be 3.27 or higher
flutter upgrade
flutter pub get
```

---

## `Execution failed for task ':app:checkDebugAarMetadata'` / `uses-sdk:minSdkVersion 21 cannot be smaller than version 23`

**Cause:** Android `minSdk` is too low for Firebase Auth.

**Fix:** Re-read [`SETUP.md` step 5.1](SETUP.md#51-android). Make sure
`minSdk = 23` (or higher) in `android/app/build.gradle.kts`. Then:

```bash
flutter clean
flutter run
```

---

## `CocoaPods could not find compatible versions for pod "firebase_ai"`

**Cause:** iOS deployment target is below 15.0.

**Fix:** Re-read [`SETUP.md` step 5.2](SETUP.md#52-ios-macos-users-only).
Uncomment and set `platform :ios, '15.0'` in `ios/Podfile`, then:

```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter run
```

---

## `[firebase_ai/unavailable] Firebase AI Logic is not enabled for this project`

**Cause:** You didn't complete step 3.4 of setup — AI Logic was never
enabled in the Firebase console.

**Fix:**

1. Open <https://console.firebase.google.com>.
2. Pick your project.
3. Left sidebar → **Build → AI Logic**.
4. Click **Get started** and pick **Gemini Developer API**.
5. Wait ~30 seconds for it to provision.
6. Hot-restart the app.

---

## Email verification link clicked but app still says "Cek email kamu"

**Cause:** Firebase caches the verification flag for a few seconds.

**Fix:** Just wait 5 seconds. The app polls every 5 seconds and will
move on automatically. If still stuck after a minute:

- Force-close the app and reopen it.
- If still stuck, tap **Keluar** (sign out), then sign back in.

---

## `[cloud_firestore/permission-denied] Missing or insufficient permissions`

**Cause:** Firestore is in production mode but rules haven't been
published.

**Fix:** Paste the contents of `docs/firestore.rules` into the
**Rules** tab of Firestore in the Firebase Console and click
**Publish**.

---

## Insight card shows "Offline" badge even with Wi-Fi

**Cause:** Gemini call failed. Common reasons:

1. AI Logic isn't enabled (see above).
2. You're hitting the free-tier quota.
3. The model name `gemini-2.5-flash` was renamed/retired on your
   project.

**Fix:** Check the Firebase Console → AI Logic → Usage tab for quota.
If the model was retired, change the string `'gemini-2.5-flash'` in
`lib/services/gemini_insight_service.dart` to a currently-supported
model (check <https://firebase.google.com/docs/ai-logic/models>).

---

## `Unable to load asset: assets/lottie/milo_morning.json`

**Cause:** You deleted the `assets/lottie/` directory or one of its
files.

**Fix:** The app is designed to gracefully fall back to an emoji 🐱
when Lottie files are missing or invalid. If you're seeing this as a
**fatal error**, you also removed the directory entry from
`pubspec.yaml`. Restore the line:

```yaml
flutter:
  assets:
    - assets/lottie/
```

and run `flutter pub get`.

---

## "Gradle build failed to produce an .apk file"

**Cause:** Usually a leftover from a previous Flutter version.

**Fix:**

```bash
flutter clean
rm -rf android/.gradle android/app/build android/build
flutter pub get
flutter run
```

---

## Dependency resolution fails

**Cause:** Conflicting transitive versions, usually after you've
hand-edited `pubspec.yaml`.

**Fix:**

```bash
rm pubspec.lock
flutter clean
flutter pub get
```

If a specific package conflict is reported, search pub.dev for the
package and pin to a version that's listed as "compatible with
Firebase BoM 4.11.0 or higher".

---

## Hot reload doesn't reflect my Lottie changes

**Cause:** Asset changes need a full restart, not a hot reload.

**Fix:** In the `flutter run` terminal, press **`R`** (uppercase) for
hot-restart instead of `r` (lowercase, hot-reload).

---

## Still stuck?

1. Run `flutter doctor -v` and read every warning.
2. Run `flutter pub deps` to see the dependency tree.
3. Check the Firebase Console → Project Settings → Your apps to make
   sure both Android and iOS apps are registered.
4. Search the exact error message on
   <https://github.com/firebase/flutterfire/issues>.
