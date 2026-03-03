/// History list item from API.
class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.keyPoints,
    required this.confidence,
    required this.sources,
    this.createdAt,
  });

  final String id;
  final String question;
  final String answer;
  final List<String> keyPoints;
  final double confidence;
  final List<String> sources;
  final String? createdAt;

  /// Formatted date for display (e.g. "Mar 3, 2025").
  String get formattedDate {
    if (createdAt == null || createdAt!.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt!);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return createdAt!;
    }
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      keyPoints: (json['key_points'] as List<dynamic>?)?.cast<String>() ?? [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      sources: (json['sources'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'key_points': keyPoints,
      'confidence': confidence,
      'sources': sources,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
