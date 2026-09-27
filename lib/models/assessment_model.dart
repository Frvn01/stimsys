/// Supabase-backed assessment models for instructor-created quizzes/exams.

// ═══════════════════════════════════════════════════
// ASSESSMENT CONFIG
// ═══════════════════════════════════════════════════

class AssessmentConfig {
  final String? id;
  final String subjectId;
  final String term;        // prelim, midterm, semi_finals, finals
  final String type;        // quiz, exam
  final String title;
  final int timeLimitSecs;
  final bool isPublished;
  final int setCount;       // 1 for quiz, 2 for exam (Set A/B)
  final String? sessionCode;
  final String? themeColor; // hex color for student UI
  final DateTime? publishedAt;
  final DateTime? availableUntil; // Expiration of submission period
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssessmentConfig({
    this.id,
    required this.subjectId,
    required this.term,
    required this.type,
    required this.title,
    this.timeLimitSecs = 1800,
    this.isPublished = false,
    this.setCount = 1,
    this.sessionCode,
    this.themeColor,
    this.publishedAt,
    this.availableUntil,
    this.createdAt,
    this.updatedAt,
  });

  bool get isExam => type == 'exam';
  bool get isQuiz => type == 'quiz';

  /// Check if the assessment is currently published and within its active submission window
  bool get isAvailable {
    if (!isPublished) return false;
    if (availableUntil != null && DateTime.now().isAfter(availableUntil!)) {
      return false; // Submission period expired
    }
    return true;
  }

  /// Check if the submission window has expired
  bool get isExpired {
    if (!isPublished) return false;
    if (availableUntil == null) return false;
    return DateTime.now().isAfter(availableUntil!);
  }

  /// Human-readable remaining submission window duration
  String get remainingAvailabilityFormatted {
    if (!isPublished) return 'Draft';
    if (availableUntil == null) return 'No time limit';
    final diff = availableUntil!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h left';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m left';
    } else {
      return '${diff.inSeconds}s left';
    }
  }

  Map<String, dynamic> toSupabase() => {
        'subject_id': subjectId,
        'term': term,
        'type': type,
        'title': title,
        'time_limit_secs': timeLimitSecs,
        'is_published': isPublished,
        'set_count': setCount,
        'session_code': sessionCode,
        'theme_color': themeColor,
        // Always send UTC so Supabase/PostgreSQL stores the correct epoch.
        // Dart's toIso8601String() on a local DateTime omits the timezone
        // offset, which causes Supabase to mis-interpret the value as UTC.
        'published_at': publishedAt?.toUtc().toIso8601String(),
        'available_until': availableUntil?.toUtc().toIso8601String(),
      };

  factory AssessmentConfig.fromSupabase(Map<String, dynamic> map) =>
      AssessmentConfig(
        id: map['id'],
        subjectId: map['subject_id'] ?? '',
        term: map['term'] ?? 'prelim',
        type: map['type'] ?? 'quiz',
        title: map['title'] ?? '',
        timeLimitSecs: map['time_limit_secs'] ?? 1800,
        isPublished: map['is_published'] ?? false,
        setCount: map['set_count'] ?? 1,
        sessionCode: map['session_code'],
        themeColor: map['theme_color'],
        // Convert UTC timestamps from Supabase back to device-local time so
        // all DateTime comparisons and display use the same timezone.
        publishedAt: map['published_at'] != null
            ? DateTime.tryParse(map['published_at'])?.toLocal()
            : null,
        availableUntil: map['available_until'] != null
            ? DateTime.tryParse(map['available_until'])?.toLocal()
            : null,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'])?.toLocal()
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.tryParse(map['updated_at'])?.toLocal()
            : null,
      );

  AssessmentConfig copyWith({
    String? id,
    String? subjectId,
    String? term,
    String? type,
    String? title,
    int? timeLimitSecs,
    bool? isPublished,
    int? setCount,
    String? sessionCode,
    String? themeColor,
    DateTime? publishedAt,
    DateTime? availableUntil,
    bool clearAvailableUntil = false,
  }) =>
      AssessmentConfig(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        term: term ?? this.term,
        type: type ?? this.type,
        title: title ?? this.title,
        timeLimitSecs: timeLimitSecs ?? this.timeLimitSecs,
        isPublished: isPublished ?? this.isPublished,
        setCount: setCount ?? this.setCount,
        sessionCode: sessionCode ?? this.sessionCode,
        themeColor: themeColor ?? this.themeColor,
        publishedAt: publishedAt ?? this.publishedAt,
        availableUntil: clearAvailableUntil ? null : (availableUntil ?? this.availableUntil),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static String termLabel(String term) {
    switch (term) {
      case 'prelim':
        return 'Prelim';
      case 'midterm':
        return 'Midterm';
      case 'semi_finals':
        return 'Pre-Finals';
      case 'finals':
        return 'Finals';
      default:
        return term;
    }
  }
}

