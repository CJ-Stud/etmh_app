// lib/core/services/app_prefs.dart
//
// Thin, typed wrapper over SharedPreferences for small app-level flags.
// Loaded once in main() and provided via Provider, so reads are sync.

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs(this._prefs);
  final SharedPreferences _prefs;

  static const _kOnboardingDone = 'onboarding_done';
  static const _kRemindersEnabled = 'reminders_enabled';

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_kOnboardingDone, value);

  // Reserved for the notifications step (Batch 3b).
  bool get remindersEnabled => _prefs.getBool(_kRemindersEnabled) ?? false;
  Future<void> setRemindersEnabled(bool value) =>
      _prefs.setBool(_kRemindersEnabled, value);
}
