import 'package:flutter_test/flutter_test.dart';
import 'package:stimsys/models/attendance_model.dart';
import 'package:stimsys/utils/attendance_utils.dart';

AttendanceRecord _rec(DateTime date, String status) => AttendanceRecord(
      enrollmentId: 'e1',
      date: date,
      status: status,
    );

void main() {
  // September 2026: Mon 7/14/21 · Wed 2/9/16/23 · Fri 4/11/18/25
  final termStart = DateTime(2026, 9, 1);
  final termEnd = DateTime(2026, 9, 11);

  group('summarizeAttendance — expected class days', () {
    test('days without a record count as absences (9/10 ≠ 100%)', () {
      // MWF in Sep 1 → Sep 11 = 2, 4, 7, 9, 11 → 5 class days.
      // The student scanned on every day except Sep 9.
      final records = [
        _rec(DateTime(2026, 9, 2), 'present'),
        _rec(DateTime(2026, 9, 4), 'present'),
        _rec(DateTime(2026, 9, 7), 'present'),
        _rec(DateTime(2026, 9, 11), 'present'),
      ];

      final s = summarizeAttendance(
        records: records,
        scheduleDay: 'MWF',
        rangeStart: termStart,
        rangeEnd: termEnd,
        now: DateTime(2026, 9, 12),
      );

      expect(s.total, 5);
      expect(s.present, 4);
      expect(s.missing, 1);
      expect(s.rate, closeTo(0.8, 0.0001));
      expect(s.scoreRate, closeTo(0.8, 0.0001));
    });

    test('late earns half credit, excused earns full credit', () {
      final records = [
        _rec(DateTime(2026, 9, 2), 'present'),
        _rec(DateTime(2026, 9, 4), 'late'),
        _rec(DateTime(2026, 9, 7), 'excused'),
        _rec(DateTime(2026, 9, 9), 'absent'),
      ];

      final s = summarizeAttendance(
        records: records,
        scheduleDay: 'MWF',
        rangeStart: termStart,
        rangeEnd: termEnd,
        now: DateTime(2026, 9, 12),
      );

      expect(s.total, 5);
      expect(s.absent, 1);
      expect(s.missing, 1);
      expect(s.rate, closeTo(3 / 5, 0.0001)); // present + late + excused
      expect(s.scoreRate, closeTo((1 + 0.5 + 1) / 5, 0.0001));
    });

    test('cancelled class days are excluded from the denominator', () {
      final records = [
        _rec(DateTime(2026, 9, 2), 'present'),
        _rec(DateTime(2026, 9, 4), 'present'),
        _rec(DateTime(2026, 9, 7), 'present'),
        _rec(DateTime(2026, 9, 9), 'present'),
        _rec(DateTime(2026, 9, 11), 'present'),
      ];

      final viaCancellationTable = summarizeAttendance(
        records: records,
        scheduleDay: 'MWF',
        rangeStart: termStart,
        rangeEnd: termEnd,
        cancelledDates: {'2026-09-07'},
        now: DateTime(2026, 9, 12),
      );
      expect(viaCancellationTable.total, 4);
      expect(viaCancellationTable.rate, closeTo(1.0, 0.0001));

      // …and the same when the cancellation is stored as a record status.
      final viaRecordStatus = summarizeAttendance(
        records: [
          ...records,
          _rec(DateTime(2026, 9, 9), 'holiday'),
        ],
        scheduleDay: 'MWF',
        rangeStart: termStart,
        rangeEnd: termEnd,
        now: DateTime(2026, 9, 12),
      );
      expect(viaRecordStatus.total, 4); // Sep 9 is now a cancelled day
      expect(viaRecordStatus.rate, closeTo(1.0, 0.0001));
    });

    test('future class days are never counted', () {
      final records = [
        _rec(DateTime(2026, 9, 2), 'present'),
        _rec(DateTime(2026, 9, 4), 'present'),
      ];

      final s = summarizeAttendance(
        records: records,
        scheduleDay: 'MWF',
        rangeStart: termStart,
        rangeEnd: DateTime(2026, 9, 30),
        now: DateTime(2026, 9, 9), // a class day that hasn't been recorded yet
      );

      // 2nd, 4th and 7th are in the past; today (9th) has no record yet, so
      // it is skipped; days after today are never counted.
      expect(s.total, 3);
      expect(s.missing, 1);
      expect(s.rate, closeTo(2 / 3, 0.0001));
    });

    test('falls back to recorded days when the schedule is unknown', () {
      final records = [
        _rec(DateTime(2026, 9, 2), 'present'),
        _rec(DateTime(2026, 9, 4), 'present'),
        _rec(DateTime(2026, 9, 7), 'absent'),
      ];

      final s = summarizeAttendance(
        records: records,
        scheduleDay: null,
        rangeStart: termStart,
        rangeEnd: termEnd,
        now: DateTime(2026, 9, 12),
      );

      expect(s.total, 3);
      expect(s.rate, closeTo(2 / 3, 0.0001));
    });

    test('no records and no schedule → empty summary', () {
      final s = summarizeAttendance(
        records: const [],
        scheduleDay: null,
        now: DateTime(2026, 9, 12),
      );
      expect(s.total, 0);
      expect(s.rate, 0);
      expect(s.scoreRate, 0);
    });
  });

  group('expectedClassDates', () {
    test('expands combined day codes', () {
      final dates = expectedClassDates(
        scheduleDay: 'MWF',
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 7),
      );
      expect(dates.map((d) => d.day).toList(), [2, 4, 7]);
    });

    test('returns nothing for an unusable schedule', () {
      expect(
        expectedClassDates(
          scheduleDay: '',
          from: DateTime(2026, 9, 1),
          to: DateTime(2026, 9, 7),
        ),
        isEmpty,
      );
    });
  });
}
