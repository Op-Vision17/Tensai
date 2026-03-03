import 'package:dio/dio.dart';

import '../models/history_item.dart';

/// History API: list, delete.
class HistoryService {
  HistoryService(this._dio);

  final Dio _dio;

  Future<List<HistoryItem>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/history/',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return (res.data ?? [])
        .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteHistory(String id) async {
    await _dio.delete('/history/$id');
  }
}
