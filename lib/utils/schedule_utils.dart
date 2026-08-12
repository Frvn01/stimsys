import '../models/subject_model.dart';

/// Maps a scheduleDay code to Dart weekday integers (1=Mon … 7=Sun).
List<int> scheduleDayToWeekdays(String scheduleDay) {
  final parts = scheduleDay.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
  final weekdays = <int>{};
  for (final part in parts) {
    switch (part.toUpperCase().trim()) {
      case 'MON':    weekdays.add(DateTime.monday); break;
      case 'TUE':    weekdays.add(DateTime.tuesday); break;
      case 'WED':    weekdays.add(DateTime.wednesday); break;
      case 'THU':    weekdays.add(DateTime.thursday); break;
      case 'FRI':    weekdays.add(DateTime.friday); break;
      case 'SAT':    weekdays.add(DateTime.saturday); break;
      case 'SUN':    weekdays.add(DateTime.sunday); break;
      case 'MWF':    weekdays.addAll([DateTime.monday, DateTime.wednesday, DateTime.friday]); break;
      case 'TTH':    weekdays.addAll([DateTime.tuesday, DateTime.thursday]); break;
      case 'MTWTHF': weekdays.addAll([DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday]); break;
      default:       break;
    }
  }
  return weekdays.toList();
}

/// Returns all dates within [rangeStart, rangeEnd] that match the subject's
/// scheduleDay pattern. E.g. for a MWF subject from June–Sept, returns all
/// Mondays, Wednesdays, and Fridays in that range.
List<DateTime> getValidClassDates(Subject subject, DateTime rangeStart, DateTime rangeEnd) {
  final weekdays = scheduleDayToWeekdays(subject.scheduleDay);
  if (weekdays.isEmpty) return [];

  final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  final dates = <DateTime>[];

  var current = start;
  while (!current.isAfter(end)) {
    if (weekdays.contains(current.weekday)) {
      dates.add(current);
    }
    current = current.add(const Duration(days: 1));
  }
  return dates;
}

/// Human-readable label for a scheduleDay code.
String scheduleDayLabel(String code) {
  switch (code.toUpperCase().trim()) {
    case 'MON':    return 'Monday';
    case 'TUE':    return 'Tuesday';
    case 'WED':    return 'Wednesday';
    case 'THU':    return 'Thursday';
    case 'FRI':    return 'Friday';
    case 'SAT':    return 'Saturday';
    case 'SUN':    return 'Sunday';
    case 'MWF':    return 'Mon / Wed / Fri';
    case 'TTH':    return 'Tue / Thu';
    case 'MTWTHF': return 'Mon–Fri';
    default:       return code;
  }
}
