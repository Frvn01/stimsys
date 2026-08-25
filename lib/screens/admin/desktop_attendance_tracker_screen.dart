import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/grading_config_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/schedule_utils.dart';
import '../../core/supabase_config.dart';
import 'desktop_attendance_widgets.dart';

class DesktopAttendanceTrackerScreen extends StatefulWidget {
  const DesktopAttendanceTrackerScreen({super.key});
  @override
  State<DesktopAttendanceTrackerScreen> createState() => _State();
}

class _State extends State<DesktopAttendanceTrackerScreen> {
  Subject? _subj;
  DateTime? _selDate;
  DateTime _rStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rEnd = DateTime(DateTime.now().year, DateTime.now().month + 4, 0);
  List<RosterEntry> _roster = [];
  List<DateTime> _dates = [];
  bool _loading = false;
  StreamSubscription? _rtSub;
  GradingConfig? _config;

  // Class cancellation tracking
  Map<String, ClassCancellation> _cancellations = {}; // dateStr → cancellation
  bool _cancelLoading = false;

  // Phase 1.2 — section filter
  String? _selectedSection; // null = All sections

  static const _bg = Color(0xFF0F172A);
  static const _sf = Color(0xFF1A2235);
  static const _bd = Color(0xFF232D3F);
  static const _ac = Color(0xFF6366F1);
  static const _sc = {
    'present': Color(0xFF10B981),
    'late': Color(0xFFF59E0B),
    'absent': Color(0xFFEF4444),
    'excused': Color(0xFF818CF8),
    'no_class': Color(0xFF64748B),
    'holiday': Color(0xFF0EA5E9),
    'suspended': Color(0xFFF97316),
  };

  @override
  void dispose() {
    _rtSub?.cancel();
    super.dispose();
  }

  void _onSubj(Subject? s, AdminProvider p) {
    setState(() {
      _subj = s;
      _selDate = null;
      _roster = [];
      _selectedSection = null;
      _cancellations = {};
      _config = null;
    });
    _calcDates();
    _initRT();
    _loadCancellations();
    if (s != null) {
      _loadConfig(p, s.id!);
    }
  }

  Future<void> _loadConfig(AdminProvider p, String subjectId) async {
    final cfg = await p.loadGradingConfig(subjectId);
    if (mounted && _subj?.id == subjectId) {
      setState(() => _config = cfg);
      _calcDates(); // Recalculate dates with semester bounds now known
    }
  }

  /// Returns null if semester dates are fully configured and today is within bounds.
  /// Returns a message if the semester hasn't started or has ended.
  String? get _semesterStatus {
    if (_config == null) return null;
    final prelimS = _config!.prelimStart;
    final finalsE = _config!.finalsEnd;
    if (prelimS == null || finalsE == null) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (todayDate.isBefore(prelimS)) {
      return 'Semester starts ${_fmtDate(prelimS)}';
    }
    if (todayDate.isAfter(finalsE)) {
      return 'End of Semester';
    }
    return null;
  }