// ═══════════════════════════════════════════════════
// ASSESSMENT QUESTION (with answer key)
// ═══════════════════════════════════════════════════

class AssessmentQuestion {
  final String? id;
  final String assessmentId;
  final int questionOrder;
  final String questionText;
  final String questionType; // multiple_choice, identification, enumeration
  final List<String>? choices;
  final String correctAnswer;
  final List<String>? enumerationAnswers;
  final double points;

  const AssessmentQuestion({
    this.id,
    required this.assessmentId,
    this.questionOrder = 0,
    required this.questionText,
    required this.questionType,
    this.choices,
    required this.correctAnswer,
    this.enumerationAnswers,
    this.points = 1,
  });

  bool get isTrueFalse {
    if (questionType == 'true_false') return true;
    final c = choices;
    if (c == null || c.length != 2) return false;
    return c.any((x) => x.trim().toLowerCase() == 'true') &&
        c.any((x) => x.trim().toLowerCase() == 'false');
  }

  bool get isMultipleChoice =>
      questionType == 'multiple_choice' && !isTrueFalse;
  bool get isIdentification => questionType == 'identification';
  bool get isEnumeration => questionType == 'enumeration';
  bool get isEssay => questionType == 'essay';

  /// Whether the blanks can be filled in any order (interchangeable).
  /// Encoded as a `[IC]` prefix in [correctAnswer]: `[IC]Apple | Banana`.
  bool get isInterchangeable =>
      isIdentification && correctAnswer.trimLeft().startsWith('[IC]');

