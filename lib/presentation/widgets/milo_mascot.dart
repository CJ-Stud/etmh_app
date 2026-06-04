// lib/presentation/widgets/milo_mascot.dart
//
// "Milo the Cat" — the soul of ETMH. Time-of-day Lottie + scripted copy.
// The widget degrades gracefully to an emoji placeholder if a Lottie
// file is missing, so the app never crashes even before you supply
// real animations.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/emotion_entry.dart';

class MiloMascot extends StatelessWidget {
  final EmotionSlot? slot; // null → derive from current time
  final bool showGreeting;
  final bool compact;

  const MiloMascot({
    super.key,
    this.slot,
    this.showGreeting = true,
    this.compact = false,
  });

  EmotionSlot get _activeSlot =>
      slot ?? EmotionSlot.fromHour(DateTime.now().hour);

  String get _lottieAsset {
    switch (_activeSlot) {
      case EmotionSlot.morning:
        return 'assets/lottie/milo_morning.json';
      case EmotionSlot.afternoon:
        return 'assets/lottie/milo_afternoon.json';
      case EmotionSlot.evening:
        return 'assets/lottie/milo_evening.json';
      case EmotionSlot.night:
        return 'assets/lottie/milo_night.json';
    }
  }

  /// Locked to product spec — do not edit without product approval.
  String get _greeting {
    switch (_activeSlot) {
      case EmotionSlot.morning:
        return 'Meow-ning! Gimana energi kamu pagi ini?';
      case EmotionSlot.afternoon:
        return 'Siang yang sibuk ya? Istirahat sebentar yuk. Bagaimana perasaanmu?';
      case EmotionSlot.evening:
        return 'Hari mulai sore, kamu hebat sudah bertahan sejauh ini. Bagaimana hatimu?';
      case EmotionSlot.night:
        return 'Hari yang panjang selesai. Sebelum tidur, yuk rilis emosimu ke Milo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = compact ? 96.0 : 200.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: Lottie.asset(
            _lottieAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _placeholderAvatar(size),
          ),
        ),
        if (showGreeting) ...[
          const SizedBox(height: AppSpacing.md),
          _SpeechBubble(text: _greeting),
        ],
      ],
    );
  }

  Widget _placeholderAvatar(double size) => Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.secondaryLavender.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text('🐱', style: TextStyle(fontSize: size * 0.5)),
      );
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryLavender.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.secondaryLavender),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
