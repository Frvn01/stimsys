class GradeCapture {
  final String? id;
  final String fileUrl;
  final String fileType; // 'image' or 'video'
  final String? studentNote;
  final String? subjectId;
  final String? subjectCode;
  final String? studentName;  // e.g. "Raven Ulrich Fabre"
  final String? section;      // e.g. "WAD 3 AB"
  final DateTime capturedAt;
  final DateTime expiresAt;

  GradeCapture({
    this.id,
    required this.fileUrl,
    this.fileType = 'image',
    this.studentNote,
    this.subjectId,
    this.subjectCode,
    this.studentName,
    this.section,
    DateTime? capturedAt,
    DateTime? expiresAt,
  })  : capturedAt = capturedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 21));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;

  factory GradeCapture.fromSupabase(Map<String, dynamic> map) {
    return GradeCapture(
      id: map['id'],
      fileUrl: map['file_url'] ?? '',
      fileType: map['file_type'] ?? 'image',
      studentNote: map['student_note'],
      subjectId: map['subject_id'],
      subjectCode: map['subjects']?['subject_code'],
      studentName: map['student_name'],
      section: map['section'],
      capturedAt: map['captured_at'] != null
          ? DateTime.parse(map['captured_at'])
          : DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : DateTime.now().add(const Duration(days: 21)),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'file_url': fileUrl,
      'file_type': fileType,
      'student_note': studentNote,
      'subject_id': subjectId,
      'student_name': studentName,
      'section': section,
      'captured_at': capturedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
