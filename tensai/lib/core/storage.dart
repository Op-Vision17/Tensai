import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// Secure and plain storage helpers.
class Storage {
  Storage._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<String?> getSecure(String key) => _secure.read(key: key);
  static Future<void> setSecure(String key, String value) => _secure.write(key: key, value: value);
  static Future<void> deleteSecure(String key) => _secure.delete(key: key);

  static Future<String?> getPref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setPref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Clear auth keys from secure storage (logout).
  static Future<void> clearAuth() async {
    await _secure.delete(key: Constants.keyAccessToken);
    await _secure.delete(key: Constants.keyRefreshToken);
    await _secure.delete(key: Constants.keyAuthEmail);
  }
}
