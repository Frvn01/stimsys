/// Individual score item within a student's term grade.
///
/// Supports multiple quizzes, activities, and exams per term.
/// The parent [StudentGrade] record's `quiz_raw/quiz_max` and
/// `exam_raw/exam_max` are computed as sums of these items.
class StudentGradeItem {
  final String? id;
  final String gradeId;

  /// 'quiz', 'activity', or 'exam'
  final String category;

  /// Human-readable label, e.g. "Quiz 1", "Activity 3", "Prelim Exam"
  final String label;

  final double score;
  final double maxScore;

  /// How this item was created:
  /// - 'manual'         — instructor typed it in
  /// - 'assessment_qr'  — auto-imported from student QR scan
  /// - 'auto'           — auto-computed (e.g. attendance)
  final String source;

  /// Link to the assessment that generated this score (nullable).
  final String? assessmentId;

  final DateTime? createdAt;

  const StudentGradeItem({
    this.id,
    required this.gradeId,
    required this.category,
    required this.label,
    this.score = 0,
    this.maxScore = 0,
    this.source = 'manual',
    this.assessmentId,
    this.createdAt,
  });

  bool get isQuiz => category == 'quiz';
  bool get isActivity => category == 'activity';
  bool get isExam => category == 'exam';
  bool get isBonus => category == 'bonus';
  bool get isAutoImported => source == 'assessment_qr' || source == 'auto';

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  Map<String, dynamic> toSupabase() => {
        'grade_id': gradeId,
        'category': category,
        'label': label,
        'score': score,
        'max_score': maxScore,
        'source': source,
        'assessment_id': assessmentId,
      };

  factory StudentGradeItem.fromSupabase(Map<String, dynamic> map) =>
      StudentGradeItem(
        id: map['id'],
        gradeId: map['grade_id'] ?? '',
        category: map['category'] ?? 'quiz',
        label: map['label'] ?? '',
        score: (map['score'] as num?)?.toDouble() ?? 0,
        maxScore: (map['max_score'] as num?)?.toDouble() ?? 0,
        source: map['source'] ?? 'manual',
        assessmentId: map['assessment_id'],
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'])
            : null,
      );

  StudentGradeItem copyWith({
    String? id,
    String? gradeId,
    String? category,
    String? label,
    double? score,
    double? maxScore,
    String? source,
    String? assessmentId,
  }) =>
      StudentGradeItem(
        id: id ?? this.id,
        gradeId: gradeId ?? this.gradeId,
        category: category ?? this.category,
        label: label ?? this.label,
        score: score ?? this.score,
        maxScore: maxScore ?? this.maxScore,
        source: source ?? this.source,
        assessmentId: assessmentId ?? this.assessmentId,
        createdAt: createdAt,
      );

  /// Group a list of items by category.
  static Map<String, List<StudentGradeItem>> groupByCategory(
      List<StudentGradeItem> items) {
    final map = <String, List<StudentGradeItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// Sum scores for a given category from a list of items.
  static double sumScores(List<StudentGradeItem> items, String category) =>
      items
          .where((i) => i.category == category)
          .fold(0.0, (sum, i) => sum + i.score);

  /// Sum max scores for a given category from a list of items.
  static double sumMaxScores(List<StudentGradeItem> items, String category) =>
      items
          .where((i) => i.category == category)
          .fold(0.0, (sum, i) => sum + i.maxScore);
}
