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
  final String? themeColor;

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
    this.themeColor,
    this.instructorName,
  });

  ScheduleSlot? get todaySlot {
    final now = DateTime.now();
    for (final slot in scheduleSlots) {
      final days = slot.day.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final d in days) {
        final weekdays = _dayToWeekdays(d);
        if (weekdays.contains(now.weekday)) {
          return slot;
        }
      }
    }
    return scheduleSlots.isNotEmpty ? scheduleSlots.first : null;
  }

  static List<int> _dayToWeekdays(String code) {
    switch (code.toUpperCase().trim()) {
      case 'MON': return [DateTime.monday];
      case 'TUE': return [DateTime.tuesday];
      case 'WED': return [DateTime.wednesday];
      case 'THU': return [DateTime.thursday];
      case 'FRI': return [DateTime.friday];
      case 'SAT': return [DateTime.saturday];
      case 'SUN': return [DateTime.sunday];
      case 'MWF': return [DateTime.monday, DateTime.wednesday, DateTime.friday];
      case 'TTH': return [DateTime.tuesday, DateTime.thursday];
      case 'MTWTHF': return [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday];
      default: return [];
    }
  }

  List<ScheduleSlot> get scheduleSlots {
    final days = scheduleDay.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final starts = scheduleStartTime.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final ends = scheduleEndTime.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (days.isEmpty) {
      return [
        ScheduleSlot(
          day: scheduleDay,
          startTime: starts.isNotEmpty ? starts[0] : '00:00',
          endTime: ends.isNotEmpty ? ends[0] : '00:00',
        )
      ];
    }

    final slots = <ScheduleSlot>[];
    for (int i = 0; i < days.length; i++) {
      final sTime = i < starts.length ? starts[i] : (starts.isNotEmpty ? starts[0] : '00:00');
      final eTime = i < ends.length ? ends[i] : (ends.isNotEmpty ? ends[0] : '00:00');
      slots.add(ScheduleSlot(day: days[i], startTime: sTime, endTime: eTime));
    }
    return slots;
  }

  /// Parse "HH:mm" string to a DateTime for today (for time comparison)
  DateTime get startTimeToday {
    final slot = todaySlot;
    final timeStr = slot?.startTime ?? (scheduleStartTime.contains(';') ? scheduleStartTime.split(';').first : scheduleStartTime);
    final parts = timeStr.split(':');
    final now = DateTime.now();
    final hr = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(now.year, now.month, now.day, hr, min);
  }

  DateTime get endTimeToday {
    final slot = todaySlot;
    final timeStr = slot?.endTime ?? (scheduleEndTime.contains(';') ? scheduleEndTime.split(';').first : scheduleEndTime);
    final parts = timeStr.split(':');
    final now = DateTime.now();
    final hr = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(now.year, now.month, now.day, hr, min);
  }

  String get formattedStartTime {
    if (scheduleStartTime.isEmpty) return '';
    final slots = scheduleSlots;
    if (slots.length <= 1) return slots.first.formattedStartTime;
    return slots.map((s) => s.formattedStartTime).join(', ');
  }

  String get formattedEndTime {
    if (scheduleEndTime.isEmpty) return '';
    final slots = scheduleSlots;
    if (slots.length <= 1) return slots.first.formattedEndTime;
    return slots.map((s) => s.formattedEndTime).join(', ');
  }

  String get formattedSchedule {
    final slots = scheduleSlots;
    if (slots.length <= 1) {
      return slots.first.formatted;
    }
    return slots.map((s) => s.formatted).join(' | ');
  }

  /// Clean 12-hour format time range for the subject, e.g. "06:00 PM - 07:30 PM".
  String get formattedTimeRange {
    final slots = scheduleSlots;
    if (slots.isEmpty) {
      if (scheduleStartTime.isEmpty) return '';
      return '$formattedStartTime - $formattedEndTime';
    }
    if (slots.length == 1) {
      return '${slots.first.formattedStartTime} - ${slots.first.formattedEndTime}';
    }
    final firstStart = slots.first.formattedStartTime;
    final firstEnd = slots.first.formattedEndTime;
    final allSame = slots.every(
        (s) => s.formattedStartTime == firstStart && s.formattedEndTime == firstEnd);
    if (allSame) {
      return '$firstStart - $firstEnd';
    }
    return slots
        .map((s) => '${s.day}: ${s.formattedStartTime} - ${s.formattedEndTime}')
        .join(', ');
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
      'theme_color': themeColor,
    };
  }

  factory Subject.fromSupabase(Map<String, dynamic> map) {
    // Handle time fields - Supabase TIME type returns as "HH:mm:ss"
    String parseTime(dynamic value) {
      if (value == null) return '00:00';
      final str = value.toString();
      final items = str.split(';');
      final parsedItems = <String>[];
      for (final item in items) {
        final parts = item.trim().split(':');
        if (parts.length >= 2) {
          parsedItems.add('${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}');
        } else {
          parsedItems.add(item.trim());
        }
      }
      return parsedItems.join('; ');
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
      themeColor: map['theme_color'],
      instructorName: map['instructors'] != null
          ? map['instructors']['full_name']
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Subject) return false;
    if (id != null && other.id != null) {
      return id == other.id;
    }
    return subjectCode == other.subjectCode;
  }

  @override
  int get hashCode => (id ?? subjectCode).hashCode;
}

class ScheduleSlot {
  final String day;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"

  ScheduleSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  String _formatSingleTime(String tStr) {
    if (tStr.isEmpty) return '';
    final parts = tStr.split(':');
    if (parts.length < 2) return tStr;
    int hr = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hr >= 12 ? 'PM' : 'AM';
    if (hr == 0) hr = 12;
    if (hr > 12) hr -= 12;
    return '${hr.toString().padLeft(2, '0')}:$min $period';
  }

  String get formattedStartTime => _formatSingleTime(startTime);
  String get formattedEndTime => _formatSingleTime(endTime);

  String get formatted {
    final startFmt = formattedStartTime;
    final endFmt = formattedEndTime;
    if (startFmt.isEmpty && endFmt.isEmpty) return day;
    return '$day $startFmt - $endFmt';
  }
}
