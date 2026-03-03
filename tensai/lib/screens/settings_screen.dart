import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/logo_widget.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final email = authAsync.valueOrNull?.email ?? '—';
    final initial = email.isNotEmpty && email != '—' ? email[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarLogo(size: 32),
        title: Text('Settings', style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.subtitle,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppCard(
            title: 'Account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.3),
                      child: Text(
                        initial,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.focusBorder,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        email,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GradientButton(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/send-otp');
                  },
                  label: 'Sign Out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
