// lib/presentation/guards/root_gate.dart
//
// Decides the very first screen: show the one-time onboarding if it
// hasn't been completed, otherwise hand control to the AuthGuard.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_prefs.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import 'auth_guard.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late bool _onboardingDone;

  @override
  void initState() {
    super.initState();
    _onboardingDone = context.read<AppPrefs>().onboardingDone;
  }

  void _finishOnboarding() async {
    await context.read<AppPrefs>().setOnboardingDone(true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingDone) {
      return OnboardingScreen(onDone: _finishOnboarding);
    }
    return const AuthGuard(child: HomeScreen());
  }
}
