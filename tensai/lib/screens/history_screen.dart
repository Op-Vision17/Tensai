import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../providers/history_provider.dart';
import '../widgets/history_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(historyNotifierProvider.notifier).fetch(refresh: true),
      color: AppColors.primary,
      child: historyAsync.when(
        data: (historyState) {
          final items = historyState.items;
          if (items.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Text(
                    'No history yet.',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 16),
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: items.length + (historyState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          ref.read(historyNotifierProvider.notifier).fetch(refresh: false),
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      label: Text(
                        'Load more',
                        style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 16),
                      ),
                    ),
                  ),
                );
              }
              final item = items[index];
              return HistoryCard(
                item: item,
                onDelete: () => ref.read(historyNotifierProvider.notifier).delete(item.id),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.spaceGrotesk(color: AppColors.errorBorder),
          ),
        ),
      ),
    );
  }
}
