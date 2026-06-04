// lib/presentation/screens/help/crisis_help_screen.dart
//
// A static, always-available support screen. It does NOT depend on the
// AI — the resources are hard-coded and verified, so they're reachable
// even offline or if Gemini fails. Tone is warm and non-triggering; it
// never describes methods, only points to people who can help.
//
// Resources (Indonesia, verified mid-2025/2026):
//   • 119 ext. 8  — national mental-health emergency line (SEJIWA /
//     Healing119.id), 24 hours, free, confidential.
//   • healing119.id — online chat / voice support, 24 hours, free.
//   • 119 — national medical emergency (ambulance).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class CrisisHelpScreen extends StatelessWidget {
  const CrisisHelpScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _toast(context, 'Tidak dapat membuka otomatis. Nomor/tautan bisa '
            'kamu salin secara manual.');
      }
    } catch (_) {
      if (context.mounted) {
        _toast(context, 'Tidak dapat membuka otomatis. Nomor/tautan bisa '
            'kamu salin secara manual.');
      }
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Butuh Bantuan?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.secondaryLavenderDeep,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Kamu tidak sendirian',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Kalau saat ini terasa sangat berat, kamu berhak mendapat '
              'dukungan dari orang yang siap mendengarkan. Layanan di bawah '
              'ini gratis, rahasia, dan tersedia 24 jam.',
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _ResourceCard(
              icon: Icons.call_rounded,
              title: 'Telepon 119 ext. 8',
              subtitle:
                  'Layanan darurat kesehatan jiwa nasional (SEJIWA / '
                  'Healing119). Tekan 119, lalu pilih ekstensi 8.',
              actionLabel: 'Telepon 119',
              onTap: () => _launch(context, Uri(scheme: 'tel', path: '119')),
            ),
            const SizedBox(height: AppSpacing.md),

            _ResourceCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat di healing119.id',
              subtitle:
                  'Bicara lewat chat atau panggilan suara dengan konselor '
                  'terlatih, tanpa perlu mendaftar.',
              actionLabel: 'Buka healing119.id',
              onTap: () => _launch(
                context,
                Uri.parse('https://www.healing119.id'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _ResourceCard(
              icon: Icons.local_hospital_outlined,
              title: 'Darurat medis: 119',
              subtitle:
                  'Jika ada bahaya langsung pada keselamatan, hubungi 119 '
                  'atau pergi ke fasilitas kesehatan terdekat.',
              actionLabel: 'Telepon 119',
              onTap: () => _launch(context, Uri(scheme: 'tel', path: '119')),
            ),

            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondaryLavender.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Text(
                'Milo adalah teman pendamping, bukan pengganti tenaga '
                'profesional. Untuk dukungan yang lebih mendalam, '
                'menghubungi psikolog atau dokter sangat dianjurkan.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primarySageDeep, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
