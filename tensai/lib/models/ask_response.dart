/// /ask API response.
class AskResponse {
  const AskResponse({
    required this.question,
    required this.answer,
    required this.keyPoints,
    required this.confidence,
    required this.sources,
  });

  final String question;
  final String answer;
  final List<String> keyPoints;
  final double confidence;
  final List<String> sources;

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    return AskResponse(
      question: json['question'] as String,
      answer: json['answer'] as String,
      keyPoints: (json['key_points'] as List<dynamic>?)?.cast<String>() ?? [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      sources: (json['sources'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'key_points': keyPoints,
      'confidence': confidence,
      'sources': sources,
    };
  }
}
