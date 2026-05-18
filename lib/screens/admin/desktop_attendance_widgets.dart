import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/attendance_model.dart';
import '../../models/subject_model.dart';
import '../../services/supabase_service.dart';
import 'student_attendance_detail_screen.dart';

class AttendanceRow extends StatefulWidget {
  final int index;
  final RosterEntry entry;
  final DateTime date;
  final Map<String, Color> statusColors;
  final void Function(RosterEntry) onUpdated;
  // Phase 1.2 — needed for detail screen
  final List<DateTime> classDates;
  final Subject subject;

  const AttendanceRow({
    super.key,
    required this.index,
    required this.entry,
    required this.date,
    required this.statusColors,
    required this.onUpdated,
    required this.classDates,
    required this.subject,
  });

  @override
  State<AttendanceRow> createState() => _AttendanceRowState();
}

class _AttendanceRowState extends State<AttendanceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final rec = e.attendanceRecord;
    final status = rec?.status ?? 'absent';
    final color = widget.statusColors[status] ?? Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? const Color(0xFF1E2D42) : const Color(0xFF1A2235),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              // #
              Expanded(flex: 1, child: Text('${widget.index}',
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 11))),
              // Name
              Expanded(flex: 4, child: Text(e.fullName,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
              // USN
              Expanded(flex: 2, child: Text(e.usn,
                  style: GoogleFonts.robotoMono(color: const Color(0xFF4B5E78), fontSize: 10),
                  overflow: TextOverflow.ellipsis)),
              // Section
              Expanded(flex: 2, child: Text(e.sectionLabel,
                  style: GoogleFonts.inter(color: const Color(0xFF8B9AB2), fontSize: 11))),
              // Status badge
              Expanded(flex: 2, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(5)),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              )),
              // Scan time
              Expanded(flex: 2, child: Text(
                rec?.scannedAt != null
                    ? DateFormat('hh:mm a').format(rec!.scannedAt!.toLocal())
                    : '—',
                style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 11),
              )),
              // Actions (edit + detail)
              Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                // View full detail
                Tooltip(
                  message: 'View Attendance History',
                  child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () => _openDetail(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5)),
                        child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF6366F1), size: 13)))),
                ),
                const SizedBox(width: 4),
                // Edit
                Tooltip(
                  message: 'Edit Status',
                  child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () => _showEdit(context),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF232D3F),
                          borderRadius: BorderRadius.circular(5)),
                        child: const Icon(Icons.edit_rounded, color: Color(0xFF4B5E78), size: 13)))),
                ),
              ])),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF232D3F)),
        ]),
      ),
    );
  }

  void _openDetail(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => StudentAttendanceDetailScreen(
        entry: widget.entry,
        subjectTitle: widget.subject.subjectTitle,
        subjectCode: widget.subject.subjectCode,
        classDates: widget.classDates,
      ),
    ));
  }

  void _showEdit(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => EditAttendanceDialog(
      entry: widget.entry, date: widget.date,
      statusColors: widget.statusColors, onSaved: widget.onUpdated,
    ));
  }
}

// ─── Edit Dialog ──────────────────────────────────────────────────────────────

class EditAttendanceDialog extends StatefulWidget {
  final RosterEntry entry;
  final DateTime date;
  final Map<String, Color> statusColors;
  final void Function(RosterEntry) onSaved;
  const EditAttendanceDialog({
    super.key,
    required this.entry,
    required this.date,
    required this.statusColors,
    required this.onSaved,
  });
  @override
  State<EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<EditAttendanceDialog> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.entry.attendanceRecord?.status ?? 'absent';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF232D3F))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit Attendance',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.entry.fullName,
              style: GoogleFonts.inter(color: const Color(0xFF8B9AB2), fontSize: 12)),
          Text('USN: ${widget.entry.usn}',
              style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10)),
          const SizedBox(height: 18),
          Row(children: ['present', 'late', 'absent', 'excused'].map((s) {
            final color = widget.statusColors[s] ?? Colors.grey;
            final sel = _status == s;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => setState(() => _status = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: sel ? color : const Color(0xFF232D3F), width: sel ? 1.5 : 1)),
                  child: Text(s[0].toUpperCase() + s.substring(1),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: sel ? color : const Color(0xFF4B5E78),
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF4B5E78)))),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))),
              child: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<AdminProvider>();
    try {
      RosterEntry updated;
      if (widget.entry.attendanceRecord != null) {
        await provider.updateAttendanceStatus(widget.entry.attendanceRecord!.id!, _status);
        final oldRec = widget.entry.attendanceRecord!;
        final newRec = AttendanceRecord(
          id: oldRec.id, enrollmentId: oldRec.enrollmentId, date: oldRec.date,
          status: _status, scannedAt: oldRec.scannedAt,
          minutesLate: oldRec.minutesLate, markedAt: DateTime.now(),
          studentName: widget.entry.fullName, studentUsn: widget.entry.usn,
        );
        updated = RosterEntry(
          enrollmentId: widget.entry.enrollmentId, studentId: widget.entry.studentId,
          lastName: widget.entry.lastName, firstName: widget.entry.firstName,
          usn: widget.entry.usn, course: widget.entry.course,
          yearLevel: widget.entry.yearLevel, section: widget.entry.section,
          attendanceRecord: newRec,
        );
      } else {
        final newRec = await provider.createManualAttendance(
            enrollmentId: widget.entry.enrollmentId, date: widget.date, status: _status);
        updated = RosterEntry(
          enrollmentId: widget.entry.enrollmentId, studentId: widget.entry.studentId,
          lastName: widget.entry.lastName, firstName: widget.entry.firstName,
          usn: widget.entry.usn, course: widget.entry.course,
          yearLevel: widget.entry.yearLevel, section: widget.entry.section,
          attendanceRecord: newRec,
        );
      }
      if (mounted) { widget.onSaved(updated); Navigator.pop(context); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
      setState(() => _saving = false);
    }
  }
}
