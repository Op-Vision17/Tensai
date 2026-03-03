import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../services/ingest_service.dart';

final ingestServiceProvider = Provider<IngestService>((ref) {
  return IngestService(ref.watch(apiServiceProvider).dio);
});
