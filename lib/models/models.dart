class QuizRecord {
  final int? id;
  final String courseName;
  final String email;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final String qrCode;
  final String? term;
  final String? assessmentType;

  QuizRecord({
    this.id,
    required this.courseName,
    required this.email,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.qrCode,
    this.term,
    this.assessmentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseName': courseName,
      'email': email,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
      'qrCode': qrCode,
      'term': term,
      'assessmentType': assessmentType,
    };
  }

  factory QuizRecord.fromMap(Map<String, dynamic> map) {
    return QuizRecord(
      id: map['id'] as int?,
      courseName: map['courseName'] as String,
      email: map['email'] as String,
      score: map['score'] as int,
      totalQuestions: map['totalQuestions'] as int,
      completedAt: DateTime.parse(map['completedAt'] as String),
      qrCode: map['qrCode'] as String,
      term: map['term'] as String?,
      assessmentType: map['assessmentType'] as String?,
    );
  }

  double get percentage => (score / totalQuestions) * 100;
}

class AttendanceRecord {
  final int? id;
  final String courseName;
  final String email;
  final DateTime markedAt;
  final String qrCode;

  AttendanceRecord({
    this.id,
    required this.courseName,
    required this.email,
    required this.markedAt,
    required this.qrCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseName': courseName,
      'email': email,
      'markedAt': markedAt.toIso8601String(),
      'qrCode': qrCode,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      courseName: map['courseName'] as String,
      email: map['email'] as String,
      markedAt: DateTime.parse(map['markedAt'] as String),
      qrCode: map['qrCode'] as String,
    );
  }
}

class EventRecord {
  final int? id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String courseName;
  final String type; // 'quiz', 'assignment', 'exam', 'lab'

  EventRecord({
    this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.courseName,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'courseName': courseName,
      'type': type,
    };
  }

  factory EventRecord.fromMap(Map<String, dynamic> map) {
    return EventRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      eventDate: DateTime.parse(map['eventDate'] as String),
      courseName: map['courseName'] as String,
      type: map['type'] as String,
    );
  }
}
