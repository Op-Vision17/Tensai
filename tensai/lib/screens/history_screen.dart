import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/history_provider.dart';
import '../widgets/history_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyNotifierProvider.notifier).fetch();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(historyNotifierProvider.notifier).fetch(refresh: false);
    }
  }

  Future<void> _refresh() async {
    await ref.read(historyNotifierProvider.notifier).fetch(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyNotifierProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(child: Text('No history yet.')),
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return HistoryCard(
                item: item,
                onDelete: () => ref.read(historyNotifierProvider.notifier).delete(item.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
