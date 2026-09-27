import 'package:intl/intl.dart';

class AttendanceRecord {
  final String? id;
  final String enrollmentId;
  final DateTime date;
  final String status; // 'present', 'late', 'absent', 'excused', 'no_class', 'holiday', 'suspended'
  final DateTime? scannedAt;
  final int minutesLate;
  final DateTime? markedAt;
  final String? remarks;

  // Joined fields for display
  final String? studentName;
  final String? studentUsn;
  final String? subjectCode;
  final String? subjectTitle;

  // Joined fields used to derive the *expected* class dates for a subject
  // (so days without an attendance record still count toward the total).
  final String? subjectId;
  final String? scheduleDay;   // e.g. "MWF", "TTH"
  final DateTime? enrolledAt;

  // Extra joined fields for section grouping in tracker
  final String? studentCourse;
  final String? studentYearLevel;
  final String? studentSection;
  final String? studentLastName;
  final String? studentFirstName;

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
    this.subjectId,
    this.scheduleDay,
    this.enrolledAt,
    this.studentCourse,
    this.studentYearLevel,
    this.studentSection,
    this.studentLastName,
    this.studentFirstName,
  });

  bool get isPresent => status == 'present';
  bool get isLate => status == 'late';
  bool get isAbsent => status == 'absent';
  bool get isExcused => status == 'excused';
  bool get isNoClass => status == 'no_class';
  bool get isHoliday => status == 'holiday';
  bool get isSuspended => status == 'suspended';
  /// True when the day was cancelled (no_class / holiday / suspended)
  bool get isCancelled => isNoClass || isHoliday || isSuspended;

  /// e.g. "BSIT 2 A" or "WAD 1 AB"
  String get sectionLabel {
    final c = studentCourse ?? '';
    final y = studentYearLevel ?? '';
    final s = studentSection ?? '';
    if (c.isEmpty && y.isEmpty && s.isEmpty) return 'Unknown Section';
    return '$c $y $s'.trim();
  }

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late ($minutesLate min)';
      case 'absent':
        return 'Absent';
      case 'excused':
        return 'Excused';
      case 'no_class':
        return 'No Class';
      case 'holiday':
        return 'Holiday';
      case 'suspended':
        return 'Suspended';
      default:
        return status;
    }
  }

  /// Converts any UTC or local DateTime to Philippine Standard Time (PST/PHT, UTC+8).
  /// Handles self-healing for legacy records where local time numbers were stored as UTC.
  static DateTime toPht(DateTime dt, [DateTime? referenceDate]) {
    // If dt is not UTC and system is already UTC+8, it's already in PHT
    if (!dt.isUtc && dt.timeZoneOffset.inHours == 8) {
      return dt;
    }

    final asUtc = dt.toUtc();
    final withOffset = asUtc.add(const Duration(hours: 8));

    if (referenceDate != null) {
      final refDay = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
      final utcDay = DateTime(asUtc.year, asUtc.month, asUtc.day);
      final offsetDay = DateTime(withOffset.year, withOffset.month, withOffset.day);

      // If adding 8 hours shifts to the next day while utcDay was already on referenceDate,
      // the record was saved with raw local time numbers.
      if (utcDay.isAtSameMomentAs(refDay) && !offsetDay.isAtSameMomentAs(refDay)) {
        return DateTime(asUtc.year, asUtc.month, asUtc.day, asUtc.hour, asUtc.minute, asUtc.second);
      }
    }

    // If adding 8 hours rolls over past midnight (00:00 - 05:59) from evening (18:00+),
    // it was already local evening time.
    if (withOffset.hour < 6 && asUtc.hour >= 18) {
      return DateTime(asUtc.year, asUtc.month, asUtc.day, asUtc.hour, asUtc.minute, asUtc.second);
    }

    return DateTime(withOffset.year, withOffset.month, withOffset.day, withOffset.hour, withOffset.minute, withOffset.second);
  }

  /// Formatted scan time in 12-hour Philippine Time (e.g. "06:18 PM").
  String get formattedScanTime {
    if (scannedAt == null) return '—';
    final pht = toPht(scannedAt!, date);
    return DateFormat('hh:mm a').format(pht);
  }

  /// Formatted scan time with seconds (e.g. "06:18:23 PM").
  String get formattedScanTimeWithSeconds {
    if (scannedAt == null) return '—';
    final pht = toPht(scannedAt!, date);
    return DateFormat('hh:mm:ss a').format(pht);
  }

  Map<String, dynamic> toSupabase() {
    return {
      'enrollment_id': enrollmentId,
      'date': date.toIso8601String().split('T').first,
      'status': status,
      'scanned_at': scannedAt?.toUtc().toIso8601String(),
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
    String? studentCourse;
    String? studentYearLevel;
    String? studentSection;
    String? studentLastName;
    String? studentFirstName;
    String? subjectId;
    String? scheduleDay;
    DateTime? enrolledAt;

    if (map['enrollments'] != null) {
      final enrollment = map['enrollments'];
      subjectId = enrollment['subject_id'];
      enrolledAt = enrollment['enrolled_at'] != null
          ? DateTime.tryParse(enrollment['enrolled_at'])
          : null;
      if (enrollment['students'] != null) {
        final student = enrollment['students'];
        studentFirstName = student['first_name'];
        studentLastName = student['last_name'];
        studentName = '${student['first_name']} ${student['last_name']}';
        studentUsn = student['usn'];
        studentCourse = student['course'];
        studentYearLevel = student['year_level'];
        studentSection = student['section'];
      }
      if (enrollment['subjects'] != null) {
        final subject = enrollment['subjects'];
        subjectCode = subject['subject_code'];
        subjectTitle = subject['subject_title'];
        scheduleDay = subject['schedule_day'];
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
      subjectId: subjectId,
      scheduleDay: scheduleDay,
      enrolledAt: enrolledAt,
      studentCourse: studentCourse,
      studentYearLevel: studentYearLevel,
      studentSection: studentSection,
      studentLastName: studentLastName,
      studentFirstName: studentFirstName,
    );
  }
}