  String _fmtDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  void _calcDates() {
    if (_subj == null) {
      setState(() => _dates = []);
      return;
    }
    // Use grading config semester bounds if configured, otherwise use default range
    final semStart = _config?.prelimStart ?? _rStart;
    final semEnd = _config?.finalsEnd ?? _rEnd;
    final d = getValidClassDates(_subj!, semStart, semEnd);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _dates = d;
      if (d.isNotEmpty) _selDate = d.contains(today) ? today : d.last;
    });
    if (_selDate != null) _load(context.read<AdminProvider>());
  }

  Future<void> _loadCancellations() async {
    if (_subj == null || _subj!.id == null) return;
    final p = context.read<AdminProvider>();
    final list = await p.getCancellationsForSubject(_subj!.id!);
    final map = <String, ClassCancellation>{};
    for (final c in list) {
      map[c.date.toIso8601String().split('T').first] = c;
    }
    if (mounted) setState(() => _cancellations = map);
  }

  bool _isDateCancelled(DateTime date) {
    final dateStr = date.toIso8601String().split('T').first;
    return _cancellations.containsKey(dateStr);
  }

  ClassCancellation? _getCancellation(DateTime date) {
    final dateStr = date.toIso8601String().split('T').first;
    return _cancellations[dateStr];
  }

  DateTime? _lastRTRefresh;

  void _initRT() {
    _rtSub?.cancel();
    if (_subj == null) return;
    _rtSub = SupabaseConfig.client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .listen((_) {
          if (_loading || !mounted || _subj == null || _selDate == null) return;
          final now = DateTime.now();
          if (_lastRTRefresh != null &&
              now.difference(_lastRTRefresh!).inSeconds < 2)
            return;
          _lastRTRefresh = now;
          _load(context.read<AdminProvider>());
        });
  }

  Future<void> _load(AdminProvider p) async {
    if (_subj == null || _selDate == null || _loading) return;
    setState(() => _loading = true);
    _roster = await p.getSubjectRoster(_subj!.id!, date: _selDate);
    if (mounted) setState(() => _loading = false);
  }

  // ── Filtered roster by selected section ──────────────────
  List<RosterEntry> get _filteredRoster {
    if (_selectedSection == null || _selectedSection == 'All') return _roster;
    return _roster.where((e) => e.sectionLabel == _selectedSection).toList();
  }

  // ── All unique section labels in current roster ──────────
  List<String> get _sectionOptions {
    final labels = _roster.map((e) => e.sectionLabel).toSet().toList()..sort();
    return labels;
  }

  Map<String, List<RosterEntry>> get _grp {
    final m = <String, List<RosterEntry>>{};
    for (final e in _filteredRoster) {
      final k = e.sectionLabel.isEmpty ? 'Unknown' : e.sectionLabel;
      m.putIfAbsent(k, () => []).add(e);
    }
    return Map.fromEntries(
      m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  int _cnt(String s) =>
      _filteredRoster.where((e) => e.attendanceRecord?.status == s).length;

  /// Whether the currently selected date is cancelled
  bool get _selDateCancelled => _selDate != null && _isDateCancelled(_selDate!);
  ClassCancellation? get _selDateCancellation =>
      _selDate != null ? _getCancellation(_selDate!) : null;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (ctx, prov, _) => Container(
        color: _bg,
        child: Row(
          children: [
            _leftPanel(prov),
            Container(width: 1, color: _bd),
            Expanded(child: _rightPanel(prov)),
          ],
        ),
      ),
    );
  }

  Widget _leftPanel(AdminProvider p) {
    return Container(
      width: 300,
      color: _sf,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track by subject & schedule',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _bd),

          // ── Subject Picker ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBJECT',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _bd),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Subject>(
                      value: _subj != null && p.subjects.contains(_subj) ? _subj : null,
                      isExpanded: true,
                      dropdownColor: _sf,
                      iconEnabledColor: const Color(0xFF4B5E78),
                      hint: Text(
                        'Select subject',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF4B5E78),
                          fontSize: 12,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      onChanged: (s) => _onSubj(s, p),
                      items: p.subjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${s.subjectCode} - ${s.subjectTitle}',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${scheduleDayLabel(s.scheduleDay)} • ${s.room}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF4B5E78),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                if (_subj != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _ac.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _ac.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.schedule_rounded, color: _ac, size: 13),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                scheduleDayLabel(_subj!.scheduleDay),
                                style: GoogleFonts.inter(
                                  color: _ac,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subj!.formattedTimeRange,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF8B9AB2),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Section Filter (Phase 1.2) ──
          if (_roster.isNotEmpty) ...[
            Container(
              height: 1,
              color: _bd,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECTION FILTER',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4B5E78),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _bd),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSection ?? 'All',
                        isExpanded: true,
                        dropdownColor: _sf,
                        iconEnabledColor: const Color(0xFF4B5E78),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        onChanged: (v) => setState(
                          () => _selectedSection = (v == 'All') ? null : v,
                        ),
                        items: ['All', ..._sectionOptions]
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    color: s == 'All'
                                        ? const Color(0xFF4B5E78)
                                        : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  if (_selectedSection != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${_filteredRoster.length} student${_filteredRoster.length == 1 ? '' : 's'} in section',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF4B5E78),
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          Container(
            height: 1,
            color: _bd,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // ── Date Range ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATE RANGE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _drBtn('From', _rStart, (d) {
                        setState(() => _rStart = d);
                        _calcDates();
                      }),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _drBtn('To', _rEnd, (d) {
                        setState(() => _rEnd = d);
                        _calcDates();
                      }),
                    ),
                  ],
                ),
                if (_dates.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${_dates.length} class dates found',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4B5E78),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            height: 1,
            color: _bd,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              'CLASS DATES',
              style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // ── Date List ──
          if (_semesterStatus != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _semesterStatus!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _dates.isEmpty
                ? Center(
                    child: Text(
                      _subj == null
                          ? 'Select a subject'
                          : (_semesterStatus != null
                                ? _semesterStatus!
                                : 'No dates in range'),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2E3D54),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _dates.length,
                    itemBuilder: (_, i) => _dItem(p, _dates[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dItem(AdminProvider p, DateTime d) {
    final sel =
        _selDate != null &&
        d.year == _selDate!.year &&
        d.month == _selDate!.month &&
        d.day == _selDate!.day;
    final now = DateTime.now();
    final today =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final cancelled = _isDateCancelled(d);
    final cancellation = _getCancellation(d);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () {
            setState(() => _selDate = d);
            _load(p);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? (cancelled
                        ? const Color(0xFF64748B).withValues(alpha: 0.15)
                        : _ac.withValues(alpha: 0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: sel
                    ? (cancelled
                          ? const Color(0xFF64748B).withValues(alpha: 0.35)
                          : _ac.withValues(alpha: 0.3))
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('MMM dd').format(d),
                  style: GoogleFonts.inter(
                    color: cancelled
                        ? const Color(0xFF64748B)
                        : (sel ? Colors.white : const Color(0xFF8B9AB2)),
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE').format(d),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78),
                    fontSize: 10,
                  ),
                ),
                if (_config != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _ac.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      GradingConfig.termLabel(_config!.termForDate(d)),
                      style: GoogleFonts.inter(
                        color: _ac,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (cancelled) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _cancelledReasonColor(
                        cancellation!.reason,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _cancelledReasonShort(cancellation.reason),
                      style: GoogleFonts.inter(
                        color: _cancelledReasonColor(cancellation.reason),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else if (today) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drBtn(String lbl, DateTime dt, void Function(DateTime) cb) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: dt,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
          builder: (c, ch) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _ac,
                surface: Color(0xFF1A2235),
              ),
            ),
            child: ch!,
          ),
        );
        if (d != null) cb(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _bd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lbl,
              style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              DateFormat('MMM yyyy').format(dt),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _cancelledReasonColor(String reason) {
    switch (reason) {
      case 'no_class':
        return const Color(0xFF64748B);
      case 'holiday':
        return const Color(0xFF0EA5E9);
      case 'suspended':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _cancelledReasonShort(String reason) {
    switch (reason) {
      case 'no_class':
        return 'NO CLASS';
      case 'holiday':
        return 'HOLIDAY';
      case 'suspended':
        return 'SUSPENDED';
      default:
        return reason.toUpperCase();
    }
  }

  IconData _cancelledReasonIcon(String reason) {
    switch (reason) {
      case 'no_class':
        return Icons.person_off_rounded;
      case 'holiday':
        return Icons.celebration_rounded;
      case 'suspended':
        return Icons.block_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }

  Future<void> _markDayCancelled(AdminProvider p, String reason) async {
    if (_subj?.id == null || _selDate == null) return;
    setState(() => _cancelLoading = true);
    try {
      await p.markClassCancelled(
        subjectId: _subj!.id!,
        date: _selDate!,
        reason: reason,
      );
      await _loadCancellations();
      await _load(p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
    if (mounted) setState(() => _cancelLoading = false);
  }

  Future<void> _restoreDay(AdminProvider p) async {
    if (_subj?.id == null || _selDate == null) return;
    setState(() => _cancelLoading = true);
    try {
      await p.restoreClassDay(subjectId: _subj!.id!, date: _selDate!);
      await _loadCancellations();
      await _load(p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
    if (mounted) setState(() => _cancelLoading = false);
  }

  Widget _rightPanel(AdminProvider p) {
    final grp = _grp;
    final pr = _cnt('present');
    final lt = _cnt('late');
    final ab = _cnt('absent');
    final ex = _cnt('excused');
    final total = _filteredRoster.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats bar
        if (_roster.isNotEmpty || _selDateCancelled)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _bd)),
            ),
            child: Row(
              children: [
                if (_selDate != null)
                  Text(
                    '${DateFormat('EEEE, MMM dd yyyy').format(_selDate!)}${_config != null ? ' (${GradingConfig.termLabel(_config!.termForDate(_selDate!))})' : ''}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 16),
                if (!_selDateCancelled) ...[
                  _chip('Present', pr, const Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  _chip('Late', lt, const Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  _chip('Absent', ab, const Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  _chip('Excused', ex, const Color(0xFF818CF8)),
                ],
                const Spacer(),
                if (_selectedSection != null)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _ac.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _ac.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          color: _ac,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedSection!,
                          style: GoogleFonts.inter(
                            color: _ac,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Mark Day button (dropdown)
                if (_subj != null && _selDate != null && !_selDateCancelled)
                  _buildMarkDayButton(p),
                // Restore day button (if cancelled)
                if (_selDateCancelled) _buildRestoreDayButton(p),
                const SizedBox(width: 6),
                if (!_selDateCancelled)
                  Text(
                    '$total students',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4B5E78),
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _load(p),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _sf,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _bd),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF4B5E78),
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Cancellation banner
        if (_selDateCancelled) _buildCancellationBanner(),

        // Table header
        if (_subj != null && _selDate != null && !_loading)
          Container(
            margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _sf,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: _bd),
            ),
            child: Row(
              children: [
                _th('#', 1),
                _th('Student Name', 4),
                _th('USN', 2),
                _th('Section', 2),
                _th('Status', 2),
                _th('Scan Time', 2),
                _th('', 2),
              ],
            ),
          ),

        Expanded(
          child: _subj == null || _selDate == null
              ? _mt('Select a subject and date', Icons.fact_check_outlined)
              : _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _ac, strokeWidth: 2),
                )
              : _filteredRoster.isEmpty
              ? _mt('No records for this date', Icons.calendar_today_outlined)
              : Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: _bd),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    child: ListView(
                      children: [
                        for (final entry in grp.entries) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            color: _ac.withValues(alpha: 0.05),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_rounded,
                                  color: _ac,
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.key,
                                  style: GoogleFonts.inter(
                                    color: _ac,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${entry.value.length} students',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF4B5E78),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.asMap().entries.map(
                            (e) => AttendanceRow(
                              index: e.key + 1,
                              entry: e.value,
                              date: _selDate!,
                              statusColors: _sc,
                              classDates: _dates,
                              subject: _subj!,
                              onUpdated: (u) {
                                final i = _roster.indexWhere(
                                  (r) => r.enrollmentId == u.enrollmentId,
                                );
                                if (i != -1) setState(() => _roster[i] = u);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ), // closes ClipRRect + Container
        ), // closes Expanded
      ],
    );
  }

  Widget _chip(String l, int v, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$v $l',
          style: GoogleFonts.inter(
            color: c,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _th(String t, int f) => Expanded(
    flex: f,
    child: Text(
      t,
      style: GoogleFonts.inter(
        color: const Color(0xFF4B5E78),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _mt(String m, IconData i) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, color: const Color(0xFF2E3D54), size: 44),
        const SizedBox(height: 10),
        Text(
          m,
          style: GoogleFonts.inter(
            color: const Color(0xFF4B5E78),
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  // ── Mark Day as Cancelled (dropdown) ────────────────────────
  Widget _buildMarkDayButton(AdminProvider p) {
    return PopupMenuButton<String>(
      onSelected: (reason) => _markDayCancelled(p, reason),
      enabled: !_cancelLoading,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: _sf,
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'no_class',
          child: Row(
            children: [
              const Icon(
                Icons.person_off_rounded,
                color: Color(0xFF64748B),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'No Class (Instructor Leave)',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'holiday',
          child: Row(
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: Color(0xFF0EA5E9),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Holiday',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'suspended',
          child: Row(
            children: [
              const Icon(
                Icons.block_rounded,
                color: Color(0xFFF97316),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Class Suspended',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF97316).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cancelLoading
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      color: Color(0xFFF97316),
                      strokeWidth: 1.5,
                    ),
                  )
                : const Icon(
                    Icons.event_busy_rounded,
                    color: Color(0xFFF97316),
                    size: 13,
                  ),
            const SizedBox(width: 5),
            Text(
              'Mark Day',
              style: GoogleFonts.inter(
                color: const Color(0xFFF97316),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFFF97316),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── Restore Day (undo cancellation) ─────────────────────────
  Widget _buildRestoreDayButton(AdminProvider p) {
    return GestureDetector(
      onTap: _cancelLoading ? null : () => _restoreDay(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cancelLoading
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                      strokeWidth: 1.5,
                    ),
                  )
                : const Icon(
                    Icons.restore_rounded,
                    color: Color(0xFF10B981),
                    size: 13,
                  ),
            const SizedBox(width: 5),
            Text(
              'Restore Day',
              style: GoogleFonts.inter(
                color: const Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cancellation Banner ─────────────────────────────────────
  Widget _buildCancellationBanner() {
    final c = _selDateCancellation;
    if (c == null) return const SizedBox.shrink();
    final color = _cancelledReasonColor(c.reason);
    final icon = _cancelledReasonIcon(c.reason);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.reasonLabel,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All student attendance records for this date have been marked as "${_cancelledReasonShort(c.reason)}".\nStudents will not be penalized for this date.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                if (c.remarks != null && c.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${c.remarks}',
                    style: GoogleFonts.inter(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
