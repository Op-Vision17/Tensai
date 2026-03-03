import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../models/source_item.dart';

/// Ingest API: /ingest/text, /ingest/upload, /ingest/sources.
class IngestService {
  IngestService(this._dio);

  final Dio _dio;

  Future<List<SourceItem>> getSources() async {
    final res = await _dio.get<List<dynamic>>('/ingest/sources');
    final list = res.data;
    if (list == null) return [];
    return list
        .map((e) => SourceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteSource(String id) async {
    await _dio.delete('/ingest/sources/$id');
  }

  Future<int> ingestText(String text, {String? title}) async {
    final data = <String, dynamic>{'text': text};
    if (title != null && title.trim().isNotEmpty) data['title'] = title.trim();
    final res = await _dio.post<Map<String, dynamic>>(
      '/ingest/text',
      data: data,
    );
    return res.data!['ingested'] as int;
  }

  Future<int> ingestUpload(PlatformFile file, {String? title}) async {
    final MultipartFile multipart;
    if (file.path != null && file.path!.isNotEmpty) {
      multipart = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    } else if (file.bytes != null && file.bytes!.isNotEmpty) {
      multipart = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else {
      throw ArgumentError('PlatformFile has no path or bytes');
    }
    final formData = FormData.fromMap({
      'file': multipart,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/ingest/upload',
      data: formData,
    );
    return res.data!['ingested'] as int;
  }
}
