import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants.dart';
import '../core/storage.dart';
import 'auth_provider.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<String> build() async {
    final url = await Storage.getPref(Constants.keyBaseUrl);
    return url ?? Constants.defaultBaseUrl;
  }

  Future<void> updateBaseUrl(String url) async {
    await Storage.setPref(Constants.keyBaseUrl, url);
    state = AsyncValue.data(url);
  }

  Future<String> checkHealth() async {
    try {
      final dio = ref.read(apiServiceProvider).dio;
      final res = await dio.get<Map<String, dynamic>>('/health');
      final data = res.data;
      if (data != null) {
        final status = data['status'] as String?;
        final service = data['service'] as String?;
        final model = data['model'] as String?;
        if (status == 'ok') {
          return '${service ?? 'API'} ok · model: ${model ?? '—'}';
        }
      }
      return 'Unexpected response';
    } catch (e) {
      return e.toString();
    }
  }
}
