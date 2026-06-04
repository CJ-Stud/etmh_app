// lib/main.dart
//
// Bootstrap order matters:
//   1. WidgetsFlutterBinding   — required before any plugin call.
//   2. Indonesian date locale  — used by InsightCard.
//   3. Firebase                — Auth, Firestore, AI Logic.
//   4. Hive                    — open the local cache box.
//   5. Repository + Provider   — DI wiring.
//   6. AuthGuard               — gates the entire app.
//
// If Firebase initialisation fails (the most common reason being a
// missing or stale firebase_options.dart), we show a friendly screen
// telling the user exactly what to do instead of crashing to red.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/app_prefs.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/emotion_repository.dart';
import 'firebase_options.dart';
import 'presentation/guards/root_gate.dart';
import 'presentation/providers/emotion_provider.dart';
import 'services/gemini_insight_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Indonesian locale for DateFormat. Loaded once.
  await initializeDateFormatting('id_ID');

  // Open the Hive box first — we'll need it whether Firebase succeeds
  // or not (for offline mode in the future).
  await Hive.initFlutter();
  final logBox =
      await Hive.openBox<String>(EmotionRepository.boxName);

  // Small app-level flags (onboarding, reminders).
  final appPrefs = AppPrefs(await SharedPreferences.getInstance());

  // Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Most common cause: the user hasn't run `flutterfire configure` yet
    // and the placeholder firebase_options.dart was used as-is.
    runApp(_FatalErrorApp(message: e.toString()));
    return;
  }

  final repository = EmotionRepository(box: logBox);
  final aiService = GeminiInsightService();

  // Local notifications: initialise, and (re)schedule if the user has
  // reminders turned on. Wrapped so a failure here never blocks startup.
  final notificationService = NotificationService();
  try {
    await notificationService.init();
    if (appPrefs.remindersEnabled) {
      await notificationService.scheduleDailyReminders();
    }
  } catch (_) {
    // Notifications are non-critical; continue launching the app.
  }

  runApp(EtmhApp(
    repository: repository,
    aiService: aiService,
    appPrefs: appPrefs,
    notificationService: notificationService,
  ));
}

class EtmhApp extends StatelessWidget {
  final EmotionRepository repository;
  final GeminiInsightService aiService;
  final AppPrefs appPrefs;
  final NotificationService notificationService;

  const EtmhApp({
    super.key,
    required this.repository,
    required this.aiService,
    required this.appPrefs,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<EmotionRepository>.value(value: repository),
        Provider<GeminiInsightService>.value(value: aiService),
        Provider<AppPrefs>.value(value: appPrefs),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<EmotionProvider>(
          create: (_) => EmotionProvider(
            repository: repository,
            aiService: aiService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ETMH',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RootGate(),
      ),
    );
  }
}

/// Last-resort error screen. The user sees this only if Firebase can't
/// initialise, which means setup is incomplete. The text walks them to
/// the SETUP.md doc.
class _FatalErrorApp extends StatelessWidget {
  final String message;
  const _FatalErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETMH — Setup needed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 64,
                    color: AppColors.primarySage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Konfigurasi Firebase belum lengkap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'ETMH membutuhkan proyek Firebase. Jalankan langkah-'
                    'langkah di docs/SETUP.md, terutama bagian '
                    '"4. Run flutterfire configure", lalu hot-restart.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
