import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';
import '../models/ask_response.dart';

part 'ask_provider.g.dart';

@Riverpod(keepAlive: true)
class AskNotifier extends _$AskNotifier {
  @override
  Future<AskResponse?> build() async => null;

  Future<AsyncValue<AskResponse>> ask(String question) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(apiServiceProvider).dio;
      final res = await dio.post<Map<String, dynamic>>(
        '/ask',
        data: {'question': question},
      );
      final data = res.data;
      if (data == null) {
        state = const AsyncValue.data(null);
        return AsyncValue.error('No response', StackTrace.current);
      }
      final response = AskResponse.fromJson(data);
      state = AsyncValue.data(response);
      return AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
