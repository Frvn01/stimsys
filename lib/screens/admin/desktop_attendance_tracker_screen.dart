import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/schedule_utils.dart';
import '../../core/supabase_config.dart';
import 'desktop_attendance_widgets.dart';
import 'student_attendance_detail_screen.dart';

class DesktopAttendanceTrackerScreen extends StatefulWidget {
  const DesktopAttendanceTrackerScreen({super.key});
  @override
  State<DesktopAttendanceTrackerScreen> createState() => _State();
}

class _State extends State<DesktopAttendanceTrackerScreen> {
  Subject? _subj;
  DateTime? _selDate;
  DateTime _rStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rEnd   = DateTime(DateTime.now().year, DateTime.now().month + 4, 0);
  List<RosterEntry> _roster = [];
  List<DateTime>    _dates  = [];
  bool _loading = false;
  StreamSubscription? _rtSub;

  // Phase 1.2 — section filter
  String? _selectedSection; // null = All sections

  static const _bg = Color(0xFF0F172A);
  static const _sf = Color(0xFF1A2235);
  static const _bd = Color(0xFF232D3F);
  static const _ac = Color(0xFF6366F1);
  static const _sc = {
    'present': Color(0xFF10B981), 'late': Color(0xFFF59E0B),
    'absent':  Color(0xFFEF4444), 'excused': Color(0xFF818CF8),
  };

  @override
  void dispose() { _rtSub?.cancel(); super.dispose(); }

  void _onSubj(Subject? s, AdminProvider p) {
    setState(() { _subj = s; _selDate = null; _roster = []; _selectedSection = null; });
    _calcDates();
    _initRT();
  }

