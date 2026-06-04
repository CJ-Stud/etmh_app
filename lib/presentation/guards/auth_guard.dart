// lib/presentation/guards/auth_guard.dart
//
// A single widget that gates the entire app on auth state:
//
//   ┌─ No user signed in       → LoginScreen
//   ├─ Signed in, NOT verified → EmailVerificationScreen
//   └─ Signed in + verified    → child (HomeScreen)

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/login_screen.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSub;
  Timer? _verificationPoller;
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_handleUser);
  }

  Future<void> _handleUser(User? u) async {
    // Firebase caches `emailVerified` aggressively — force a reload so we
    // always work against the freshest value.
    try {
      await u?.reload();
    } catch (_) {
      // Reload may fail if the token expired; the next auth state change
      // will re-trigger this handler with a fresh user object.
    }
    if (!mounted) return;
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
      _loading = false;
    });
    _managePoller();
  }

  /// While the user is signed in but unverified, poll every 5s so the
  /// verification screen advances automatically once they tap the
  /// confirmation link in their inbox.
  void _managePoller() {
    _verificationPoller?.cancel();
    final u = _user;
    if (u != null && !u.emailVerified) {
      _verificationPoller = Timer.periodic(
        const Duration(seconds: 5),
        (_) async {
          try {
            await FirebaseAuth.instance.currentUser?.reload();
          } catch (_) {/* swallow */}
          final fresh = FirebaseAuth.instance.currentUser;
          if (fresh?.emailVerified == true && mounted) {
            setState(() => _user = fresh);
            _verificationPoller?.cancel();
          }
        },
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FirebaseAuth.instance.currentUser?.reload().then((_) {
        if (mounted) {
          setState(() => _user = FirebaseAuth.instance.currentUser);
        }
      }).catchError((_) {/* swallow */});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _verificationPoller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primarySage),
        ),
      );
    }
    final user = _user;
    if (user == null) return const LoginScreen();
    if (!user.emailVerified) return const EmailVerificationScreen();
    return widget.child;
  }
}
