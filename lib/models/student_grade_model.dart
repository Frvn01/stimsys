/// Stores a student's raw scores for a single grading term.
///
/// Computed grade is saved after calculation so it persists even if
/// the config weights change later.
class StudentGrade {
  final String? id;
  final String enrollmentId;

  /// 'prelim' | 'midterm' | 'semi_finals' | 'finals'
  final String term;

  // Raw scores (score obtained)
  final double? examRaw;
  final double? examMax;
  final double? quizRaw;
  final double? quizMax;
  final double? attendanceRaw;
  final double? attendanceMax;

  /// Auto-computed and saved at encoding time.
  final double? computedGrade;

  final DateTime? encodedAt;
  final DateTime? updatedAt;

  // Joined student info (read-only, from DB join)
  final String? studentId;
  final String? lastName;
  final String? firstName;
  final String? usn;

  const StudentGrade({
    this.id,
    required this.enrollmentId,
    required this.term,
    this.examRaw,
    this.examMax,
    this.quizRaw,
    this.quizMax,
    this.attendanceRaw,
    this.attendanceMax,
    this.computedGrade,
    this.encodedAt,
    this.updatedAt,
    this.studentId,
    this.lastName,
    this.firstName,
    this.usn,
  });

  String get studentFullName {
    final ln = lastName ?? '';
    final fn = firstName ?? '';
    if (ln.isEmpty && fn.isEmpty) return '—';
    return '$ln, $fn';
  }

  bool get isComplete =>
      examRaw != null &&
      examMax != null &&
      quizRaw != null &&
      quizMax != null &&
      attendanceRaw != null &&
      attendanceMax != null;

  Map<String, dynamic> toSupabase() => {
        'enrollment_id': enrollmentId,
        'term': term,
        'exam_raw': examRaw,
        'exam_max': examMax,
        'quiz_raw': quizRaw,
        'quiz_max': quizMax,
        'attendance_raw': attendanceRaw,
        'attendance_max': attendanceMax,
        'computed_grade': computedGrade,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory StudentGrade.fromSupabase(Map<String, dynamic> map) {
    // Joined student data via enrollments → students
    Map<String, dynamic>? studentMap;
    final enrollment = map['enrollments'];
    if (enrollment is Map<String, dynamic>) {
      studentMap = enrollment['students'] as Map<String, dynamic>?;
    }

    return StudentGrade(
      id: map['id'],
      enrollmentId: map['enrollment_id'] ?? '',
      term: map['term'] ?? 'prelim',
      examRaw: (map['exam_raw'] as num?)?.toDouble(),
      examMax: (map['exam_max'] as num?)?.toDouble(),
      quizRaw: (map['quiz_raw'] as num?)?.toDouble(),
      quizMax: (map['quiz_max'] as num?)?.toDouble(),
      attendanceRaw: (map['attendance_raw'] as num?)?.toDouble(),
      attendanceMax: (map['attendance_max'] as num?)?.toDouble(),
      computedGrade: (map['computed_grade'] as num?)?.toDouble(),
      encodedAt: map['encoded_at'] != null
          ? DateTime.tryParse(map['encoded_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
      studentId: studentMap?['id'],
      lastName: studentMap?['last_name'],
      firstName: studentMap?['first_name'],
      usn: studentMap?['usn'],
    );
  }

  StudentGrade copyWith({
    String? id,
    String? enrollmentId,
    String? term,
    double? examRaw,
    double? examMax,
    double? quizRaw,
    double? quizMax,
    double? attendanceRaw,
    double? attendanceMax,
    double? computedGrade,
  }) =>
      StudentGrade(
        id: id ?? this.id,
        enrollmentId: enrollmentId ?? this.enrollmentId,
        term: term ?? this.term,
        examRaw: examRaw ?? this.examRaw,
        examMax: examMax ?? this.examMax,
        quizRaw: quizRaw ?? this.quizRaw,
        quizMax: quizMax ?? this.quizMax,
        attendanceRaw: attendanceRaw ?? this.attendanceRaw,
        attendanceMax: attendanceMax ?? this.attendanceMax,
        computedGrade: computedGrade ?? this.computedGrade,
        encodedAt: encodedAt,
        updatedAt: updatedAt,
        studentId: studentId,
        lastName: lastName,
        firstName: firstName,
        usn: usn,
      );
}

/// Aggregated row used in the Final Grade Summary view.
class StudentFinalSummary {
  final String enrollmentId;
  final String studentId;
  final String lastName;
  final String firstName;
  final String usn;
  final Map<String, double?> termGrades; // term → computedGrade

  const StudentFinalSummary({
    required this.enrollmentId,
    required this.studentId,
    required this.lastName,
    required this.firstName,
    required this.usn,
    required this.termGrades,
  });

  String get fullName => '$lastName, $firstName';

  /// Simple unweighted average — kept as a fallback.
  double? simpleAverage(List<String> terms) {
    final values =
        terms.map((t) => termGrades[t]).where((v) => v != null).cast<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
