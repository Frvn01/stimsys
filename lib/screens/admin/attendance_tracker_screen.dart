import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';
import '../../services/supabase_service.dart';

class AttendanceTrackerScreen extends StatefulWidget {
  const AttendanceTrackerScreen({super.key});
  @override
  State<AttendanceTrackerScreen> createState() => _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  Subject? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  List<RosterEntry> _roster = [];
  bool _isLoading = false;

  static const _statusColors = {
    'present': Color(0xFF10B981),
    'late':    Color(0xFFF59E0B),
    'absent':  Color(0xFFEF4444),
    'excused': Color(0xFF818CF8),
  };
  static const _statusIcons = {
    'present': Icons.check_circle_rounded,
    'late':    Icons.watch_later_rounded,
    'absent':  Icons.cancel_rounded,
    'excused': Icons.remove_circle_rounded,
  };

  Future<void> _load(AdminProvider p) async {
    if (_selectedSubject == null) return;
    setState(() => _isLoading = true);
    _roster = await p.getSubjectRoster(_selectedSubject!.id!, date: _selectedDate);
    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, List<RosterEntry>> get _grouped {
    final Map<String, List<RosterEntry>> m = {};
    for (final e in _roster) {
      final key = e.sectionLabel.isEmpty ? 'Unknown Section' : e.sectionLabel;
      m.putIfAbsent(key, () => []).add(e);
    }
    return Map.fromEntries(m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  int _count(String status) => _roster.where((e) => e.attendanceRecord?.status == status).length;

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1), surface: Color(0xFF111633))),
        child: child!,
      ),
    );
    if (p != null) { setState(() => _selectedDate = p); _load(context.read<AdminProvider>()); }
  }

  void _showEditSheet(RosterEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditStatusSheet(
        entry: entry,
        date: _selectedDate,
        onSaved: (updated) {
          final idx = _roster.indexWhere((e) => e.enrollmentId == entry.enrollmentId);
          if (idx != -1) setState(() => _roster[idx] = updated);
        },
      ),
    );
  }

  void _showSubjectQR(Subject s) {
    final qrData = 'STIMSYSENROLL|${s.id}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF111633), borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.subjectTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            Text(s.subjectCode, style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: qrData, version: QrVersions.auto, size: 200, backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.H)),
            const SizedBox(height: 16),
            Text('Students scan to self-enroll', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('STIMSYSENROLL | ${s.subjectCode}', style: GoogleFonts.robotoMono(color: Colors.grey[600], fontSize: 10)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.w600)))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, provider, _) {
      final present = _count('present'), late = _count('late'),
            absent = _count('absent'), excused = _count('excused');
      final total = _roster.length;

      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: SafeArea(child: Column(children: [

          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1226),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Attendance Tracker', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('Spreadsheet view by section', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                ])),
                if (_selectedSubject != null)
                  GestureDetector(
                    onTap: () => _showSubjectQR(_selectedSubject!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.qr_code_rounded, color: Color(0xFF6366F1), size: 16),
                        const SizedBox(width: 6),
                        Text('Enroll QR', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),

              // Subject picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111633),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedSubject != null
                      ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Subject>(
                    value: _selectedSubject != null && provider.subjects.contains(_selectedSubject)
                        ? _selectedSubject
                        : null,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A2140),
                    hint: Text('— Select Subject —', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
                    items: provider.subjects.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.subjectCode} — ${s.subjectTitle}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) { setState(() { _selectedSubject = v; _roster = []; }); _load(provider); },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Date picker row
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF111633), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                        const Spacer(),
                        Icon(Icons.unfold_more_rounded, color: Colors.grey[600], size: 16),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _load(provider),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3))),
                    child: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1), size: 18),
                  ),
                ),
              ]),

              // Stats
              if (total > 0) ...[
                const SizedBox(height: 12),
                Row(children: [
                  _StatChip('P', present, total, const Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  _StatChip('L', late, total, const Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  _StatChip('A', absent, total, const Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  _StatChip('E', excused, total, const Color(0xFF818CF8)),
                  const Spacer(),
                  Text('$total students', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                ]),
              ],
            ]),
          ),

          // ── Body ──
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : _selectedSubject == null
              ? _empty('Select a subject to view roster', Icons.analytics_outlined)
              : _roster.isEmpty
                ? _empty('No students enrolled in this subject', Icons.people_outline)
                : _buildSpreadsheet(),
          ),
        ])),
      );
    });
  }

  Widget _buildSpreadsheet() {
    final groups = _grouped;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final entry in groups.entries) ...[
          _SectionHeader(label: entry.key, count: entry.value.length),
          const SizedBox(height: 8),
          // Table header
          _TableHeaderRow(),
          const SizedBox(height: 4),
          ...entry.value.map((r) => _StudentRow(
            entry: r,
            statusColors: _statusColors,
            statusIcons: _statusIcons,
            onTap: () => _showEditSheet(r),
          )),
          const SizedBox(height: 20),
        ],
      ]),
    );
  }

  Widget _empty(String msg, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: Colors.grey[700], size: 52),
    const SizedBox(height: 12),
    Text(msg, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13), textAlign: TextAlign.center),
  ]));
}

