class Subject {
  final String? id;
  final String subjectCode;
  final String subjectTitle;
  final int units;
  final String scheduleStartTime; // "HH:mm" format, e.g. "10:30"
  final String scheduleEndTime;   // "HH:mm" format, e.g. "13:00"
  final String scheduleDay;       // e.g. "MWF", "TTH", "SAT"
  final String room;
  final String instructorId;
  final int lateThresholdMinutes;
  final DateTime? createdAt;

  // Joined fields
  final String? instructorName;

  Subject({
    this.id,
    required this.subjectCode,
    required this.subjectTitle,
    required this.units,
    required this.scheduleStartTime,
    required this.scheduleEndTime,
    required this.scheduleDay,
    required this.room,
    required this.instructorId,
    this.lateThresholdMinutes = 15,
    this.createdAt,
    this.instructorName,
  });

  /// Parse "HH:mm" string to a DateTime for today (for time comparison)
  DateTime get startTimeToday {
    final parts = scheduleStartTime.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime get endTimeToday {
    final parts = scheduleEndTime.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  String get formattedStartTime {
    if (scheduleStartTime.isEmpty) return '';
    final parts = scheduleStartTime.split(':');
    if (parts.length < 2) return scheduleStartTime;
    int hr = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hr >= 12 ? 'PM' : 'AM';
    if (hr == 0) hr = 12;
    if (hr > 12) hr -= 12;
    return '${hr.toString().padLeft(2, '0')}:$min $period';
  }

  String get formattedEndTime {
    if (scheduleEndTime.isEmpty) return '';
    final parts = scheduleEndTime.split(':');
    if (parts.length < 2) return scheduleEndTime;
    int hr = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hr >= 12 ? 'PM' : 'AM';
    if (hr == 0) hr = 12;
    if (hr > 12) hr -= 12;
    return '${hr.toString().padLeft(2, '0')}:$min $period';
  }

  String get formattedSchedule {
    return '$scheduleDay $formattedStartTime - $formattedEndTime';
  }

  Map<String, dynamic> toSupabase() {
    return {
      'subject_code': subjectCode,
      'subject_title': subjectTitle,
      'units': units,
      'schedule_start_time': scheduleStartTime,
      'schedule_end_time': scheduleEndTime,
      'schedule_day': scheduleDay,
      'room': room,
      'instructor_id': instructorId,
      'late_threshold_minutes': lateThresholdMinutes,
    };
  }

  factory Subject.fromSupabase(Map<String, dynamic> map) {
    // Handle time fields - Supabase TIME type returns as "HH:mm:ss"
    String parseTime(dynamic value) {
      if (value == null) return '00:00';
      final str = value.toString();
      // Take only HH:mm from "HH:mm:ss" or "HH:mm:ss+00"
      final parts = str.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return str;
    }

    return Subject(
      id: map['id'],
      subjectCode: map['subject_code'] ?? '',
      subjectTitle: map['subject_title'] ?? '',
      units: map['units'] ?? 0,
      scheduleStartTime: parseTime(map['schedule_start_time']),
      scheduleEndTime: parseTime(map['schedule_end_time']),
      scheduleDay: map['schedule_day'] ?? '',
      room: map['room'] ?? '',
      instructorId: map['instructor_id'] ?? '',
      lateThresholdMinutes: map['late_threshold_minutes'] ?? 15,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      instructorName: map['instructors'] != null
          ? map['instructors']['full_name']
          : null,
    );
  }
}
