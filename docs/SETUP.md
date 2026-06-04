# ETMH — Setup Guide (from zero to running app)

This guide takes you from **a fresh computer** with nothing installed to
a **running ETMH app on your phone or emulator**. Follow the steps in
order. Every command can be copy-pasted directly into your terminal.

> ⏱ **Estimated time:** 30–45 minutes for a first-timer. 15 minutes if
> you already have Flutter & a Firebase account.

---

## Table of Contents

1. [Prerequisites — install these once](#1-prerequisites)
2. [Get the project on your machine](#2-get-the-project)
3. [Create your Firebase project](#3-create-your-firebase-project)
4. [Generate `firebase_options.dart`](#4-generate-firebase_optionsdart)
5. [Set Android & iOS minimum versions](#5-set-android--ios-minimum-versions)
6. [Run the app](#6-run-the-app)
7. [Verify it all works](#7-verify-it-all-works)
8. [Optional: replace the Milo placeholder](#8-optional-replace-milo-placeholder)
9. [Going to production](#9-going-to-production)

---

## 1. Prerequisites

### 1.1 Install Flutter SDK (`3.27` or newer)

Follow the official instructions for your OS:
**<https://docs.flutter.dev/get-started/install>**

After install, in a **new terminal window**, run:

```bash
flutter --version
```

You must see version **3.27.0 or higher**. If not, run `flutter upgrade`.

Then run:

```bash
flutter doctor
```

Fix every ❌ shown. The two most common ones:

| ❌ Shown by `flutter doctor` | How to fix |
| --- | --- |
| "Android toolchain — Android Studio not installed" | Install Android Studio from <https://developer.android.com/studio>, open it once, then accept SDK licenses with `flutter doctor --android-licenses`. |
| "Xcode not installed" (macOS only) | Install Xcode from the App Store. Then run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch`. |

Stop and resolve every issue before continuing. **Do not skip this.**

### 1.2 Install a code editor

Either is fine:

- **VS Code** + the official "Flutter" extension (recommended for first-timers).
- **Android Studio** with the Flutter plugin.

### 1.3 Install Node.js (only required if Firebase CLI isn't already installed)

The FlutterFire CLI itself doesn't need Node.js, but the Firebase CLI
(used in step 3) does:
**<https://nodejs.org/>** — pick the LTS version.

Verify:

```bash
node --version   # should print v20.x or v22.x
```

### 1.4 Install the Firebase CLI

```bash
npm install -g firebase-tools
```

Verify:

```bash
firebase --version   # should print 13.x or higher
firebase login       # opens browser, sign in with the Google account you'll use
```

### 1.5 Install the FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

If the install warns about a directory not being on your `PATH`, follow
its instructions to add it. On macOS/Linux, that's usually adding this
line to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Then open a **new** terminal and verify:

```bash
flutterfire --version
```

---

## 2. Get the project

Unzip the project archive to any folder, then `cd` into it:

```bash
unzip etmh_app.zip
cd etmh_app
```

The first time only, run:

```bash
flutter create --org com.etmh --project-name etmh_app .
```

> **What this does:** Flutter's `lib/` and `pubspec.yaml` already exist
> in the archive. The command generates the native scaffolding
> (`android/`, `ios/`, etc.) **without overwriting anything that's
> already there**. It just fills in the gaps.

Then install Dart dependencies:

```bash
flutter pub get
```

You should see `Got dependencies!`. If you see resolution errors, see
[`TROUBLESHOOTING.md`](TROUBLESHOOTING.md#dependency-resolution-fails).

---

## 3. Create your Firebase project

ETMH needs Firebase for authentication, Firestore (cloud sync), **and**
Gemini AI Logic (the Milo insights). All three are configured from one
Firebase project.

### 3.1 Create the project

1. Open <https://console.firebase.google.com>.
2. Click **Add project**.
3. Name it anything (e.g. *"My ETMH App"*).
4. **Google Analytics:** you can disable it for this app.
5. Wait ~30 seconds for the project to finish creating.

### 3.2 Enable Email/Password authentication

1. In the Firebase Console left sidebar: **Build → Authentication**.
2. Click **Get started**.
3. On the *Sign-in method* tab, click **Email/Password**.
4. Toggle the first switch **on** (leave the "passwordless" one off).
5. Click **Save**.

### 3.3 Enable Cloud Firestore

1. Left sidebar: **Build → Firestore Database**.
2. Click **Create database**.
3. Pick a location closest to your users (for Indonesia: `asia-southeast2`).
4. Choose **Start in production mode**.
5. Click **Create**.
6. Go to the **Rules** tab and paste the rules from
   [`docs/firestore.rules`](firestore.rules), then click **Publish**.

### 3.4 Enable Firebase AI Logic (the Gemini integration)

1. Left sidebar: **Build → AI Logic** (sometimes shown as "Gemini API").
2. Click **Get started**.
3. Pick the **Gemini Developer API** option (the simpler one — no
   billing required for the free tier).
4. Click **Enable**.

> 💡 **Billing note:** The Gemini Developer API on Firebase AI Logic has
> a free tier that's more than enough for ETMH's traffic. You'll only
> see a billing prompt if you exceed it. Read more:
> <https://firebase.google.com/docs/ai-logic/pricing>

---

## 4. Generate `firebase_options.dart`

This is the step that connects your local code to **your** Firebase
project.

From the project root (where `pubspec.yaml` lives), run:

```bash
flutterfire configure
```

You'll be prompted interactively:

| Prompt | Answer |
| --- | --- |
| "Select a Firebase project to configure your Flutter application with" | Pick the project you created in step 3. |
| "Which platforms should your configuration support?" | Tick **android** and **ios**. Use space to toggle, enter to confirm. |
| "Which android application id..." | Accept the default (`com.etmh.etmh_app`) by pressing enter. |
| "Which ios bundle id..." | Accept the default. |

The command will:

- Register both platforms with your Firebase project.
- Overwrite `lib/firebase_options.dart` (the placeholder) with the real
  configuration.
- Drop `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist` into the right places.

**You should never edit those three files by hand.** Re-running
`flutterfire configure` regenerates them whenever you add a platform.

---

## 5. Set Android & iOS minimum versions

Firebase Auth needs Android SDK ≥ 23. `firebase_ai` needs iOS ≥ 15.
Flutter's defaults are slightly lower, so two tiny edits:

### 5.1 Android

Open `android/app/build.gradle.kts` (or `android/app/build.gradle` on
older Flutter). Find the line that says:

```kotlin
minSdk = flutter.minSdkVersion
```

…or, in the older Groovy DSL:

```groovy
minSdkVersion flutter.minSdkVersion
```

Change it to:

```kotlin
minSdk = 23
```

…or Groovy:

```groovy
minSdkVersion 23
```

Save the file. That's the only Android change you need to make.

### 5.2 iOS (macOS users only)

Open `ios/Podfile`. Near the top, find:

```ruby
# platform :ios, '13.0'
```

Uncomment and change to:

```ruby
platform :ios, '15.0'
```

Save. Then run:

```bash
cd ios
pod install --repo-update
cd ..
```

---

## 6. Run the app

### 6.1 Start a device

Either:

- **Android emulator:** Open Android Studio → Device Manager → click the
  ▶ button next to any virtual device.
- **iOS simulator** (macOS): `open -a Simulator`.
- **Physical Android:** Plug in via USB, enable USB debugging in
  Developer Options, accept the prompt on your phone.
- **Physical iPhone:** Plug in via USB, trust the computer when prompted.

Confirm Flutter sees your device:

```bash
flutter devices
```

### 6.2 Run

```bash
flutter run
```

The first run takes 3–5 minutes (Gradle downloads, CocoaPods, etc.).
Subsequent runs are seconds.

When the app loads, you should see the **ETMH login screen**.

---

## 7. Verify it all works

1. **Sign up:** Tap "Belum punya akun? Daftar", enter an email and a
   password (≥ 6 chars), tap **Daftar**.
2. **Verify email:** Open the inbox of the email you used. Click the
   verification link.
3. **Wait 5 seconds:** the app polls every 5 seconds and will jump to
   the home screen automatically.
4. **Tap an emoji:** Pick any emoji from the row. The button briefly
   highlights, then Milo's insight card starts loading.
5. **Read the insight:** Within a few seconds, an empathetic Bahasa
   Indonesia paragraph from Gemini appears.

If any step fails, see [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

---

## 8. Optional: replace the Milo placeholder

The shipped app has placeholder Lottie files, so where Milo should be
you currently see a friendly cat emoji 🐱 in a lavender circle. To swap
in real animations:

1. Visit <https://lottiefiles.com> and search "cat" / "kitten".
2. Download **four** animations as `.json` (one per time-of-day).
3. Replace the four files in `assets/lottie/`:
   - `milo_morning.json`
   - `milo_afternoon.json`
   - `milo_evening.json`
   - `milo_night.json`
4. Hot-restart (`R` in the `flutter run` terminal).

No code changes required.

---

## 9. Going to production

When you're ready to ship to the Play Store / App Store:

| Task | Where to read more |
| --- | --- |
| Sign your Android build | <https://docs.flutter.dev/deployment/android> |
| Sign your iOS build | <https://docs.flutter.dev/deployment/ios> |
| Enable Firebase App Check (anti-abuse) | <https://firebase.google.com/docs/app-check/flutter/default-providers> |
| Tighten Firestore security rules | `docs/firestore.rules` is a sensible starting point. |
| Bump bundle ID | Search-and-replace `com.etmh.etmh_app` everywhere. |
| Set release-mode flags | `flutter build apk --release` / `flutter build ipa --release` |

---

## You're done 🎉

If you got here with the app running and the Milo insights generating,
**setup is complete**. Everything else (UI tweaks, new features) is just
editing Dart files inside `lib/`.

If anything broke, jump to [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