  /// Returns the list of required blanks for an identification question,
  /// stripping the optional [IC] prefix.
  List<String> get identificationBlanks {
    if (!isIdentification) return const [];
    final raw = isInterchangeable
        ? correctAnswer.trimLeft().substring(4) // strip '[IC]'
        : correctAnswer;
    return raw
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Check a student's answer against the correct answer.
  bool checkAnswer(String studentAnswer) {
    final sa = studentAnswer.trim().toLowerCase();
    if (sa.isEmpty) return false;

    if (isEssay) return false; // Needs manual grading

    if (isTrueFalse) {
      return sa == correctAnswer.trim().toLowerCase();
    }

    if (isEnumeration && enumerationAnswers != null) {
      // For enumeration, check if the student's comma-separated answers
      // contain all correct answers (order-independent).
      final studentParts =
          sa.split(',').map((e) => e.trim().toLowerCase()).toSet();
      final correctParts = enumerationAnswers!
          .map((e) => e.trim().toLowerCase())
          .toSet();
      return correctParts.difference(studentParts).isEmpty;
    }

    if (isIdentification) {
      // Student answers are stored as '||'-separated values, one per blank.
      final blanks = identificationBlanks;
      if (blanks.isEmpty) return false;

      final studentBlanks = studentAnswer
          .split('||')
          .map((e) => e.trim().toLowerCase())
          .toList();

      if (studentBlanks.length != blanks.length) return false;

      if (isInterchangeable) {
        // Order doesn't matter — each student blank must match some correct blank
        // (one-to-one, no reuse).
        final remaining = blanks.map((b) => b.toLowerCase()).toList();
        for (final sb in studentBlanks) {
          final idx = remaining.indexOf(sb);
          if (idx == -1) return false;
          remaining.removeAt(idx);
        }
        return true;
      } else {
        // Strict order: blank i must match answer i.
        for (int i = 0; i < blanks.length; i++) {
          if (studentBlanks[i] != blanks[i].toLowerCase()) return false;
        }
        return true;
      }
    }

    return sa == correctAnswer.trim().toLowerCase();
  }

  /// Compute points earned for a given answer.
  double computePoints(String studentAnswer) {
    if (isEssay) return 0; // Default to 0 for auto-grading until manual grading is added
    if (checkAnswer(studentAnswer)) return points;

    // Partial credit for enumeration
    if (isEnumeration && enumerationAnswers != null) {
      final studentParts =
          studentAnswer.trim().toLowerCase().split(',').map((e) => e.trim()).toSet();
      final correctParts = enumerationAnswers!
          .map((e) => e.trim().toLowerCase())
          .toSet();
      if (correctParts.isEmpty) return 0;
      final matches = correctParts.intersection(studentParts).length;
      return (matches / correctParts.length) * points;
    }

    // Partial credit for identification (per-blank scoring)
    if (isIdentification) {
      final blanks = identificationBlanks;
      if (blanks.isEmpty) return 0;
      final studentBlanks = studentAnswer
          .split('||')
          .map((e) => e.trim().toLowerCase())
          .toList();

      if (isInterchangeable) {
        // Greedy match: count how many student blanks hit a unique correct blank
        final remaining = blanks.map((b) => b.toLowerCase()).toList();
        int correct = 0;
        for (final sb in studentBlanks) {
          final idx = remaining.indexOf(sb);
          if (idx != -1) {
            correct++;
            remaining.removeAt(idx);
          }
        }
        return (correct / blanks.length) * points;
      } else {
        int correct = 0;
        for (int i = 0; i < blanks.length; i++) {
          final studentVal = i < studentBlanks.length ? studentBlanks[i] : '';
          if (studentVal == blanks[i].toLowerCase()) correct++;
        }
        return (correct / blanks.length) * points;
      }
    }

    return 0;
  }

  Map<String, dynamic> toSupabase() => {
        'assessment_id': assessmentId,
        'question_order': questionOrder,
        'question_text': questionText,
        'question_type': isTrueFalse ? 'multiple_choice' : questionType,
        'choices': isTrueFalse ? (choices ?? const ['True', 'False']) : choices,
        'correct_answer': correctAnswer,
        'enumeration_answers': enumerationAnswers,
        'points': points,
      };

  factory AssessmentQuestion.fromSupabase(Map<String, dynamic> map) {
    final rawType = map['question_type'] ?? 'multiple_choice';
    final choicesList = (map['choices'] as List?)?.cast<String>();
    final isTf = rawType == 'true_false' ||
        (rawType == 'multiple_choice' &&
            choicesList != null &&
            choicesList.length == 2 &&
            choicesList.any((c) => c.trim().toLowerCase() == 'true') &&
            choicesList.any((c) => c.trim().toLowerCase() == 'false'));

    return AssessmentQuestion(
      id: map['id'],
      assessmentId: map['assessment_id'] ?? '',
      questionOrder: map['question_order'] ?? 0,
      questionText: map['question_text'] ?? '',
      questionType: isTf ? 'true_false' : rawType,
      choices: isTf ? (choicesList ?? const ['True', 'False']) : choicesList,
      correctAnswer: map['correct_answer'] ?? '',
      enumerationAnswers:
          (map['enumeration_answers'] as List?)?.cast<String>(),
      points: (map['points'] as num?)?.toDouble() ?? 1,
    );
  }

  AssessmentQuestion copyWith({
    String? id,
    String? assessmentId,
    int? questionOrder,
    String? questionText,
    String? questionType,
    List<String>? choices,
    String? correctAnswer,
    List<String>? enumerationAnswers,
    double? points,
  }) =>
      AssessmentQuestion(
        id: id ?? this.id,
        assessmentId: assessmentId ?? this.assessmentId,
        questionOrder: questionOrder ?? this.questionOrder,
        questionText: questionText ?? this.questionText,
        questionType: questionType ?? this.questionType,
        choices: choices ?? this.choices,
        correctAnswer: correctAnswer ?? this.correctAnswer,
        enumerationAnswers: enumerationAnswers ?? this.enumerationAnswers,
        points: points ?? this.points,
      );
}

// ═══════════════════════════════════════════════════
// ASSESSMENT SUBMISSION
// ═══════════════════════════════════════════════════

class AssessmentSubmission {
  final String? id;
  final String assessmentId;
  final String studentId;
  final String? setLabel; // 'A' or 'B', null for quizzes
  final double score;
  final double maxScore;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final bool isGraded;

  // Appeal system fields
  final bool isInvalidated;
  final String appealStatus; // 'none', 'pending', 'approved', 'rejected'
  final String? appealReason;

  // Joined fields (from queries)
  final String? studentUsn;
  final String? studentName;
  final String? assessmentTitle;

  const AssessmentSubmission({
    this.id,
    required this.assessmentId,
    required this.studentId,
    this.setLabel,
    this.score = 0,
    this.maxScore = 0,
    this.startedAt,
    this.submittedAt,
    this.isGraded = false,
    this.isInvalidated = false,
    this.appealStatus = 'none',
    this.appealReason,
    this.studentUsn,
    this.studentName,
    this.assessmentTitle,
  });

