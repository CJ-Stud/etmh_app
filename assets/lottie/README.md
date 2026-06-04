# Milo Mascot Animations

This folder holds the four time-of-day Lottie animations the app shows
as "Milo the Cat":

| File                  | Used when    | Greeting (from spec)                                                            |
| --------------------- | ------------ | ------------------------------------------------------------------------------- |
| `milo_morning.json`   | 05:00–10:59  | "Meow-ning! Gimana energi kamu pagi ini?"                                       |
| `milo_afternoon.json` | 11:00–15:59  | "Siang yang sibuk ya? Istirahat sebentar yuk. Bagaimana perasaanmu?"            |
| `milo_evening.json`   | 16:00–20:59  | "Hari mulai sore, kamu hebat sudah bertahan sejauh ini. Bagaimana hatimu?"      |
| `milo_night.json`     | 21:00–04:59  | "Hari yang panjang selesai. Sebelum tidur, yuk rilis emosimu ke Milo."          |

## What ships here are PLACEHOLDERS

The four `.json` files in this folder are intentionally invalid Lottie
files so the app's `errorBuilder` falls back to a friendly 🐱 emoji.
This way `flutter pub get` and `flutter run` never fail because of a
missing asset.

## Replacing with real animations

1. Open https://lottiefiles.com and search for "cat" (or commission an
   artist for a custom Milo design).
2. Download the four animations you like as **`.json`** (Lottie JSON,
   not GIF or MP4).
3. Drop them into this folder using the exact filenames above —
   overwriting these placeholder files.
4. Hot-restart the app. Milo will start animating.

No code changes are required.
