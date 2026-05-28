/// Represents a learning module stored in Supabase.
/// Actual files (PDF / PPT) are hosted on Google Drive.
class LearningModule {
  final String? id;
  final String title;
  final String? description;
  final String subject;
  final String term; // 'prelim', 'midterm', 'prefinal', 'final'
  final String fileUrl;
  final DateTime? createdAt;

  const LearningModule({
    this.id,
    required this.title,
    this.description,
    required this.subject,
    required this.term,
    required this.fileUrl,
    this.createdAt,
  });

  // ── Serialization ──────────────────────────────────────────────

  factory LearningModule.fromSupabase(Map<String, dynamic> m) => LearningModule(
        id: m['id'] as String?,
        title: m['title'] as String? ?? '',
        description: m['description'] as String?,
        subject: m['subject'] as String? ?? '',
        term: m['term'] as String? ?? 'prelim',
        fileUrl: m['file_url'] as String? ?? '',
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toSupabase() => {
        'title': title,
        'description': description,
        'subject': subject,
        'term': term,
        'file_url': fileUrl,
      };

  // ── Helpers ────────────────────────────────────────────────────

  String get termLabel {
    switch (term) {
      case 'prelim':
        return 'Prelim';
      case 'midterm':
        return 'Midterm';
      case 'prefinal':
        return 'Pre-Final';
      case 'final':
        return 'Final';
      default:
        return term;
    }
  }

  LearningModule copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? term,
    String? fileUrl,
    DateTime? createdAt,
  }) =>
      LearningModule(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        subject: subject ?? this.subject,
        term: term ?? this.term,
        fileUrl: fileUrl ?? this.fileUrl,
        createdAt: createdAt ?? this.createdAt,
      );
}
