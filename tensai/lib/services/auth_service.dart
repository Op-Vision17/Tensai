import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/storage.dart';
import '../models/auth_response.dart';

/// Auth API: send-otp, verify-otp. Saves tokens to SecureStorage on verify.
class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  Future<void> sendOtp(String email) async {
    await _dio.post('/auth/send-otp', data: {'email': email});
  }

  Future<AuthResponse> verifyOtp(String email, String code) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'email': email, 'code': code},
    );
    final auth = AuthResponse.fromJson(res.data!);
    await Storage.setSecure(Constants.keyAccessToken, auth.accessToken);
    await Storage.setSecure(Constants.keyRefreshToken, auth.refreshToken);
    await Storage.setSecure(Constants.keyAuthEmail, auth.email);
    return auth;
  }
}
