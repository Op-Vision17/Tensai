import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ingest_provider.dart';
import '../models/source_item.dart';

part 'sources_provider.g.dart';

@Riverpod(keepAlive: true)
class SourcesNotifier extends _$SourcesNotifier {
  @override
  Future<List<SourceItem>> build() async {
    return fetch();
  }

  Future<List<SourceItem>> fetch() async {
    final service = ref.read(ingestServiceProvider);
    final list = await service.getSources();
    state = AsyncValue.data(list);
    return list;
  }

  Future<void> delete(String id) async {
    final service = ref.read(ingestServiceProvider);
    await service.deleteSource(id);
    state = AsyncValue.data(
      (state.value ?? []).where((s) => s.id != id).toList(),
    );
  }
}
