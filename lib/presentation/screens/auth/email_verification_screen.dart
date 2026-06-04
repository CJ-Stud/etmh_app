// lib/presentation/screens/auth/email_verification_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  String? _status;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _status = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      setState(() => _status = 'Email verifikasi telah dikirim ulang.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _status =
          e.code == 'too-many-requests'
              ? 'Terlalu banyak percobaan. Coba lagi nanti.'
              : 'Gagal mengirim ulang email.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: AppColors.primarySage,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Cek email kamu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kami sudah mengirim link verifikasi ke\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (_status != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _status!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primarySageDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(
                    _resending ? 'Mengirim…' : 'Kirim ulang email',
                  ),
                ),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
