import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

/// Ingest API: /ingest/text, /ingest/upload.
class IngestService {
  IngestService(this._dio);

  final Dio _dio;

  Future<int> ingestText(String text) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/ingest/text',
      data: {'text': text},
    );
    return res.data!['ingested'] as int;
  }

  Future<int> ingestUpload(PlatformFile file) async {
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
    final formData = FormData.fromMap({'file': multipart});
    final res = await _dio.post<Map<String, dynamic>>(
      '/ingest/upload',
      data: formData,
    );
    return res.data!['ingested'] as int;
  }
}
