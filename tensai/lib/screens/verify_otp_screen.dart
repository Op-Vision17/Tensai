import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/input_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/logo_widget.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _codeController = TextEditingController();
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    if (_resendCountdown > 0) return;
    setState(() => _resendCountdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendCountdown > 0) _resendCountdown--;
      });
      if (_resendCountdown <= 0) _timer?.cancel();
    });
  }

  Future<void> _verify() async {
    final email = widget.email?.trim();
    if (email == null || email.isEmpty) {
      if (mounted) AppSnackbar.showError(context, 'Email missing. Go back and enter email.');
      return;
    }
    final code = _codeController.text.trim();
    if (code.length != 6) {
      if (mounted) AppSnackbar.showError(context, 'Enter the 6-digit code');
      return;
    }
    await ref.read(authNotifierProvider.notifier).verifyOtp(email, code);
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth != null && auth.isLoggedIn) {
      context.go('/ask');
    }
  }

  Future<void> _resendOtp() async {
    final email = widget.email?.trim();
    if (email == null || email.isEmpty || _resendCountdown > 0) return;
    await ref.read(authNotifierProvider.notifier).sendOtp(email);
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth?.error != null) {
      AppSnackbar.showError(context, auth!.error!);
    } else {
      _startResendCountdown();
      AppSnackbar.showSuccess(context, 'OTP sent again');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.valueOrNull?.isLoading ?? false;
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenData((s) {
        if (s.error != null && mounted) {
          AppSnackbar.showError(context, s.error!);
        }
      });
    });

    final email = widget.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify code', style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.subtitle,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const LogoWidget(width: 70),
              const SizedBox(height: 20),
              Text(
                'Check your email',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email.isNotEmpty ? 'Enter the code sent to $email' : 'Enter verification code',
                style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputStyles.otp(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: isLoading ? null : _verify,
                      label: 'Verify',
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _resendCountdown > 0 ? null : _resendOtp,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend OTP in ${_resendCountdown}s'
                            : 'Resend OTP',
                        style: GoogleFonts.spaceGrotesk(
                          color: _resendCountdown > 0
                              ? AppColors.subtitle
                              : AppColors.focusBorder,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
