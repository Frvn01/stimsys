import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/supabase_service.dart';

/// Full attendance detail for a single student across all dates of a subject.
class StudentAttendanceDetailScreen extends StatefulWidget {
  final RosterEntry entry;
  final String subjectTitle;
  final String subjectCode;
  /// All class dates (from the date range) for this subject.
  final List<DateTime> classDates;

  const StudentAttendanceDetailScreen({
    super.key,
    required this.entry,
    required this.subjectTitle,
    required this.subjectCode,
    required this.classDates,
  });

  @override
  State<StudentAttendanceDetailScreen> createState() =>
      _StudentAttendanceDetailScreenState();
}

class _StudentAttendanceDetailScreenState
    extends State<StudentAttendanceDetailScreen> {
  List<_DayRecord> _records = [];
  bool _loading = true;

  static const _bg   = Color(0xFF0F172A);
  static const _sf   = Color(0xFF1A2235);
  static const _bd   = Color(0xFF232D3F);
  static const _ac   = Color(0xFF6366F1);

  static const _statusColors = {
    'present': Color(0xFF10B981),
    'late':    Color(0xFFF59E0B),
    'absent':  Color(0xFFEF4444),
    'excused': Color(0xFF818CF8),
    'no_class': Color(0xFF64748B),
    'holiday': Color(0xFF0EA5E9),
    'suspended': Color(0xFFF97316),
  };
  static const _statusIcons = {
    'present': Icons.check_circle_rounded,
    'late':    Icons.watch_later_rounded,
    'absent':  Icons.cancel_rounded,
    'excused': Icons.remove_circle_rounded,
    'no_class': Icons.person_off_rounded,
    'holiday': Icons.celebration_rounded,
    'suspended': Icons.block_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    setState(() => _loading = true);
    final svc = SupabaseService();
    final results = <_DayRecord>[];

    for (final date in widget.classDates) {
      final dateStr = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      try {
        final res = await svc.client
            .from('attendance')
            .select()
            .eq('enrollment_id', widget.entry.enrollmentId)
            .eq('date', dateStr)
            .maybeSingle();

        if (res != null) {
          final rec = AttendanceRecord.fromSupabase(res);
          results.add(_DayRecord(date: date, record: rec));
        } else {
          // Class date but no record yet → show as "—"
          results.add(_DayRecord(date: date, record: null));
        }
      } catch (_) {
        results.add(_DayRecord(date: date, record: null));
      }
    }

    // Newest first
    results.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) setState(() { _records = results; _loading = false; });
  }

  // ── Stats ────────────────────────────────────────────────
  int get _totalClasses => _records.length;
  int get _cancelledCount => _records
      .where((r) => r.record != null && (r.record!.isNoClass || r.record!.isHoliday || r.record!.isSuspended)).length;
  int get _effectiveClasses => _totalClasses - _cancelledCount;
  int get _presentCount => _records
      .where((r) => r.record?.status == 'present').length;
  int get _lateCount => _records
      .where((r) => r.record?.status == 'late').length;
  int get _absentCount => _records
      .where((r) => r.record?.status == 'absent').length;
  int get _excusedCount => _records
      .where((r) => r.record?.status == 'excused').length;

  /// Attendance % = (present + late + excused) / effective classes
  /// Cancelled days (no_class, holiday, suspended) are excluded.
  double get _attendancePct {
    if (_effectiveClasses == 0) return 0;
    return ((_presentCount + _lateCount + _excusedCount) / _effectiveClasses) * 100;
  }

  Color get _pctColor {
    final p = _attendancePct;
    if (p >= 80) return const Color(0xFF10B981);
    if (p >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _sf,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.entry.fullName,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('${widget.subjectCode} • USN: ${widget.entry.usn}',
                style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78), fontSize: 11)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _ac))
          : Column(
              children: [
                _buildStats(),
                const Divider(height: 1, color: _bd),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildStats() {
    return Container(
      color: _sf,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          // Subject title
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: _ac, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(widget.subjectTitle,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attendance % ring + stat chips
          Row(
            children: [
              // Circular percentage indicator
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _attendancePct / 100,
                        strokeWidth: 7,
                        backgroundColor: _bd,
                        valueColor: AlwaysStoppedAnimation<Color>(_pctColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_attendancePct.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                              color: _pctColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                        Text('Attend.',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF4B5E78), fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Stats grid
              Expanded(
                child: Column(
                  children: [
                    Row(children: [
                      _statChip('Present', _presentCount, const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _statChip('Late', _lateCount, const Color(0xFFF59E0B)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _statChip('Absent', _absentCount, const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _statChip('Excused', _excusedCount, const Color(0xFF818CF8)),
                    ]),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF4B5E78), size: 13),
              const SizedBox(width: 5),
              Text('$_effectiveClasses effective class date${_effectiveClasses == 1 ? '' : 's'} ($_totalClasses total${_cancelledCount > 0 ? ', $_cancelledCount cancelled' : ''})',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF4B5E78), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: GoogleFonts.inter(
                        color: color, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(label,
                    style: GoogleFonts.inter(
                        color: color.withValues(alpha: 0.7), fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined,
                color: Color(0xFF2E3D54), size: 48),
            const SizedBox(height: 12),
            Text('No attendance records yet',
                style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RecordTile(
        dayRecord: _records[i],
        statusColors: _statusColors,
        statusIcons: _statusIcons,
      ),
    );
  }
}

class _DayRecord {
  final DateTime date;
  final AttendanceRecord? record;
  const _DayRecord({required this.date, required this.record});
}

class _RecordTile extends StatelessWidget {
  final _DayRecord dayRecord;
  final Map<String, Color> statusColors;
  final Map<String, IconData> statusIcons;

  const _RecordTile({
    required this.dayRecord,
    required this.statusColors,
    required this.statusIcons,
  });

  @override
  Widget build(BuildContext context) {
    final rec = dayRecord.record;
    final status = rec?.status ?? 'unmarked';
    final color = statusColors[status] ?? const Color(0xFF4B5E78);
    final icon  = statusIcons[status]  ?? Icons.help_outline_rounded;

    final dateStr = DateFormat('EEE, MMM d yyyy').format(dayRecord.date);
    final timeStr = rec?.scannedAt != null
        ? DateFormat('hh:mm:ss a').format(rec!.scannedAt!.toLocal())
        : null;

    String getLabel(String s) {
      if (s == 'no_class') return 'No Class';
      return s[0].toUpperCase() + s.substring(1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rec != null
              ? color.withValues(alpha: 0.22)
              : const Color(0xFF232D3F),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),

          // Date + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                if (timeStr != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Color(0xFF4B5E78), size: 11),
                      const SizedBox(width: 4),
                      Text(timeStr,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF4B5E78), fontSize: 11)),
                    ],
                  ),
                ],
                if (rec?.remarks != null && rec!.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(rec!.remarks!,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2), fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              status == 'unmarked'
                  ? '—'
                  : getLabel(status),
              style: GoogleFonts.inter(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
