import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/student_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Student Registry — no camera/QR scanner, clean table layout
// ─────────────────────────────────────────────────────────────────────────────

class DesktopStudentRegistryScreen extends StatefulWidget {
  const DesktopStudentRegistryScreen({super.key});
  @override
  State<DesktopStudentRegistryScreen> createState() =>
      _DesktopStudentRegistryScreenState();
}

class _DesktopStudentRegistryScreenState
    extends State<DesktopStudentRegistryScreen> {
  String _searchQuery = '';
  String _filterCourse = 'All';
  String _filterStatus = 'All'; // All | Confirmed | Pending

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _accent  = Color(0xFF6366F1);
  static const _green   = Color(0xFF10B981);
  static const _amber   = Color(0xFFF59E0B);
  static const _red     = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        var students = provider.students;

        if (_filterCourse != 'All') {
          students = students.where((s) => s.course == _filterCourse).toList();
        }
        if (_filterStatus == 'Confirmed') {
          students = students.where((s) => s.isConfirmed).toList();
        } else if (_filterStatus == 'Pending') {
          students = students.where((s) => !s.isConfirmed).toList();
        }
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          students = students.where((s) =>
              s.fullName.toLowerCase().contains(q) ||
              s.usn.contains(q)).toList();
        }

        final confirmed = provider.confirmedStudents;
        final pending   = provider.totalStudents - confirmed;

        return Container(
          color: _bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                color: _bg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student Registry',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                              '${provider.totalStudents} registered  •  $confirmed confirmed  •  $pending pending',
                              style: GoogleFonts.inter(
                                  color: Colors.grey[500], fontSize: 13)),
                        ],
                      )),
                      // Stats chips
                      _chip('Confirmed', '$confirmed', _green),
                      const SizedBox(width: 8),
                      _chip('Pending', '$pending', _amber),
                    ]),

                    const SizedBox(height: 20),

                    // Search + filters row
                    Row(children: [
                      // Search
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: TextField(
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search by name or USN...',
                              hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[600], fontSize: 13),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.grey[600], size: 18),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status filter
                      _dropdownFilter<String>(
                        value: _filterStatus,
                        items: ['All', 'Confirmed', 'Pending'],
                        label: 'Status',
                        onChanged: (v) =>
                            setState(() => _filterStatus = v ?? 'All'),
                      ),
                      const SizedBox(width: 8),
                      // Course filter
                      _dropdownFilter<String>(
                        value: _filterCourse,
                        items: ['All', ...StudentConstants.courses],
                        label: 'Course',
                        onChanged: (v) =>
                            setState(() => _filterCourse = v ?? 'All'),
                      ),
                      const SizedBox(width: 8),
                      // Refresh
                      _iconBtn(Icons.refresh_rounded,
                          () => provider.loadStudents()),
                    ]),

                    const SizedBox(height: 16),

                    // ── Table header ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        border: Border.all(color: _border),
                      ),
                      child: Row(children: [
                        _th('Student', flex: 3),
                        _th('USN', flex: 2),
                        _th('Course / Section', flex: 2),
                        _th('Status', flex: 1),
                        _th('Actions', flex: 1, align: TextAlign.right),
                      ]),
                    ),
                  ],
                ),
              ),

              // ── Table body ─────────────────────────────────────────────
              Expanded(
                child: students.isEmpty
                    ? _emptyState()
                    : Container(
                        margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: _border),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10)),
                          child: ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: _border),
                            itemBuilder: (_, i) => _DesktopStudentRow(
                              student: students[i],
                              onConfirm: () =>
                                  provider.confirmStudent(students[i].id!),
                              onDelete: () =>
                                  _confirmDelete(context, provider, students[i]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _th(String label,
      {int flex = 1, TextAlign align = TextAlign.left}) =>
      Expanded(
        flex: flex,
        child: Text(label,
            textAlign: align,
            style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  Widget _chip(String label, String value, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$value $label',
              style: GoogleFonts.inter(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _dropdownFilter<T>({
    required T value,
    required List<T> items,
    required String label,
    required void Function(T?) onChanged,
  }) =>
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            onChanged: onChanged,
            dropdownColor: _surface,
            iconEnabledColor: Colors.grey[500],
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            items: items
                .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.toString())))
                .toList(),
          ),
        ),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: Colors.grey[500], size: 18),
          ),
        ),
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, color: Colors.grey[700], size: 48),
          const SizedBox(height: 12),
          Text('No students found',
              style: GoogleFonts.inter(
                  color: Colors.grey[600], fontSize: 14)),
        ]),
      );

  void _confirmDelete(
      BuildContext context, AdminProvider provider, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Student',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
            'Remove ${student.fullName} (${student.usn})? This cannot be undone.',
            style: GoogleFonts.inter(
                color: Colors.grey[400], fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              provider.deleteStudent(student.id!);
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Desktop Student Row ────────────────────────────────────────────────────────
class _DesktopStudentRow extends StatefulWidget {
  final Student student;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;
  const _DesktopStudentRow({
    required this.student,
    required this.onConfirm,
    required this.onDelete,
  });
  @override
  State<_DesktopStudentRow> createState() => _DesktopStudentRowState();
}

class _DesktopStudentRowState extends State<_DesktopStudentRow> {
  bool _hovered = false;
  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _green   = Color(0xFF10B981);
  static const _amber   = Color(0xFFF59E0B);
  static const _accent  = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final isConfirmed = s.isConfirmed;
    final statusColor = isConfirmed ? _green : _amber;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? const Color(0xFF273548) : _surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Avatar + Name
          Expanded(flex: 3, child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(s.firstName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                        color: _accent, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(s.phone ?? '',
                    style: GoogleFonts.inter(
                        color: Colors.grey[600], fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
          ])),
          // USN
          Expanded(flex: 2, child: Text(s.usn,
              style: GoogleFonts.robotoMono(
                  color: Colors.grey[400], fontSize: 12))),
          // Course / Section
          Expanded(flex: 2, child: Text(
              '${s.course}  ${s.yearSection}',
              style: GoogleFonts.inter(
                  color: Colors.grey[400], fontSize: 12))),
          // Status badge
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isConfirmed ? 'Confirmed' : 'Pending',
              style: GoogleFonts.inter(
                  color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          )),
          // Actions
          Expanded(flex: 1, child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isConfirmed) ...[
                _actionBtn(Icons.check_rounded, _green, widget.onConfirm,
                    tooltip: 'Confirm'),
                const SizedBox(width: 6),
              ],
              _actionBtn(Icons.delete_outline_rounded,
                  const Color(0xFFEF4444), widget.onDelete,
                  tooltip: 'Delete'),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap,
          {required String tooltip}) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
          ),
        ),
      );
}
