import '../models/subject_model.dart';

/// Maps a scheduleDay code to Dart weekday integers (1=Mon … 7=Sun).
List<int> scheduleDayToWeekdays(String scheduleDay) {
  switch (scheduleDay.toUpperCase().trim()) {
    case 'MON':    return [DateTime.monday];
    case 'TUE':    return [DateTime.tuesday];
    case 'WED':    return [DateTime.wednesday];
    case 'THU':    return [DateTime.thursday];
    case 'FRI':    return [DateTime.friday];
    case 'SAT':    return [DateTime.saturday];
    case 'SUN':    return [DateTime.sunday];
    case 'MWF':    return [DateTime.monday, DateTime.wednesday, DateTime.friday];
    case 'TTH':    return [DateTime.tuesday, DateTime.thursday];
    case 'MTWTHF': return [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday];
    default:       return [];
  }
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
