enum QuestionType { multipleChoice, identification, enumeration }

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? choices; // for multiple choice
  final String correctAnswer;
  final List<String>? enumerationAnswers; // for enumeration (multiple correct answers)

  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.choices,
    required this.correctAnswer,
    this.enumerationAnswers,
  });
}

class Assessment {
  final String id;
  final String subjectName;
  final String term; // Prelims, Midterms, Pre-Finals, Finals
  final String type; // Quiz or Exam
  final List<Question> questions;

  const Assessment({
    required this.id,
    required this.subjectName,
    required this.term,
    required this.type,
    required this.questions,
  });
}

class AssessmentResult {
  final String assessmentId;
  final String subjectName;
  final String term;
  final String type;
  final String studentName;
  final int score;
  final int totalItems;
  final DateTime takenAt;

  AssessmentResult({
    required this.assessmentId,
    required this.subjectName,
    required this.term,
    required this.type,
    required this.studentName,
    required this.score,
    required this.totalItems,
    required this.takenAt,
  });

  String get percentage =>
      '${((score / totalItems) * 100).toStringAsFixed(1)}%';

  String get qrData =>
      'ASSESSMENT|$subjectName|$term|$type|$studentName|$score/$totalItems|${takenAt.millisecondsSinceEpoch}';
}