  String get percentage =>
      maxScore > 0 ? '${((score / maxScore) * 100).toStringAsFixed(1)}%' : '0%';

  /// Generate QR data for instructor scanning.
  /// Format: STIMSYS_GRADE|assessmentId|studentId|score|maxScore|timestamp
  String get qrData =>
      'STIMSYS_GRADE|$assessmentId|$studentId|${score.toStringAsFixed(1)}|${maxScore.toStringAsFixed(1)}|${submittedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toSupabase() => {
        'assessment_id': assessmentId,
        'student_id': studentId,
        'set_label': setLabel,
        'score': score,
        'max_score': maxScore,
        // Use UTC to avoid Supabase treating local time strings as UTC.
        'started_at': startedAt?.toUtc().toIso8601String(),
        'submitted_at': submittedAt?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(),
        'is_graded': isGraded,
        'is_invalidated': isInvalidated,
        'appeal_status': appealStatus,
        'appeal_reason': appealReason,
      };

  factory AssessmentSubmission.fromSupabase(Map<String, dynamic> map) {
    // Joined student data
    final studentMap = map['students'] as Map<String, dynamic>?;
    final assessmentMap = map['assessments'] as Map<String, dynamic>?;

    return AssessmentSubmission(
      id: map['id'],
      assessmentId: map['assessment_id'] ?? '',
      studentId: map['student_id'] ?? '',
      setLabel: map['set_label'],
      score: (map['score'] as num?)?.toDouble() ?? 0,
      maxScore: (map['max_score'] as num?)?.toDouble() ?? 0,
      startedAt: map['started_at'] != null
          ? DateTime.tryParse(map['started_at'])?.toLocal()
          : null,
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'])?.toLocal()
          : null,
      isGraded: map['is_graded'] ?? false,
      isInvalidated: map['is_invalidated'] ?? false,
      appealStatus: map['appeal_status'] ?? 'none',
      appealReason: map['appeal_reason'],
      studentUsn: studentMap?['usn'],
      studentName: studentMap != null
          ? '${studentMap['last_name']}, ${studentMap['first_name']}'
          : null,
      assessmentTitle: assessmentMap?['title'],
    );
  }

  AssessmentSubmission copyWith({
    String? id,
    String? assessmentId,
    String? studentId,
    String? setLabel,
    double? score,
    double? maxScore,
    DateTime? startedAt,
    DateTime? submittedAt,
    bool? isGraded,
    bool? isInvalidated,
    String? appealStatus,
    String? appealReason,
  }) =>
      AssessmentSubmission(
        id: id ?? this.id,
        assessmentId: assessmentId ?? this.assessmentId,
        studentId: studentId ?? this.studentId,
        setLabel: setLabel ?? this.setLabel,
        score: score ?? this.score,
        maxScore: maxScore ?? this.maxScore,
        startedAt: startedAt ?? this.startedAt,
        submittedAt: submittedAt ?? this.submittedAt,
        isGraded: isGraded ?? this.isGraded,
        isInvalidated: isInvalidated ?? this.isInvalidated,
        appealStatus: appealStatus ?? this.appealStatus,
        appealReason: appealReason ?? this.appealReason,
        studentUsn: studentUsn,
        studentName: studentName,
        assessmentTitle: assessmentTitle,
      );
}

// ═══════════════════════════════════════════════════
// ASSESSMENT ANSWER (individual answer per question)
// ═══════════════════════════════════════════════════

class AssessmentAnswer {
  final String? id;
  final String submissionId;
  final String questionId;
  final String? studentAnswer;
  final bool isCorrect;
  final double pointsEarned;

  const AssessmentAnswer({
    this.id,
    required this.submissionId,
    required this.questionId,
    this.studentAnswer,
    this.isCorrect = false,
    this.pointsEarned = 0,
  });

  Map<String, dynamic> toSupabase() => {
        'submission_id': submissionId,
        'question_id': questionId,
        'student_answer': studentAnswer,
        'is_correct': isCorrect,
        'points_earned': pointsEarned,
      };

  factory AssessmentAnswer.fromSupabase(Map<String, dynamic> map) =>
      AssessmentAnswer(
        id: map['id'],
        submissionId: map['submission_id'] ?? '',
        questionId: map['question_id'] ?? '',
        studentAnswer: map['student_answer'],
        isCorrect: map['is_correct'] ?? false,
        pointsEarned: (map['points_earned'] as num?)?.toDouble() ?? 0,
      );
}
