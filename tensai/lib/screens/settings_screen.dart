import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../core/input_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/logo_widget.dart';

final _healthStatusProvider = StateProvider<String?>((ref) => null);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final healthStatus = ref.watch(_healthStatusProvider);

    ref.listen<AsyncValue<String>>(settingsNotifierProvider, (prev, next) {
      next.whenData((url) {
        if (_urlController.text != url) _urlController.text = url;
      });
    });

    final email = authAsync.valueOrNull?.email ?? '—';
    final baseUrl = settingsAsync.valueOrNull ?? '';
    final initial = email.isNotEmpty && email != '—' ? email[0].toUpperCase() : '?';

    if (_urlController.text.isEmpty && baseUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_urlController.text.isEmpty) _urlController.text = baseUrl;
      });
    }

    final isHealthy = healthStatus != null && healthStatus.toLowerCase().contains('ok');

    return Scaffold(
      appBar: AppBar(
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
          AppCard(
            title: 'Backend',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputStyles.standard(
                    labelText: 'Base URL',
                    hintText: 'https://api.example.com',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        onPressed: () async {
                          final url = _urlController.text.trim();
                          if (url.isEmpty) return;
                          await ref.read(settingsNotifierProvider.notifier).updateBaseUrl(url);
                          ref.read(_healthStatusProvider.notifier).state = null;
                        },
                        label: 'Save',
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final r = await ref.read(settingsNotifierProvider.notifier).checkHealth();
                        ref.read(_healthStatusProvider.notifier).state = r;
                      },
                      child: Text('Test', style: GoogleFonts.spaceGrotesk(color: AppColors.focusBorder)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
                if (healthStatus != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isHealthy ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          healthStatus,
                          style: GoogleFonts.spaceGrotesk(
                            color: isHealthy ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppCard(
            title: 'About',
            child: Column(
              children: [
                const LogoWidget(width: 60),
                const SizedBox(height: 12),
                Text(
                  'Tensai · AI Study Copilot',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${Constants.appVersion}',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.subtitle,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
