import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants.dart';
import '../core/storage.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

part 'auth_provider.g.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiServiceProvider).dio);
});

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.email,
    this.isLoading = false,
    this.error,
  });

  final bool isLoggedIn;
  final String? email;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isLoggedIn,
    String? email,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    final token = await Storage.getSecure(Constants.keyAccessToken);
    final email = await Storage.getSecure(Constants.keyAuthEmail);
    return AuthState(
      isLoggedIn: token != null && token.isNotEmpty,
      email: email,
    );
  }

  Future<void> sendOtp(String email) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, error: null) ??
          const AuthState(isLoading: true),
    );
    try {
      final auth = ref.read(authServiceProvider);
      await auth.sendOtp(email);
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: null),
      );
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: e is Exception ? e.toString() : 'Failed to send OTP',
        ),
      );
    }
  }

  Future<void> verifyOtp(String email, String code) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, error: null) ??
          const AuthState(isLoading: true),
    );
    try {
      final auth = ref.read(authServiceProvider);
      final res = await auth.verifyOtp(email, code);
      state = AsyncValue.data(AuthState(
        isLoggedIn: true,
        email: res.email,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          error: e is Exception ? e.toString() : 'Invalid or expired code',
        ),
      );
    }
  }

  Future<void> logout() async {
    await Storage.clearAuth();
    state = const AsyncValue.data(AuthState(isLoggedIn: false));
  }
}
