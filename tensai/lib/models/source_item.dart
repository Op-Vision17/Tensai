import 'package:flutter/material.dart';

/// Source list item from GET /ingest/sources.
class SourceItem {
  const SourceItem({
    required this.id,
    required this.title,
    required this.sourceType,
    this.filename,
    required this.chunkCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String sourceType;
  final String? filename;
  final int chunkCount;
  final DateTime createdAt;

  /// Display name: title if set, else filename, else "Untitled".
  String get displayName {
    if (title.trim().isNotEmpty) return title.trim();
    if (filename != null && filename!.trim().isNotEmpty) return filename!.trim();
    return 'Untitled';
  }

  /// Icon by source_type: upload → PDF, text → notes.
  IconData get icon {
    switch (sourceType) {
      case 'upload':
        return Icons.picture_as_pdf_rounded;
      case 'text':
      default:
        return Icons.notes_rounded;
    }
  }

  /// Formatted date for display (e.g. "Mar 3, 2025").
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  factory SourceItem.fromJson(Map<String, dynamic> json) {
    DateTime parsed = DateTime.now();
    final createdAtRaw = json['created_at'];
    if (createdAtRaw != null) {
      if (createdAtRaw is String) {
        parsed = DateTime.parse(createdAtRaw);
      } else if (createdAtRaw is DateTime) {
        parsed = createdAtRaw;
      }
    }
    return SourceItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? 'text',
      filename: json['filename'] as String?,
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
      createdAt: parsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source_type': sourceType,
      if (filename != null) 'filename': filename,
      'chunk_count': chunkCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
