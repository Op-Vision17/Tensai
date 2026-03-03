import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';

part 'history_provider.g.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService(ref.watch(apiServiceProvider).dio);
});

/// State for history list with pagination.
class HistoryState {
  const HistoryState({required this.items, required this.hasMore});
  final List<HistoryItem> items;
  final bool hasMore;
}

@Riverpod(keepAlive: true)
class HistoryNotifier extends _$HistoryNotifier {
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 5;

  @override
  Future<HistoryState> build() async {
    await fetch(refresh: true);
    return state.value ?? const HistoryState(items: [], hasMore: false);
  }

  Future<void> fetch({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _offset = 0;
      _hasMore = true;
    }
    _isLoading = true;
    final isInitialOrRefresh = refresh || (state.value?.items.isEmpty ?? true);
    if (isInitialOrRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final service = ref.read(historyServiceProvider);
      final items = await service.getHistory(
        limit: _pageSize,
        offset: _offset,
      );
      _offset += items.length;
      if (items.length < _pageSize) _hasMore = false;
      final nextList = refresh ? items : [...state.value!.items, ...items];
      state = AsyncValue.data(HistoryState(items: nextList, hasMore: _hasMore));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> delete(String id) async {
    final service = ref.read(historyServiceProvider);
    await service.deleteHistory(id);
    final next = (state.value!.items).where((e) => e.id != id).toList();
    state = AsyncValue.data(HistoryState(items: next, hasMore: state.value!.hasMore));
  }
}
