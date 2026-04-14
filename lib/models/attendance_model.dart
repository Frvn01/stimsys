class AttendanceRecord {
  final String? id;
  final String enrollmentId;
  final DateTime date;
  final String status; // 'present', 'late', 'absent'
  final DateTime? scannedAt;
  final int minutesLate;
  final DateTime? markedAt;
  final String? remarks;

  // Joined fields for display
  final String? studentName;
  final String? studentUsn;
  final String? subjectCode;
  final String? subjectTitle;

  AttendanceRecord({
    this.id,
    required this.enrollmentId,
    required this.date,
    required this.status,
    this.scannedAt,
    this.minutesLate = 0,
    this.markedAt,
    this.remarks,
    this.studentName,
    this.studentUsn,
    this.subjectCode,
    this.subjectTitle,
  });

  bool get isPresent => status == 'present';
  bool get isLate => status == 'late';
  bool get isAbsent => status == 'absent';

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late ($minutesLate min)';
      case 'absent':
        return 'Absent';
      default:
        return status;
    }
  }

  Map<String, dynamic> toSupabase() {
    return {
      'enrollment_id': enrollmentId,
      'date': date.toIso8601String().split('T').first,
      'status': status,
      'scanned_at': scannedAt?.toIso8601String(),
      'minutes_late': minutesLate,
      'remarks': remarks,
    };
  }

  factory AttendanceRecord.fromSupabase(Map<String, dynamic> map) {
    // Extract nested student/subject info from joins
    String? studentName;
    String? studentUsn;
    String? subjectCode;
    String? subjectTitle;

    if (map['enrollments'] != null) {
      final enrollment = map['enrollments'];
      if (enrollment['students'] != null) {
        final student = enrollment['students'];
        studentName = '${student['first_name']} ${student['last_name']}';
        studentUsn = student['usn'];
      }
      if (enrollment['subjects'] != null) {
        final subject = enrollment['subjects'];
        subjectCode = subject['subject_code'];
        subjectTitle = subject['subject_title'];
      }
    }

    return AttendanceRecord(
      id: map['id'],
      enrollmentId: map['enrollment_id'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      status: map['status'] ?? 'absent',
      scannedAt: map['scanned_at'] != null
          ? DateTime.parse(map['scanned_at'])
          : null,
      minutesLate: map['minutes_late'] ?? 0,
      markedAt: map['marked_at'] != null
          ? DateTime.parse(map['marked_at'])
          : null,
      remarks: map['remarks'],
      studentName: studentName,
      studentUsn: studentUsn,
      subjectCode: subjectCode,
      subjectTitle: subjectTitle,
    );
  }
}
