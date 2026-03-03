import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

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

    if (_urlController.text.isEmpty && baseUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_urlController.text.isEmpty) _urlController.text = baseUrl;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.subtitle,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 24),
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(email),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/send-otp');
            },
            child: const Text('Logout'),
          ),
          const SizedBox(height: 32),
          Text('Backend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.example.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: () async {
                  final url = _urlController.text.trim();
                  if (url.isEmpty) return;
                  await ref.read(settingsNotifierProvider.notifier).updateBaseUrl(url);
                  ref.read(_healthStatusProvider.notifier).state = null;
                },
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  final r = await ref.read(settingsNotifierProvider.notifier).checkHealth();
                  ref.read(_healthStatusProvider.notifier).state = r;
                },
                child: const Text('Check connection'),
              ),
            ],
          ),
          if (healthStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              healthStatus,
              style: TextStyle(
                color: healthStatus.toLowerCase().contains('ok') ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${Constants.appName} · ${Constants.appVersion}'),
        ],
      ),
    );
  }
}
