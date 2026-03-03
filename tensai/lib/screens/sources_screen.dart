import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/input_styles.dart';
import '../models/source_item.dart';
import '../providers/ingest_provider.dart';
import '../providers/sources_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/gradient_button.dart';

final _textLoadingProvider = StateProvider<bool>((ref) => false);
final _uploadLoadingProvider = StateProvider<bool>((ref) => false);

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  final _pasteTitleController = TextEditingController();
  final _pasteTextController = TextEditingController();
  final _uploadTitleController = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _pasteTitleController.dispose();
    _pasteTextController.dispose();
    _uploadTitleController.dispose();
    super.dispose();
  }

  Future<void> _refreshSources() async {
    await ref.read(sourcesNotifierProvider.notifier).fetch();
  }

  Future<void> _confirmDeleteSource(BuildContext context, SourceItem source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete source?', style: GoogleFonts.spaceGrotesk()),
        content: Text(
          'This will remove all vectors from your study materials. This cannot be undone.',
          style: GoogleFonts.spaceGrotesk(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorBorder),
            child: Text('Delete', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Material(
          color: Colors.transparent,
          child: CircularProgressIndicator(
            color: AppColors.focusBorder,
            strokeWidth: 2,
          ),
        ),
      ),
    );
    try {
      await ref.read(sourcesNotifierProvider.notifier).delete(source.id);
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(context, 'Source deleted');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showError(
          context,
          e is DioException ? ApiService.handleError(e) : e.toString(),
        );
      }
    }
  }

  Future<void> _ingestText() async {
    final text = _pasteTextController.text.trim();
    if (text.isEmpty) return;
    ref.read(_textLoadingProvider.notifier).state = true;
    try {
      await ref.read(ingestServiceProvider).ingestText(
            text,
            title: _pasteTitleController.text.trim().isEmpty ? null : _pasteTitleController.text.trim(),
          );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Ingested successfully');
        _pasteTitleController.clear();
        _pasteTextController.clear();
        await _refreshSources();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          e is DioException ? ApiService.handleError(e) : e.toString(),
        );
      }
    } finally {
      if (mounted) ref.read(_textLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  Future<void> _ingestUpload() async {
    final file = _pickedFile;
    if (file == null) return;
    ref.read(_uploadLoadingProvider.notifier).state = true;
    try {
      await ref.read(ingestServiceProvider).ingestUpload(
            file,
            title: _uploadTitleController.text.trim().isEmpty ? null : _uploadTitleController.text.trim(),
          );
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Ingested successfully');
        _uploadTitleController.clear();
        setState(() => _pickedFile = null);
        await _refreshSources();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          e is DioException ? ApiService.handleError(e) : e.toString(),
        );
      }
    } finally {
      if (mounted) ref.read(_uploadLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(sourcesNotifierProvider);
    final textLoading = ref.watch(_textLoadingProvider);
    final uploadLoading = ref.watch(_uploadLoadingProvider);

    return RefreshIndicator(
      onRefresh: _refreshSources,
      color: AppColors.focusBorder,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Section 1: Your Sources ───
            AppCard(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_rounded, size: 22, color: AppColors.subtitle),
                      const SizedBox(width: 10),
                      Text(
                        'Your Sources',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF888888),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      sourcesAsync.when(
                        data: (list) => _CountBadge(count: list.length),
                        loading: () => _CountBadge(count: 0),
                        error: (_, __) => _CountBadge(count: 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  sourcesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: AppColors.focusBorder),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Failed to load sources',
                          style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 14),
                        ),
                      ),
                    ),
                    data: (sources) {
                      if (sources.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 40, color: AppColors.subtitle),
                                const SizedBox(height: 12),
                                Text(
                                  'No sources yet',
                                  style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: sources
                            .map(
                              (s) => _SourceTile(
                                source: s,
                                onDelete: () => _confirmDeleteSource(context, s),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            // ─── Section 2: Paste Text ───
            AppCard(
              title: 'Paste Text',
              titleIcon: Icons.text_fields_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _pasteTitleController,
                    decoration: InputStyles.standard(
                      labelText: 'Title',
                      hintText: 'Source title e.g. Chapter 1 Notes',
                    ).copyWith(
                      prefixIcon: Icon(Icons.label_outline_rounded, size: 22, color: AppColors.subtitle),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pasteTextController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputStyles.standard(
                      hintText: 'Paste your study notes here...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    onPressed: textLoading ? null : _ingestText,
                    label: 'Ingest Text',
                    isLoading: textLoading,
                  ),
                ],
              ),
            ),
            // ─── Section 3: Upload File ───
            AppCard(
              title: 'Upload File',
              titleIcon: Icons.upload_file_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _uploadTitleController,
                    decoration: InputStyles.standard(
                      labelText: 'Title',
                      hintText: 'Source title e.g. Physics Textbook',
                    ).copyWith(
                      prefixIcon: Icon(Icons.label_outline_rounded, size: 22, color: AppColors.subtitle),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickedFile == null ? _pickFile : null,
                    child: _pickedFile == null
                        ? SizedBox(
                            height: 140,
                            child: _DashedBorderContainer(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_rounded, size: 32, color: AppColors.focusBorder),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to choose file',
                                      style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PDF · DOCX · TXT',
                                      style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: InputStyles.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, size: 22, color: AppColors.subtitle),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _pickedFile!.name,
                                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: AppColors.subtitle,
                                  onPressed: () => setState(() => _pickedFile = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    onPressed: (uploadLoading || _pickedFile == null) ? null : _ingestUpload,
                    label: 'Upload and Ingest',
                    isLoading: uploadLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderContainer extends StatelessWidget {
  const _DashedBorderContainer({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              if (w.isFinite && h.isFinite)
                CustomPaint(
                  size: Size(w, h),
                  painter: _DashedBorderPainter(
                    color: AppColors.border,
                    strokeWidth: 1.5,
                    borderRadius: 12,
                  ),
                ),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.strokeWidth, required this.borderRadius});

  final Color color;
  final double strokeWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashGap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.subtitle,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source, required this.onDelete});

  final SourceItem source;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff0a0f1e),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(source.icon, size: 20, color: AppColors.focusBorder),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  source.formattedDate,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.errorBorder,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
