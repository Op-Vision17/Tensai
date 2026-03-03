import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/storage.dart';

/// Base API client (Dio) with auth interceptor and 401 refresh retry.
class ApiService {
  ApiService() : _dio = Dio() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final baseUrl = await Storage.getPref(Constants.keyBaseUrl) ??
        Constants.defaultBaseUrl;
    options.baseUrl = baseUrl;

    final token = await Storage.getSecure(Constants.keyAccessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken =
        await Storage.getSecure(Constants.keyRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    try {
      final baseUrl = await Storage.getPref(Constants.keyBaseUrl) ??
          Constants.defaultBaseUrl;
      final res = await Dio().post<Map<String, dynamic>>(
        '$baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newToken = res.data?['access_token'] as String?;
      if (newToken != null) {
        await Storage.setSecure(Constants.keyAccessToken, newToken);
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final retry = await _dio.fetch(opts);
        return handler.resolve(
          Response(requestOptions: opts, data: retry.data),
        );
      }
    } catch (_) {}

    handler.next(err);
  }

  /// Convert DioException to user-facing message.
  static String handleError(DioException e) {
    final res = e.response;
    if (res != null) {
      final data = res.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) return detail.first.toString();
      }
      if (res.statusCode == 401) return 'Session expired. Please sign in again.';
      if (res.statusCode == 404) return 'Not found.';
      if (res.statusCode != null) return 'Request failed (${res.statusCode})';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Check your network.';
      case DioExceptionType.connectionError:
        return 'No connection. Check your network.';
      case DioExceptionType.badResponse:
        return 'Server error. Try again later.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
