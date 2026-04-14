import 'subject_model.dart';

class Enrollment {
  final String? id;
  final String studentId;
  final String subjectId;
  final DateTime? enrolledAt;

  // Nested subject data (from join)
  final Subject? subject;

  Enrollment({
    this.id,
    required this.studentId,
    required this.subjectId,
    this.enrolledAt,
    this.subject,
  });

  // Convenience getters delegating to nested Subject
  String? get subjectTitle => subject?.subjectTitle;
  String? get subjectCode => subject?.subjectCode;
  String? get scheduleDay => subject?.scheduleDay;
  String? get room => subject?.room;

  Map<String, dynamic> toSupabase() {
    return {
      'student_id': studentId,
      'subject_id': subjectId,
    };
  }

  factory Enrollment.fromSupabase(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'],
      studentId: map['student_id'] ?? '',
      subjectId: map['subject_id'] ?? '',
      enrolledAt: map['enrolled_at'] != null
          ? DateTime.parse(map['enrolled_at'])
          : null,
      subject: map['subjects'] != null
          ? Subject.fromSupabase(map['subjects'])
          : null,
    );
  }
}
