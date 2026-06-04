// lib/presentation/widgets/smooth_tap.dart
//
// Two small helpers that make the whole app feel more responsive:
//
//   • SmoothTap        — wrap any card/chip to add a Material ink ripple,
//                        a light haptic tick, and a subtle press-in scale.
//                        Replaces bare GestureDetectors that feel "dead".
//   • fadeThroughRoute — a gentle fade + rise page transition to replace
//                        the default abrupt MaterialPageRoute push.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmoothTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const SmoothTap({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<SmoothTap> createState() => _SmoothTapState();
}

class _SmoothTapState extends State<SmoothTap> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap == null
              ? null
              : () {
                  _setPressed(false);
                  HapticFeedback.lightImpact();
                  widget.onTap!();
                },
          child: widget.child,
        ),
      ),
    );
  }
}

/// A calm fade + slight upward slide transition. Usage:
///   Navigator.of(context).push(fadeThroughRoute(const CalendarScreen()));
Route<T> fadeThroughRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
