/// Auth API response (verify-otp).
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.isNewUser,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
  final bool isNewUser;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      email: json['email'] as String,
      isNewUser: json['is_new_user'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'email': email,
      'is_new_user': isNewUser,
    };
  }
}