// ── Section Header ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF1A1060), Color(0xFF111633)]),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
        child: Text('$count students', style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

// ── Table Header Row ────────────────────────────────────────
class _TableHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(children: [
      Expanded(flex: 5, child: Text('Student', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      Expanded(flex: 3, child: Text('USN', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
      SizedBox(width: 80, child: Center(child: Text('STATUS', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)))),
    ]),
  );
}

// ── Student Row ─────────────────────────────────────────────
class _StudentRow extends StatelessWidget {
  final RosterEntry entry;
  final Map<String, Color> statusColors;
  final Map<String, IconData> statusIcons;
  final VoidCallback onTap;
  const _StudentRow({required this.entry, required this.statusColors, required this.statusIcons, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rec = entry.attendanceRecord;
    final status = rec?.status;
    final color = status != null ? (statusColors[status] ?? Colors.grey) : Colors.grey[700]!;
    final icon = status != null ? (statusIcons[status] ?? Icons.remove_rounded) : Icons.remove_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: status != null ? color.withValues(alpha: 0.05) : const Color(0xFF111633),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: status != null ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(children: [
          Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entry.lastName}, ${entry.firstName}',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
            if (rec?.remarks != null && status != null)
              Text(rec!.remarks!, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10), overflow: TextOverflow.ellipsis),
          ])),
          Expanded(flex: 3, child: Text(entry.usn, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500))),
          SizedBox(width: 80, child: Center(child: status == null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, color: Colors.grey[500], size: 11),
                  const SizedBox(width: 4),
                  Text('SET', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ]),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: color, size: 11),
                  const SizedBox(width: 4),
                  Text(status.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ]),
              ),
          )),
        ]),
      ),
    );
  }
}

// ── Stat Chip ───────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _StatChip(this.label, this.count, this.total, this.color);
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Text('$label: $count ($pct%)', style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Edit Status Bottom Sheet ────────────────────────────────
class _EditStatusSheet extends StatefulWidget {
  final RosterEntry entry;
  final DateTime date;
  final ValueChanged<RosterEntry> onSaved;
  const _EditStatusSheet({required this.entry, required this.date, required this.onSaved});
  @override
  State<_EditStatusSheet> createState() => _EditStatusSheetState();
}

class _EditStatusSheetState extends State<_EditStatusSheet> {
  String _selected = '';
  bool _saving = false;
  final _remarksCtrl = TextEditingController();

  static const _options = [
    ('present', 'Present',  Color(0xFF10B981), Icons.check_circle_rounded),
    ('late',    'Late',     Color(0xFFF59E0B), Icons.watch_later_rounded),
    ('absent',  'Absent',   Color(0xFFEF4444), Icons.cancel_rounded),
    ('excused', 'Excused',  Color(0xFF818CF8), Icons.remove_circle_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.entry.attendanceRecord?.status ?? '';
    _remarksCtrl.text = widget.entry.attendanceRecord?.remarks ?? '';
  }

  @override
  void dispose() { _remarksCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    final provider = context.read<AdminProvider>();
    final entry = widget.entry;
    final remarks = _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim();
    try {
      if (entry.attendanceRecord?.id != null) {
        await provider.updateAttendanceStatus(entry.attendanceRecord!.id!, _selected, remarks: remarks);
        final updated = RosterEntry(
          enrollmentId: entry.enrollmentId, studentId: entry.studentId,
          lastName: entry.lastName, firstName: entry.firstName,
          usn: entry.usn, course: entry.course,
          yearLevel: entry.yearLevel, section: entry.section,
          attendanceRecord: AttendanceRecord(
            id: entry.attendanceRecord!.id, enrollmentId: entry.enrollmentId,
            date: entry.attendanceRecord!.date, status: _selected,
            minutesLate: entry.attendanceRecord!.minutesLate, remarks: remarks,
            studentName: entry.fullName, studentUsn: entry.usn,
          ),
        );
        widget.onSaved(updated);
      } else {
        final rec = await provider.createManualAttendance(
          enrollmentId: entry.enrollmentId, status: _selected,
          date: widget.date, remarks: remarks,
        );
        if (rec != null) {
          final updated = RosterEntry(
            enrollmentId: entry.enrollmentId, studentId: entry.studentId,
            lastName: entry.lastName, firstName: entry.firstName,
            usn: entry.usn, course: entry.course,
            yearLevel: entry.yearLevel, section: entry.section,
            attendanceRecord: rec,
          );
          widget.onSaved(updated);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Color(0xFF111633), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        Text('Edit Attendance', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${widget.entry.lastName}, ${widget.entry.firstName} • ${widget.entry.usn}',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 18),

        // Status options
        Row(children: _options.map(((String s, String l, Color c, IconData i) opt) {
          final isSelected = _selected == opt.$1;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: opt.$1 != 'excused' ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selected = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? opt.$3.withValues(alpha: 0.18) : const Color(0xFF0D1226),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? opt.$3 : Colors.white.withValues(alpha: 0.06), width: isSelected ? 1.5 : 1),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(opt.$4, color: isSelected ? opt.$3 : Colors.grey[700], size: 22),
                  const SizedBox(height: 6),
                  Text(opt.$2, style: GoogleFonts.inter(color: isSelected ? opt.$3 : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ));
        }).toList()),

        const SizedBox(height: 14),
        TextField(
          controller: _remarksCtrl,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Remarks (optional)',
            labelStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
            filled: true, fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: (_selected.isEmpty || _saving) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              disabledBackgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          )),
      ]),
    );
  }
}
