/// Holds the instructor-configured grading weights for a subject.
///
/// Computation formula per component:
///   contribution = (raw ÷ max) × 100 × (weight ÷ 100)
///
/// Term grade = sum of all component contributions.
///
/// Cross-term final grade weighting:
///   Semester  (4 terms): Prelim×0.2 + Midterm×0.2 + Semi-Finals×0.2 + Finals×0.4
///   Trimester (3 terms): Prelim×0.25 + Midterm×0.25 + Finals×0.5
class GradingConfig {
  final String? id;
  final String subjectId;

  /// 'semester'  → Prelim, Midterm, Semi-Finals, Finals  (4 terms)
  /// 'trimester' → Prelim, Midterm, Finals               (3 terms)
  final String termType;

  final double examPct;
  final double quizPct;
  final double attendancePct;

  const GradingConfig({
    this.id,
    required this.subjectId,
    this.termType = 'semester',
    this.examPct = 60,
    this.quizPct = 30,
    this.attendancePct = 10,
  });

  // ── Helpers ──────────────────────────────────────────────────────

  List<String> get terms => termType == 'trimester'
      ? ['prelim', 'midterm', 'finals']
      : ['prelim', 'midterm', 'semi_finals', 'finals'];

  static String termLabel(String term) {
    switch (term) {
      case 'prelim':      return 'Prelim';
      case 'midterm':     return 'Midterm';
      case 'semi_finals': return 'Semi-Finals';
      case 'finals':      return 'Finals';
      default:            return term;
    }
  }

  bool get isValid =>
      (examPct + quizPct + attendancePct - 100.0).abs() < 0.01;

  // ── Core Grade Computation ────────────────────────────────────────

  /// Computes the term grade from raw scores and the instructor's weights.
  /// Returns null if any max value is zero (division guard).
  double? computeTermGrade({
    required double examRaw,
    required double examMax,
    required double quizRaw,
    required double quizMax,
    required double attendRaw,
    required double attendMax,
  }) {
    if (examMax <= 0 || quizMax <= 0 || attendMax <= 0) return null;
    double contrib(double raw, double max, double pct) =>
        (raw / max) * 100 * (pct / 100);
    return contrib(examRaw, examMax, examPct) +
        contrib(quizRaw, quizMax, quizPct) +
        contrib(attendRaw, attendMax, attendancePct);
  }

  // ── Cross-term final grade weighting ─────────────────────────────
  //
  // Semester  (4 terms): Prelim×0.2 + Midterm×0.2 + Semi-Finals×0.2 + Finals×0.4 = 1.0
  // Trimester (3 terms): Prelim×0.25 + Midterm×0.25 + Finals×0.5 = 1.0
  //   (ratio 1:1:2 kept identical to semester)

  /// Returns the multiplier to apply to each term's grade toward the final.
  Map<String, double> get termWeights {
    if (termType == 'trimester') {
      return {
        'prelim':  0.25,
        'midterm': 0.25,
        'finals':  0.50,
      };
    }
    // semester
    return {
      'prelim':      0.20,
      'midterm':     0.20,
      'semi_finals': 0.20,
      'finals':      0.40,
    };
  }

  /// Computes the overall final grade from a map of {term → termGrade}.
  ///
  /// Formula (semester example):
  ///   (Prelim×0.2) + (Midterm×0.2) + (Semi-Finals×0.2) + (Finals×0.4)
  ///
  /// Only includes terms that have a recorded grade.
  /// Returns null if no terms have grades yet.
  double? computeFinalGrade(Map<String, double?> termGrades) {
    final weights = termWeights;
    double total = 0;
    double weightSum = 0;
    for (final term in terms) {
      final g = termGrades[term];
      final w = weights[term] ?? 0;
      if (g != null && w > 0) {
        total     += g * w;
        weightSum += w;
      }
    }
    if (weightSum <= 0) return null;
    // When ALL terms are complete, weightSum == 1.0 so this is just `total`.
    // For partial records we normalise proportionally.
    return total / weightSum;
  }

  // ── Supabase Serialization ────────────────────────────────────────

  Map<String, dynamic> toSupabase() => {
        'subject_id': subjectId,
        'term_type': termType,
        'exam_pct': examPct,
        'quiz_pct': quizPct,
        'attendance_pct': attendancePct,
      };

  factory GradingConfig.fromSupabase(Map<String, dynamic> map) =>
      GradingConfig(
        id: map['id'],
        subjectId: map['subject_id'] ?? '',
        termType: map['term_type'] ?? 'semester',
        examPct: (map['exam_pct'] as num?)?.toDouble() ?? 60,
        quizPct: (map['quiz_pct'] as num?)?.toDouble() ?? 30,
        attendancePct: (map['attendance_pct'] as num?)?.toDouble() ?? 10,
      );

  GradingConfig copyWith({
    String? id,
    String? subjectId,
    String? termType,
    double? examPct,
    double? quizPct,
    double? attendancePct,
  }) =>
      GradingConfig(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        termType: termType ?? this.termType,
        examPct: examPct ?? this.examPct,
        quizPct: quizPct ?? this.quizPct,
        attendancePct: attendancePct ?? this.attendancePct,
      );
}

// ── Grading Remarks Helper ────────────────────────────────────────────────────

class GradeRemarks {
  GradeRemarks._();

  static String remarks(double? avg) {
    if (avg == null) return '—';
    if (avg >= 98) return 'Excellent';
    if (avg >= 94) return 'Excellent';
    if (avg >= 90) return 'Very Good';
    if (avg >= 86) return 'Very Good';
    if (avg >= 82) return 'Good';
    if (avg >= 78) return 'Good';
    if (avg >= 74) return 'Satisfactory';
    if (avg >= 70) return 'Satisfactory';
    if (avg >= 65) return 'Passing';
    return 'Failed';
  }

  static String equivalent(double? avg) {
    if (avg == null) return '—';
    if (avg >= 98) return '1.00';
    if (avg >= 94) return '1.25';
    if (avg >= 90) return '1.50';
    if (avg >= 86) return '1.75';
    if (avg >= 82) return '2.00';
    if (avg >= 78) return '2.25';
    if (avg >= 74) return '2.50';
    if (avg >= 70) return '2.75';
    if (avg >= 65) return '3.00';
    return '5.00';
  }

  static bool isPassed(double? avg) => avg != null && avg >= 75.0;
}
