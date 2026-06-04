// lib/presentation/screens/settings/settings_screen.dart
//
// Houses the daily-reminder toggle and sign-out. Toggling reminders on
// requests OS permission, then schedules; off cancels everything. The
// choice is remembered via AppPrefs.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _reminders;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reminders = context.read<AppPrefs>().remindersEnabled;
  }

  Future<void> _toggleReminders(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);

    final notif = context.read<NotificationService>();
    final prefs = context.read<AppPrefs>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (value) {
        final granted = await notif.requestPermission();
        if (!granted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Izinkan notifikasi di Pengaturan HP untuk mengaktifkan '
                'pengingat.',
              ),
            ),
          );
          return;
        }
        await notif.scheduleDailyReminders();
        await prefs.setRemindersEnabled(true);
        if (mounted) setState(() => _reminders = true);
        messenger.showSnackBar(
          const SnackBar(content: Text('Pengingat harian diaktifkan 🌱')),
        );
      } else {
        await notif.cancelAll();
        await prefs.setRemindersEnabled(false);
        if (mounted) setState(() => _reminders = false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    Navigator.of(context).pop();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _sendTest() async {
    final notif = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    final granted = await notif.requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Izinkan notifikasi di Pengaturan HP terlebih dulu.'),
        ),
      );
      return;
    }
    await notif.showTestNotification();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Notifikasi tes akan muncul sebentar lagi 🌱'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: SwitchListTile.adaptive(
                value: _reminders,
                onChanged: _busy ? null : _toggleReminders,
                activeThumbColor: AppColors.primarySage,
                title: const Text(
                  'Pengingat harian',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Milo mengingatkanmu mencatat emosi pada pagi, siang, '
                  'sore, dan malam.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primarySageDeep,
              ),
              title: const Text(
                'Kirim notifikasi tes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Cek apakah notifikasi berfungsi di HP ini.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              onTap: _sendTest,
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.textSecondary,
              ),
              title: const Text(
                'Keluar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
