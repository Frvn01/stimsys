import '../models/attendance_model.dart';
import 'schedule_utils.dart';

/// Parses a `scheduleDay` string (e.g. "MWF", "MON; WED", "TTH") into the
/// set of Dart weekday integers it matches. Empty when nothing can be parsed.
Set<int> _weekdaysOf(String? scheduleDay) {
  if (scheduleDay == null || scheduleDay.trim().isEmpty) return <int>{};
  return scheduleDayToWeekdays(scheduleDay).toSet();
}

/// Normalises any date to a date-only `DateTime` (local, midnight).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// All scheduled class dates in `[from, to]` for the given schedule pattern.
///
/// Returns an empty list when the schedule pattern is unusable so callers can
/// fall back to a record-based calculation.
List<DateTime> expectedClassDates({
  required String? scheduleDay,
  required DateTime from,
  required DateTime to,
}) {
  final weekdays = _weekdaysOf(scheduleDay);
  if (weekdays.isEmpty) return const [];

  final start = dateOnly(from);
  final end = dateOnly(to);
  if (end.isBefore(start)) return const [];

  final dates = <DateTime>[];
  var current = start;
  while (!current.isAfter(end)) {
    if (weekdays.contains(current.weekday)) dates.add(current);
    current = current.add(const Duration(days: 1));
  }
  return dates;
}

/// Attendance tally for a single subject/term.
class AttendanceSummary {
  final int present;
  final int late;
  final int absent;
  final int excused;
  final int missing;

  const AttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.excused = 0,
    this.missing = 0,
  });

  /// Total number of *effective* class days (cancelled days excluded).
  int get total => present + late + absent + excused + missing;

  /// Days that count as attended (present / late / excused).
  int get attended => present + late + excused;

  /// 0.0 – 1.0 — used for the attendance percentage banner.
  double get rate => total == 0 ? 0.0 : attended / total;

  /// 0.0 – 1.0 — credit toward the attendance grade (late = half credit).
  double get scoreRate =>
      total == 0 ? 0.0 : (present + (late * 0.5) + excused) / total;

  static const empty = AttendanceSummary();
}

/// Computes an attendance summary that is **not** fooled by days the student
/// simply has no record for.
///
/// The denominator comes from the subject's expected class dates (schedule
/// pattern ∩ date range, capped at today), so a student who attended 9 of 10
/// held classes is reported as 90% instead of 100%.
///
/// * [scheduleDay]  – subject schedule pattern ("MWF", "TTH", …).
/// * [rangeStart]   – first day of the period (term start / enrolment date).
/// * [rangeEnd]     – last day of the period; future days are never counted.
/// * [cancelledDates] – `'yyyy-MM-dd'` keys of cancelled classes, in addition
///   to dates whose record has a cancelled status (no_class/holiday/suspended).
///
/// When the schedule pattern or [rangeStart] is unavailable the calculation
/// falls back to the recorded days (previous behaviour) instead of guessing.
AttendanceSummary summarizeAttendance({
  required List<AttendanceRecord> records,
  required String? scheduleDay,
  DateTime? rangeStart,
  DateTime? rangeEnd,
  Set<String> cancelledDates = const <String>{},
  DateTime? now,
}) {
  final today = dateOnly(now ?? DateTime.now());

  final byDate = <String, AttendanceRecord>{};
  final cancelled = <String>{...cancelledDates};
  for (final r in records) {
    final key = dateOnly(r.date).toIso8601String().split('T').first;
    byDate[key] = r;
    if (r.isCancelled) cancelled.add(key);
  }

  // ── Which days should exist? ────────────────────────────────
  DateTime? start = rangeStart != null ? dateOnly(rangeStart) : null;
  DateTime end = rangeEnd == null || dateOnly(rangeEnd).isAfter(today)
      ? today
      : dateOnly(rangeEnd);

  // Fall back to the recorded days when we cannot build a schedule.
  if (start == null && records.isNotEmpty) {
    var earliest = dateOnly(records.first.date);
    for (final r in records) {
      final d = dateOnly(r.date);
      if (d.isBefore(earliest)) earliest = d;
    }
    start = earliest;
  }

  List<DateTime>? expected;
  if (start != null && !end.isBefore(start)) {
    expected = expectedClassDates(
        scheduleDay: scheduleDay, from: start, to: end);
    if (expected.isEmpty) expected = null;
  }

  List<DateTime> effectiveDates;
  if (expected != null) {
    // Scheduled days that were actually held: always count days before
    // today, and today only once a record exists (class may not have
    // started yet when the page is opened).
    effectiveDates = expected
        .where((d) =>
            !cancelled.contains(d.toIso8601String().split('T').first) &&
            (d.isBefore(today) || byDate.containsKey(d.toIso8601String().split('T').first)))
        .toList();
  } else {
    // Fallback: only recorded days (excludes cancelled ones).
    effectiveDates = byDate.keys
        .where((k) => !cancelled.contains(k))
        .map(DateTime.parse)
        .toList()
      ..sort();
  }

  var present = 0, late = 0, absent = 0, excused = 0, missing = 0;
  for (final d in effectiveDates) {
    final rec = byDate[d.toIso8601String().split('T').first];
    if (rec == null) {
      missing++;
      continue;
    }
    switch (rec.status) {
      case 'present':
        present++;
        break;
      case 'late':
        late++;
        break;
      case 'excused':
        excused++;
        break;
      default:
        absent++;
    }
  }

  return AttendanceSummary(
    present: present,
    late: late,
    absent: absent,
    excused: excused,
    missing: missing,
  );
}
