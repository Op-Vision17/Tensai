import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/input_styles.dart';
import '../providers/ingest_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/gradient_button.dart';

final _sourcesLoadingProvider = StateProvider<String?>((ref) => null); // 'text' | 'upload' | null

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  final _textController = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _ingestText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref.read(_sourcesLoadingProvider.notifier).state = 'text';
    try {
      final n = await ref.read(ingestServiceProvider).ingestText(text);
      if (mounted) AppSnackbar.showSuccess(context, 'Ingested $n chunks');
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          e is DioException ? ApiService.handleError(e) : e.toString(),
        );
      }
    } finally {
      if (mounted) ref.read(_sourcesLoadingProvider.notifier).state = null;
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
    ref.read(_sourcesLoadingProvider.notifier).state = 'upload';
    try {
      final n = await ref.read(ingestServiceProvider).ingestUpload(file);
      if (mounted) AppSnackbar.showSuccess(context, 'Ingested $n chunks');
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          e is DioException ? ApiService.handleError(e) : e.toString(),
        );
      }
    } finally {
      if (mounted) ref.read(_sourcesLoadingProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadingState = ref.watch(_sourcesLoadingProvider);
    final textLoading = loadingState == 'text';
    final uploadLoading = loadingState == 'upload';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            title: 'Paste Text',
            titleIcon: Icons.text_fields_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _textController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputStyles.standard(
                    hintText: 'Paste your study material here...',
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
          AppCard(
            title: 'Upload Document',
            titleIcon: Icons.upload_file_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PDF · DOCX · TXT',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.subtitle,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: uploadLoading ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose file'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.focusBorder,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                if (_pickedFile != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      _pickedFile!.name,
                      style: GoogleFonts.spaceGrotesk(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: InputStyles.fillColor,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    onPressed: uploadLoading ? null : _ingestUpload,
                    label: 'Upload and Ingest',
                    isLoading: uploadLoading,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
