import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/input_styles.dart';
import '../providers/ask_provider.dart';
import '../widgets/answer_card.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_button.dart';

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.length < 5) return;
    await ref.read(askNotifierProvider.notifier).ask(question);
  }

  @override
  Widget build(BuildContext context) {
    final askAsync = ref.watch(askNotifierProvider);
    final isLoading = askAsync.isLoading;
    final response = askAsync.valueOrNull;
    final questionLength = _questionController.text.trim().length;
    final canSubmit = questionLength >= 5 && !isLoading;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _questionController,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 1000,
                    onChanged: (_) => setState(() {}),
                    decoration: InputStyles.standard(
                      labelText: 'Your question',
                      hintText: 'Ask about your study materials...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: canSubmit ? _ask : null,
                    label: 'Ask Tensai',
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
            if (response != null) ...[
              AppCard(
                child: AnswerCard(
                  answer: response.answer,
                  keyPoints: response.keyPoints,
                  confidence: response.confidence,
                  sources: response.sources,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