  void _calcDates() {
    if (_subj == null) { setState(() => _dates = []); return; }
    final d = getValidClassDates(_subj!, _rStart, _rEnd);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() { _dates = d; if (d.isNotEmpty) _selDate = d.contains(today) ? today : d.last; });
    if (_selDate != null) _load(context.read<AdminProvider>());
  }

  DateTime? _lastRTRefresh;

  void _initRT() {
    _rtSub?.cancel();
    if (_subj == null) return;
    _rtSub = SupabaseConfig.client.from('attendance').stream(primaryKey: ['id']).listen((_) {
      if (_loading || !mounted || _subj == null || _selDate == null) return;
      final now = DateTime.now();
      if (_lastRTRefresh != null && now.difference(_lastRTRefresh!).inSeconds < 2) return;
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
    return Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  int _cnt(String s) => _filteredRoster.where((e) => e.attendanceRecord?.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (ctx, prov, _) => Container(
      color: _bg,
      child: Row(children: [
        _leftPanel(prov),
        Container(width: 1, color: _bd),
        Expanded(child: _rightPanel(prov)),
      ]),
    ));
  }

  Widget _leftPanel(AdminProvider p) {
    return Container(width: 300, color: _sf, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attendance', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Track by subject & schedule', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 11)),
      ])),
      Container(height: 1, color: _bd),

      // ── Subject Picker ──
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SUBJECT', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bd)),
          child: DropdownButtonHideUnderline(child: DropdownButton<Subject>(
            value: _subj, isExpanded: true, dropdownColor: _sf, iconEnabledColor: const Color(0xFF4B5E78),
            hint: Text('Select subject', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 12)),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            onChanged: (s) => _onSubj(s, p),
            items: p.subjects.map((s) => DropdownMenuItem(
              value: s,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${s.subjectCode} - ${s.subjectTitle}', overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${scheduleDayLabel(s.scheduleDay)} • ${s.room}',
                    style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10)),
              ]),
            )).toList(),
          )),
        ),
        if (_subj != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: _ac.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              Icon(Icons.schedule_rounded, color: _ac, size: 13), const SizedBox(width: 6),
              Expanded(child: Text(scheduleDayLabel(_subj!.scheduleDay),
                  style: GoogleFonts.inter(color: _ac, fontSize: 11, fontWeight: FontWeight.w600))),
              Text('${_subj!.scheduleStartTime}-${_subj!.scheduleEndTime}',
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10)),
            ]),
          ),
        ],
      ])),

      // ── Section Filter (Phase 1.2) ──
      if (_roster.isNotEmpty) ...[
        Container(height: 1, color: _bd, margin: const EdgeInsets.symmetric(horizontal: 16)),
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SECTION FILTER', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _bd)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _selectedSection ?? 'All',
              isExpanded: true,
              dropdownColor: _sf,
              iconEnabledColor: const Color(0xFF4B5E78),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              onChanged: (v) => setState(() => _selectedSection = (v == 'All') ? null : v),
              items: ['All', ..._sectionOptions].map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: GoogleFonts.inter(
                    color: s == 'All' ? const Color(0xFF4B5E78) : Colors.white, fontSize: 12)),
              )).toList(),
            )),
          ),
          if (_selectedSection != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${_filteredRoster.length} student${_filteredRoster.length == 1 ? '' : 's'} in section',
                style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10),
              ),
            ),
        ])),
      ],

      Container(height: 1, color: _bd, margin: const EdgeInsets.symmetric(horizontal: 16)),

      // ── Date Range ──
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DATE RANGE', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _drBtn('From', _rStart, (d) { setState(() => _rStart = d); _calcDates(); })),
          const SizedBox(width: 6),
          Expanded(child: _drBtn('To', _rEnd, (d) { setState(() => _rEnd = d); _calcDates(); })),
        ]),
        if (_dates.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6),
            child: Text('${_dates.length} class dates found', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10))),
      ])),

      Container(height: 1, color: _bd, margin: const EdgeInsets.symmetric(horizontal: 16)),
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Text('CLASS DATES', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8))),

      // ── Date List ──
      Expanded(child: _dates.isEmpty
        ? Center(child: Text(
            _subj == null ? 'Select a subject' : 'No dates in range',
            style: GoogleFonts.inter(color: const Color(0xFF2E3D54), fontSize: 12)))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _dates.length,
            itemBuilder: (_, i) => _dItem(p, _dates[i]))),
    ]));
  }

  Widget _dItem(AdminProvider p, DateTime d) {
    final sel = _selDate != null && d.year == _selDate!.year && d.month == _selDate!.month && d.day == _selDate!.day;
    final now = DateTime.now();
    final today = d.year == now.year && d.month == now.month && d.day == now.day;
    return Padding(padding: const EdgeInsets.only(bottom: 2),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(7),
        child: InkWell(borderRadius: BorderRadius.circular(7),
          onTap: () { setState(() => _selDate = d); _load(p); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _ac.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: sel ? _ac.withValues(alpha: 0.3) : Colors.transparent)),
            child: Row(children: [
              Text(DateFormat('MMM dd').format(d),
                  style: GoogleFonts.inter(
                      color: sel ? Colors.white : const Color(0xFF8B9AB2),
                      fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
              const SizedBox(width: 6),
              Text(DateFormat('EEE').format(d),
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10)),
              if (today) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text('Today', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w700))),
              ],
            ]),
          ))));
  }

  Widget _drBtn(String lbl, DateTime dt, void Function(DateTime) cb) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context, initialDate: dt, firstDate: DateTime(2024), lastDate: DateTime(2030),
          builder: (c, ch) => Theme(
            data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _ac, surface: Color(0xFF1A2235))),
            child: ch!));
        if (d != null) cb(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _bd)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lbl, style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 9, fontWeight: FontWeight.w600)),
          Text(DateFormat('MMM yyyy').format(dt), style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
    );
  }

  Widget _rightPanel(AdminProvider p) {
    final grp = _grp;
    final pr = _cnt('present'); final lt = _cnt('late');
    final ab = _cnt('absent'); final ex = _cnt('excused');
    final total = _filteredRoster.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Stats bar
      if (_roster.isNotEmpty)
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _bd))),
          child: Row(children: [
            if (_selDate != null)
              Text(DateFormat('EEEE, MMM dd yyyy').format(_selDate!),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
            _chip('Present', pr, const Color(0xFF10B981)), const SizedBox(width: 6),
            _chip('Late', lt, const Color(0xFFF59E0B)), const SizedBox(width: 6),
            _chip('Absent', ab, const Color(0xFFEF4444)), const SizedBox(width: 6),
            _chip('Excused', ex, const Color(0xFF818CF8)),
            const Spacer(),
            if (_selectedSection != null)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _ac.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _ac.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.filter_list_rounded, color: _ac, size: 13),
                  const SizedBox(width: 4),
                  Text(_selectedSection!, style: GoogleFonts.inter(color: _ac, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            Text('$total students', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 11)),
            const SizedBox(width: 10),
            Material(color: Colors.transparent, borderRadius: BorderRadius.circular(6),
              child: InkWell(borderRadius: BorderRadius.circular(6), onTap: () => _load(p),
                child: Container(padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _sf, borderRadius: BorderRadius.circular(6), border: Border.all(color: _bd)),
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFF4B5E78), size: 15)))),
          ]),
        ),

      // Table header
      if (_subj != null && _selDate != null && !_loading)
        Container(
          margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _sf,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: _bd)),
          child: Row(children: [
            _th('#', 1), _th('Student Name', 4), _th('USN', 2),
            _th('Section', 2), _th('Status', 2), _th('Scan Time', 2), _th('', 2),
          ]),
        ),

      Expanded(child: _subj == null || _selDate == null
        ? _mt('Select a subject and date', Icons.fact_check_outlined)
        : _loading
          ? const Center(child: CircularProgressIndicator(color: _ac, strokeWidth: 2))
          : _filteredRoster.isEmpty
            ? _mt('No records for this date', Icons.calendar_today_outlined)
            : Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                decoration: BoxDecoration(
                  border: Border.all(color: _bd),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  child: ListView(children: [
                    for (final entry in grp.entries) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        color: _ac.withValues(alpha: 0.05),
                        child: Row(children: [
                          Icon(Icons.folder_rounded, color: _ac, size: 13),
                          const SizedBox(width: 6),
                          Text(entry.key, style: GoogleFonts.inter(color: _ac, fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text('${entry.value.length} students', style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10)),
                        ]),
                      ),
                      ...entry.value.asMap().entries.map((e) => AttendanceRow(
                        index: e.key + 1,
                        entry: e.value,
                        date: _selDate!,
                        statusColors: _sc,
                        classDates: _dates,
                        subject: _subj!,
                        onUpdated: (u) {
                          final i = _roster.indexWhere((r) => r.enrollmentId == u.enrollmentId);
                          if (i != -1) setState(() => _roster[i] = u);
                        },
                      )),
                    ],
                  ]),
                 )),       // closes ClipRRect + Container
      ),                   // closes Expanded
    ]);
  }

  Widget _chip(String l, int v, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('$v $l', style: GoogleFonts.inter(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  Widget _th(String t, int f) => Expanded(
    flex: f,
    child: Text(t, style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)));

  Widget _mt(String m, IconData i) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(i, color: const Color(0xFF2E3D54), size: 44),
    const SizedBox(height: 10),
    Text(m, style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 13)),
  ]));
}
