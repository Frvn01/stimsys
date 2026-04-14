import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';

class AttendanceTrackerScreen extends StatefulWidget {
  const AttendanceTrackerScreen({super.key});

  @override
  State<AttendanceTrackerScreen> createState() => _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  Subject? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _records = [];
  bool _isLoading = false;

  Future<void> _load(AdminProvider provider) async {
    if (_selectedSubject == null) return;
    setState(() => _isLoading = true);
    try {
      _records = await provider.getSubjectAttendance(_selectedSubject!.id!, date: _selectedDate);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final present = _records.where((r) => r.isPresent).length;
        final late = _records.where((r) => r.isLate).length;
        final absent = _records.where((r) => r.isAbsent).length;
        final total = _records.length;

        final lateRecords = _records.where((r) => r.isLate);
        final avgLate = lateRecords.isEmpty ? 0
            : (lateRecords.map((r) => r.minutesLate).reduce((a, b) => a + b) / lateRecords.length).round();

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E21),
          body: SafeArea(
            child: Column(children: [

              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Attendance Tracker', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Filter by subject and date', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 16),

                  // Subject picker
                  _DropdownField(
                    value: _selectedSubject,
                    hint: '— Select Subject —',
                    icon: Icons.book_rounded,
                    subjects: provider.subjects,
                    onChanged: (v) {
                      setState(() { _selectedSubject = v; _records = []; });
                      _load(provider);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1), surface: Color(0xFF111633)),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _load(provider);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111633),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 18),
                        const SizedBox(width: 10),
                        Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.unfold_more_rounded, color: Colors.grey[600], size: 18),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  if (total > 0) ...[
                    Row(children: [
                      _SmallStat(label: 'Present', count: present, total: total, color: const Color(0xFF10B981), icon: Icons.check_circle_rounded),
                      const SizedBox(width: 8),
                      _SmallStat(label: 'Late', count: late, total: total, color: const Color(0xFFF59E0B), icon: Icons.watch_later_rounded,
                        subtitle: late > 0 ? 'avg ${avgLate}m' : null),
                      const SizedBox(width: 8),
                      _SmallStat(label: 'Absent', count: absent, total: total, color: const Color(0xFFEF4444), icon: Icons.cancel_rounded),
                    ]),
                    const SizedBox(height: 14),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(children: [
                        _ProgressSegment(flex: present, color: const Color(0xFF10B981)),
                        _ProgressSegment(flex: late, color: const Color(0xFFF59E0B)),
                        _ProgressSegment(flex: absent, color: const Color(0xFFEF4444)),
                        if (total == 0) _ProgressSegment(flex: 1, color: Colors.grey[800]!),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ],
                ]),
              ),

              // ── Records list ──
              Expanded(child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _selectedSubject == null
                  ? _emptyState('Select a subject to view attendance', Icons.analytics_outlined)
                  : _records.isEmpty
                    ? _emptyState('No records for this date', Icons.sentiment_neutral_rounded)
                    : RefreshIndicator(
                        color: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF111633),
                        onRefresh: () => _load(provider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _RecordTile(record: _records[i]),
                        ),
                      ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.grey[700], size: 52),
      const SizedBox(height: 12),
      Text(msg, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13), textAlign: TextAlign.center),
    ]));
  }
}

class _DropdownField extends StatelessWidget {
  final Subject? value;
  final String hint;
  final IconData icon;
  final List<Subject> subjects;
  final ValueChanged<Subject?> onChanged;
  const _DropdownField({required this.value, required this.hint, required this.icon, required this.subjects, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111633),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value != null ? const Color(0xFF6366F1).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Subject>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2140),
          hint: Text(hint, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
          items: subjects.map((s) => DropdownMenuItem(
            value: s,
            child: Text('${s.subjectCode} — ${s.subjectTitle}',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  final IconData icon;
  final String? subtitle;
  const _SmallStat({required this.label, required this.count, required this.total, required this.color, required this.icon, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text('$count', style: GoogleFonts.inter(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600)),
        if (subtitle != null)
          Text(subtitle!, style: GoogleFonts.inter(color: color.withValues(alpha: 0.7), fontSize: 9)),
        const SizedBox(height: 4),
        Text('${(pct * 100).round()}%', style: GoogleFonts.inter(color: color.withValues(alpha: 0.6), fontSize: 10)),
      ]),
    ));
  }
}

class _ProgressSegment extends StatelessWidget {
  final int flex;
  final Color color;
  const _ProgressSegment({required this.flex, required this.color});

  @override
  Widget build(BuildContext context) {
    if (flex == 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Container(height: 6, color: color),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.isPresent ? const Color(0xFF10B981)
        : record.isLate ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final icon = record.isPresent ? Icons.check_circle_rounded
        : record.isLate ? Icons.watch_later_rounded
        : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111633),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.studentName ?? record.studentUsn ?? 'Student',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(record.remarks ?? record.statusLabel,
            style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(record.status.toUpperCase(),
              style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
          if (record.scannedAt != null) ...[
            const SizedBox(height: 4),
            Text(DateFormat('h:mm a').format(record.scannedAt!),
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10)),
          ],
        ]),
      ]),
    );
  }
}
