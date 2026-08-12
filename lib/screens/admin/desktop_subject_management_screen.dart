import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/grading_config_model.dart';
import '../../services/supabase_service.dart';

class DesktopSubjectManagementScreen extends StatefulWidget {
  const DesktopSubjectManagementScreen({super.key});
  @override
  State<DesktopSubjectManagementScreen> createState() =>
      _DesktopSubjectManagementScreenState();
}

class _DesktopSubjectManagementScreenState
    extends State<DesktopSubjectManagementScreen> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) => Container(
        color: _bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Management',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.totalSubjects} subject${provider.totalSubjects != 1 ? 's' : ''} created',
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh
                  _iconBtn(
                    Icons.refresh_rounded,
                    () => provider.loadSubjects(),
                  ),
                  const SizedBox(width: 8),
                  // New Subject
                  Material(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showSubjectDialog(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New Subject',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Table header ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  _th('Code', flex: 2),
                  _th('Subject Title', flex: 4),
                  _th('Schedule', flex: 4),
                  _th('Room', flex: 2),
                  _th('Units', flex: 1),
                  _th('Actions', flex: 3, align: TextAlign.right),
                ],
              ),
            ),

            // ── Table body ─────────────────────────────────────────────────
            Expanded(
              child: provider.subjects.isEmpty
                  ? _empty()
                  : Container(
                      margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                        child: ListView.separated(
                          itemCount: provider.subjects.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: _border),
                          itemBuilder: (_, i) {
                            final s = provider.subjects[i];
                            return _SubjectRow(
                              subject: s,
                              onEdit: () =>
                                  _showSubjectDialog(context, provider, s),
                              onQR: () => _showQRDialog(context, s),
                              onDelete: () =>
                                  _confirmDelete(context, provider, s),
                              onGrading: () =>
                                  _showGradingSetup(context, provider, s),
                              onStudents: () =>
                                  _showEnrolledStudents(context, s),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String label, {int flex = 1, TextAlign align = TextAlign.left}) =>
      Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: align,
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
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

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.book_outlined, color: Colors.grey[700], size: 48),
        const SizedBox(height: 12),
        Text(
          'No subjects yet',
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Click "New Subject" to create one',
          style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
        ),
      ],
    ),
  );

  void _confirmDelete(BuildContext ctx, AdminProvider provider, Subject s) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Subject',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove "${s.subjectTitle}"? This cannot be undone.',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[500]),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSubject(s.id!);
              Navigator.pop(ctx);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog(BuildContext ctx, Subject s) {
    final qrData = 'STIMSYSENROLL|${s.id}';
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.subjectCode,
                style: GoogleFonts.inter(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.subjectTitle,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${s.scheduleDay}  ${s.formattedStartTime}–${s.formattedEndTime}  •  ${s.room}',
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Students scan this to self-enroll',
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dialogBtn(
                    Icons.download_rounded,
                    'Save PNG',
                    _accent,
                    () => _downloadQR(ctx, qrData, s.subjectCode),
                  ),
                  const SizedBox(width: 10),
                  _dialogBtn(
                    Icons.close_rounded,
                    'Close',
                    Colors.grey,
                    () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => Material(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _downloadQR(BuildContext ctx, String qrData, String code) async {
    try {
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final img = await painter.toImageData(
        600,
        format: ui.ImageByteFormat.png,
      );
      if (img == null) throw Exception('Failed');
      if (kIsWeb) {
        throw Exception(
          'Downloading files directly is not supported on web in this demo.',
        );
      }
      final home =
          Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '.';
      final path = '$home/Downloads/STIMSYS_QR_$code.png';
      await File(path).writeAsBytes(img.buffer.asUint8List());
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              'Saved to $path',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showSubjectDialog(
    BuildContext ctx,
    AdminProvider provider, [
    Subject? subject,
  ]) {
    showDialog(
      context: ctx,
      builder: (_) =>
          _DesktopSubjectDialog(provider: provider, subject: subject),
    );
  }

  void _showGradingSetup(BuildContext ctx, AdminProvider provider, Subject s) {
    showDialog(
      context: ctx,
      builder: (_) => _GradingSetupDialog(provider: provider, subject: s),
    );
  }

  void _showEnrolledStudents(BuildContext ctx, Subject s) {
    showDialog(
      context: ctx,
      builder: (_) => _EnrolledStudentsDialog(subject: s),
    );
  }

  void _showEnrollMasterlist(BuildContext ctx, AdminProvider provider) {
    showDialog(
      context: ctx,
      builder: (_) => _EnrollMasterlistDialog(provider: provider),
    );
  }
}

// ── Subject table row ─────────────────────────────────────────────────────────
class _SubjectRow extends StatefulWidget {
  final Subject subject;
  final VoidCallback onEdit, onQR, onDelete, onGrading, onStudents;
  const _SubjectRow({
    required this.subject,
    required this.onEdit,
    required this.onQR,
    required this.onDelete,
    required this.onGrading,
    required this.onStudents,
  });
  @override
  State<_SubjectRow> createState() => _SubjectRowState();
}

class _SubjectRowState extends State<_SubjectRow> {
  bool _hovered = false;
  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? const Color(0xFF273548) : _surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.subjectCode,
                  style: GoogleFonts.inter(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                s.subjectTitle,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: s.scheduleSlots
                    .map((slot) => Text(
                          '${slot.day}  ${slot.formattedStartTime}–${slot.formattedEndTime}',
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                s.room,
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${s.units} units',
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _btn(
                    Icons.people_rounded,
                    const Color(0xFF0EA5E9),
                    widget.onStudents,
                    'Enrolled Students',
                  ),
                  const SizedBox(width: 6),
                  _btn(
                    Icons.edit_rounded,
                    Colors.blue,
                    widget.onEdit,
                    'Edit Subject',
                  ),
                  const SizedBox(width: 6),
                  _btn(
                    Icons.grading_rounded,
                    const Color(0xFF10B981),
                    widget.onGrading,
                    'Grading Setup',
                  ),
                  const SizedBox(width: 6),
                  _btn(
                    Icons.qr_code_rounded,
                    _accent,
                    widget.onQR,
                    'Enrollment QR',
                  ),
                  const SizedBox(width: 6),
                  _btn(
                    Icons.delete_outline_rounded,
                    const Color(0xFFEF4444),
                    widget.onDelete,
                    'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap, String tip) =>
      Tooltip(
        message: tip,
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

// ── Create/Edit Subject Dialog ──────────────────────────────────────────────────
class _DesktopSubjectDialog extends StatefulWidget {
  final AdminProvider provider;
  final Subject? subject;
  const _DesktopSubjectDialog({required this.provider, this.subject});
  @override
  State<_DesktopSubjectDialog> createState() => _DesktopSubjectDialogState();
}

class _ScheduleRowInput {
  final TextEditingController dayCtrl;
  TimeOfDay start;
  TimeOfDay end;

  _ScheduleRowInput({
    required String day,
    required this.start,
    required this.end,
  }) : dayCtrl = TextEditingController(text: day);

  void dispose() {
    dayCtrl.dispose();
  }
}

class _DesktopSubjectDialogState extends State<_DesktopSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final List<_ScheduleRowInput> _scheduleRows = [];
  int _units = 3;
  String _instructorId = '';
  bool _loading = false;
  String? _themeColor = '#6366F1';

  final _colorOptions = [
    ('#6366F1', 'Indigo (Focus & Calm)'),
    ('#10B981', 'Emerald (Balance & Relief)'),
    ('#0EA5E9', 'Sky Blue (Clarity & Peace)'),
    ('#8B5CF6', 'Purple (Wisdom & Thought)'),
    ('#F59E0B', 'Amber (Energy & Warmth)'),
    ('#EC4899', 'Rose (Soft Accent)'),
  ];

  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    if (s != null) {
      _codeCtrl.text = s.subjectCode;
      _titleCtrl.text = s.subjectTitle;
      _roomCtrl.text = s.room;
      _units = s.units;
      _instructorId = s.instructorId;
      _themeColor = s.themeColor ?? '#6366F1';

      for (final slot in s.scheduleSlots) {
        TimeOfDay startTd = const TimeOfDay(hour: 7, minute: 30);
        TimeOfDay endTd = const TimeOfDay(hour: 9, minute: 0);

        final sParts = slot.startTime.split(':');
        if (sParts.length >= 2) {
          startTd = TimeOfDay(
            hour: int.tryParse(sParts[0]) ?? 7,
            minute: int.tryParse(sParts[1]) ?? 30,
          );
        }
        final eParts = slot.endTime.split(':');
        if (eParts.length >= 2) {
          endTd = TimeOfDay(
            hour: int.tryParse(eParts[0]) ?? 9,
            minute: int.tryParse(eParts[1]) ?? 0,
          );
        }

        _scheduleRows.add(_ScheduleRowInput(
          day: slot.day,
          start: startTd,
          end: endTd,
        ));
      }
    } else {
      if (!widget.provider.isSuperAdmin && widget.provider.currentInstructor != null) {
        _instructorId = widget.provider.currentInstructor!.id ?? '';
      }
    }

    if (_scheduleRows.isEmpty) {
      _scheduleRows.add(_ScheduleRowInput(
        day: 'MWF',
        start: const TimeOfDay(hour: 7, minute: 30),
        end: const TimeOfDay(hour: 9, minute: 0),
      ));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _roomCtrl.dispose();
    for (final r in _scheduleRows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subject == null ? 'New Subject' : 'Edit Subject',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _codeCtrl,
                      'Subject Code',
                      hint: 'e.g. WAD101',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _titleCtrl,
                      'Subject Title',
                      hint: 'e.g. Web App Development',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _field(_roomCtrl, 'Room', hint: 'e.g. Room 301'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _dropdown(
                      'Units',
                      '$_units',
                      ['1', '2', '3', '4', '5'],
                      (v) => setState(() => _units = int.parse(v!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic Schedule Rows Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedules',
                    style: GoogleFonts.inter(
                      color: Colors.grey[300],
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _scheduleRows.add(_ScheduleRowInput(
                          day: 'TTH',
                          start: const TimeOfDay(hour: 13, minute: 0),
                          end: const TimeOfDay(hour: 15, minute: 0),
                        ));
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 16, color: _accent),
                    label: Text(
                      'Add Schedule',
                      style: GoogleFonts.inter(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dynamic Schedule Rows List
              ...List.generate(_scheduleRows.length, (i) {
                final row = _scheduleRows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _dayDropdown(row),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _timePickerField(
                          'Start',
                          row.start,
                          (v) => setState(() => row.start = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _timePickerField(
                          'End',
                          row.end,
                          (v) => setState(() => row.end = v),
                        ),
                      ),
                      if (_scheduleRows.length > 1) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _scheduleRows[i].dispose();
                              _scheduleRows.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Theme Color',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((c) {
                  final hex = c.$1;
                  final name = c.$2;
                  final colorObj = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
                  final isSelected = _themeColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _themeColor = hex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colorObj.withValues(alpha: 0.15) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? colorObj : _border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          color: isSelected ? colorObj : Colors.grey[400],
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (widget.provider.isSuperAdmin) _instructorDropdown(),
              if (widget.provider.isSuperAdmin) const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.subject == null
                                ? 'Create Subject'
                                : 'Save Changes',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _dayOptions = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT',
    'MWF', 'TTH',
  ];

  Widget _dayDropdown(_ScheduleRowInput row) {
    final current = row.dayCtrl.text.trim().toUpperCase();
    final value = _dayOptions.contains(current) ? current : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day(s)',
          style: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select day',
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
              ),
              onChanged: (v) {
                if (v != null) {
                  setState(() => row.dayCtrl.text = v);
                }
              },
              dropdownColor: const Color(0xFF1E293B),
              iconEnabledColor: Colors.grey[500],
              isExpanded: true,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              items: _dayOptions.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    void Function(String)? onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 5),
      TextFormField(
        controller: ctrl,
        onChanged: onChanged,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    ],
  );

  String _formatTime(TimeOfDay t) {
    final hr = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hr:$min $period';
  }

  String _toDbTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _timePickerField(
    String label,
    TimeOfDay time,
    void Function(TimeOfDay) onSelected,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 5),
      InkWell(
        onTap: () async {
          final res = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: _accent,
                      surface: _surface,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
            },
          );
          if (res != null) onSelected(res);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(time),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
              Icon(
                Icons.access_time_rounded,
                color: Colors.grey[500],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: const Color(0xFF1E293B),
            iconEnabledColor: Colors.grey[500],
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            isExpanded: true,
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
          ),
        ),
      ),
    ],
  );

  Widget _instructorDropdown() {
    final items = [
      const DropdownMenuItem(value: '', child: Text('No Instructor Assigned')),
      ...widget.provider.instructors.map(
        (i) => DropdownMenuItem(value: i.id!, child: Text(i.fullName)),
      ),
    ];

    if (!items.any((item) => item.value == _instructorId)) {
      _instructorId = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructor',
          style: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _instructorId,
              onChanged: (v) => setState(() => _instructorId = v!),
              dropdownColor: const Color(0xFF1E293B),
              iconEnabledColor: Colors.grey[500],
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              isExpanded: true,
              items: items,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final scheduleDayStr = _scheduleRows.map((r) => r.dayCtrl.text.trim()).join('; ');
      final scheduleStartStr = _scheduleRows.map((r) => _toDbTime(r.start)).join('; ');
      final scheduleEndStr = _scheduleRows.map((r) => _toDbTime(r.end)).join('; ');

      if (widget.subject == null) {
        await widget.provider.createSubject(
          subjectCode: _codeCtrl.text.trim(),
          subjectTitle: _titleCtrl.text.trim(),
          scheduleDay: scheduleDayStr,
          scheduleStartTime: scheduleStartStr,
          scheduleEndTime: scheduleEndStr,
          room: _roomCtrl.text.trim(),
          units: _units,
          instructorId: _instructorId,
          themeColor: _themeColor,
        );
      } else {
        await widget.provider.updateSubject(
          subjectId: widget.subject!.id!,
          subjectCode: _codeCtrl.text.trim(),
          subjectTitle: _titleCtrl.text.trim(),
          scheduleDay: scheduleDayStr,
          scheduleStartTime: scheduleStartStr,
          scheduleEndTime: scheduleEndStr,
          room: _roomCtrl.text.trim(),
          units: _units,
          instructorId: _instructorId,
          themeColor: _themeColor,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      setState(() => _loading = false);
    }
  }
}

// ── Grading Setup Dialog ──────────────────────────────────────────────────────
class _GradingSetupDialog extends StatefulWidget {
  final AdminProvider provider;
  final Subject subject;
  const _GradingSetupDialog({required this.provider, required this.subject});
  @override
  State<_GradingSetupDialog> createState() => _GradingSetupDialogState();
}

class _GradingSetupDialogState extends State<_GradingSetupDialog> {
  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);

  bool _loading = true;
  bool _saving = false;

  late String _termType;
  late double _examPct;
  late double _quizPct;
  late double _attendPct;
  GradingConfig? _existing;

  DateTime? _prelimStart;
  DateTime? _prelimEnd;
  DateTime? _midtermStart;
  DateTime? _midtermEnd;
  DateTime? _semiFinalsStart;
  DateTime? _semiFinalsEnd;
  DateTime? _finalsStart;
  DateTime? _finalsEnd;

  final _examCtrl = TextEditingController();
  final _quizCtrl = TextEditingController();
  final _attendCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _termType = 'semester';
    _examPct = 60;
    _quizPct = 30;
    _attendPct = 10;
    _examCtrl.text = '60';
    _quizCtrl.text = '30';
    _attendCtrl.text = '10';
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final cfg = await widget.provider.loadGradingConfig(widget.subject.id!);
    if (mounted && cfg != null) {
      setState(() {
        _existing = cfg;
        _termType = cfg.termType;
        _examPct = cfg.examPct;
        _quizPct = cfg.quizPct;
        _attendPct = cfg.attendancePct;
        _examCtrl.text = cfg.examPct.toStringAsFixed(0);
        _quizCtrl.text = cfg.quizPct.toStringAsFixed(0);
        _attendCtrl.text = cfg.attendancePct.toStringAsFixed(0);

        _prelimStart = cfg.prelimStart;
        _prelimEnd = cfg.prelimEnd;
        _midtermStart = cfg.midtermStart;
        _midtermEnd = cfg.midtermEnd;
        _semiFinalsStart = cfg.semiFinalsStart;
        _semiFinalsEnd = cfg.semiFinalsEnd;
        _finalsStart = cfg.finalsStart;
        _finalsEnd = cfg.finalsEnd;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _examCtrl.dispose();
    _quizCtrl.dispose();
    _attendCtrl.dispose();
    super.dispose();
  }

  double get _total => _examPct + _quizPct + _attendPct;
  bool get _valid => (_total - 100.0).abs() < 0.01;

  void _recalc() {
    _examPct = double.tryParse(_examCtrl.text) ?? _examPct;
    _quizPct = double.tryParse(_quizCtrl.text) ?? _quizPct;
    _attendPct = double.tryParse(_attendCtrl.text) ?? _attendPct;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final config = GradingConfig(
        id: _existing?.id,
        subjectId: widget.subject.id!,
        termType: _termType,
        examPct: _examPct,
        quizPct: _quizPct,
        attendancePct: _attendPct,
        prelimStart: _prelimStart,
        prelimEnd: _prelimEnd,
        midtermStart: _midtermStart,
        midtermEnd: _midtermEnd,
        semiFinalsStart: _termType == 'semester' ? _semiFinalsStart : null,
        semiFinalsEnd: _termType == 'semester' ? _semiFinalsEnd : null,
        finalsStart: _finalsStart,
        finalsEnd: _finalsEnd,
      );
      await widget.provider.saveGradingConfig(config);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grading setup saved for ${widget.subject.subjectCode}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grading_rounded,
                          color: _green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grading Setup',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              widget.subject.subjectCode,
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Term Type
                  Text(
                    'Term Type',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _termChip('semester', 'Semester (4 terms)'),
                      const SizedBox(width: 10),
                      _termChip('trimester', 'Trimester (3 terms)'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _termType == 'semester'
                        ? 'Prelim · Midterm · Pre-Finals · Finals'
                        : 'Prelim · Midterm · Finals',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Weight fields
                  Text(
                    'Grade Component Weights',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formula: (score ÷ max) × 100 × weight%  =  contribution',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _weightField(
                        _examCtrl,
                        Icons.assignment_rounded,
                        'Exam',
                        const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 10),
                      _weightField(
                        _quizCtrl,
                        Icons.edit_note_rounded,
                        'Quiz / Activity',
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      _weightField(
                        _attendCtrl,
                        Icons.how_to_reg_rounded,
                        'Attendance',
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Term Dates
                  Text(
                    'Term Dates (For Auto Attendance Phase Mapping)',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dateField(
                        'Prelim',
                        _prelimStart,
                        _prelimEnd,
                        (s, e) => setState(() {
                          _prelimStart = s;
                          _prelimEnd = e;
                        }),
                      ),
                      const SizedBox(width: 10),
                      _dateField(
                        'Midterm',
                        _midtermStart,
                        _midtermEnd,
                        (s, e) => setState(() {
                          _midtermStart = s;
                          _midtermEnd = e;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_termType == 'semester') ...[
                        _dateField(
                          'Pre-Finals',
                          _semiFinalsStart,
                          _semiFinalsEnd,
                          (s, e) => setState(() {
                            _semiFinalsStart = s;
                            _semiFinalsEnd = e;
                          }),
                        ),
                        const SizedBox(width: 10),
                      ],
                      _dateField(
                        'Finals',
                        _finalsStart,
                        _finalsEnd,
                        (s, e) => setState(() {
                          _finalsStart = s;
                          _finalsEnd = e;
                        }),
                      ),
                      if (_termType == 'trimester') ...[
                        const Expanded(child: SizedBox()),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Total indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: (_valid ? _green : const Color(0xFFEF4444))
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_valid ? _green : const Color(0xFFEF4444))
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _valid
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color: _valid ? _green : const Color(0xFFEF4444),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _valid
                              ? 'Total: 100% ✓ Ready to save'
                              : 'Total: ${_total.toStringAsFixed(0)}%  — must equal 100%',
                          style: GoogleFonts.inter(
                            color: _valid ? _green : const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (_valid && !_saving) ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor: Colors.grey[800],
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save Config',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _termChip(String value, String label) {
    final active = _termType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _termType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? _accent.withValues(alpha: 0.12)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? _accent : _border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: active ? _accent : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _weightField(
    TextEditingController ctrl,
    IconData icon,
    String label,
    Color color,
  ) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          onChanged: (_) => _recalc(),
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            suffixText: '%',
            suffixStyle: GoogleFonts.inter(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _dateField(
    String label,
    DateTime? start,
    DateTime? end,
    void Function(DateTime?, DateTime?) onChanged,
  ) {
    String text = 'Not set';
    if (start != null && end != null) {
      text = '${start.month}/${start.day} - ${end.month}/${end.day}';
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                color: Colors.blueAccent,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
                initialDateRange: (start != null && end != null)
                    ? DateTimeRange(start: start, end: end)
                    : null,
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF6366F1),
                      surface: Color(0xFF1E293B),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (range != null) {
                onChanged(range.start, range.end);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      color: (start != null) ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: (start != null)
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[500],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enrolled Students Dialog ──────────────────────────────────────────────────
class _EnrolledStudentsDialog extends StatefulWidget {
  final Subject subject;
  const _EnrolledStudentsDialog({required this.subject});
  @override
  State<_EnrolledStudentsDialog> createState() => _EnrolledStudentsDialogState();
}

class _EnrolledStudentsDialogState extends State<_EnrolledStudentsDialog> {
  List<Student> _students = [];
  bool _loading = true;

  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final service = SupabaseService();
      final response = await service.getStudentsForSubject(widget.subject.id!);
      if (mounted) setState(() => _students = response);
    } catch (e) {
      debugPrint('Load enrolled students error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_rounded, color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enrolled Students',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${widget.subject.subjectCode} • ${widget.subject.subjectTitle}',
                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '${_students.length} students',
                    style: GoogleFonts.inter(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Student', style: _thStyle)),
                  Expanded(flex: 2, child: Text('USN', style: _thStyle)),
                  Expanded(flex: 2, child: Text('Course / Section', style: _thStyle)),
                ],
              ),
            ),

            // Table body
            Flexible(
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: _accent),
                      ),
                    )
                  : _students.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, color: Colors.grey[700], size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'No students enrolled yet',
                                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Share the enrollment QR so students can self-enroll',
                                  style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _border),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _students.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: _border),
                              itemBuilder: (_, i) {
                                final s = _students[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  color: _surface,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30, height: 30,
                                              decoration: BoxDecoration(
                                                color: _accent.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  s.firstName.isNotEmpty ? s.firstName[0].toUpperCase() : '?',
                                                  style: GoogleFonts.inter(
                                                    color: _accent,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                s.fullName,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          s.usn,
                                          style: GoogleFonts.robotoMono(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${s.course} ${s.yearSection}',
                                          style: GoogleFonts.inter(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _thStyle => GoogleFonts.inter(
    color: Colors.grey[500],
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

// ── Enroll Masterlist Dialog ──────────────────────────────────────────────────
class _EnrollMasterlistDialog extends StatefulWidget {
  final AdminProvider provider;
  const _EnrollMasterlistDialog({required this.provider});
  @override
  State<_EnrollMasterlistDialog> createState() => _EnrollMasterlistDialogState();
}

class _EnrollMasterlistDialogState extends State<_EnrollMasterlistDialog> {
  Subject? _selectedSubject;
  List<Student> _students = [];
  bool _loading = false;
  String _searchQuery = '';

  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _sky = Color(0xFF0EA5E9);

  @override
  void initState() {
    super.initState();
    if (widget.provider.subjects.isNotEmpty) {
      _selectedSubject = widget.provider.subjects.first;
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedSubject == null) return;
    setState(() => _loading = true);
    try {
      final service = SupabaseService();
      _students = await service.getStudentsForSubject(_selectedSubject!.id!);
    } catch (e) {
      debugPrint('Load masterlist error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, List<Student>> get _groupedStudents {
    final filtered = _searchQuery.isEmpty
        ? _students
        : _students.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.fullName.toLowerCase().contains(q) ||
                s.usn.toLowerCase().contains(q) ||
                s.course.toLowerCase().contains(q) ||
                s.yearSection.toLowerCase().contains(q);
          }).toList();

    final groups = <String, List<Student>>{};
    for (final s in filtered) {
      final key = '${s.course} ${s.yearSection}';
      groups.putIfAbsent(key, () => []).add(s);
    }

    // Sort keys
    final sortedKeys = groups.keys.toList()..sort();
    return {for (final k in sortedKeys) k: groups[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedStudents;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _sky.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_ind_rounded, color: _sky, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enrollment Masterlist',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!_loading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _green.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            '${_students.length} enrolled',
                            style: GoogleFonts.inter(color: _green, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey[500], size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Subject dropdown + search
                  Row(
                    children: [
                      // Subject Dropdown
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSubject?.id,
                              onChanged: (v) {
                                final subj = widget.provider.subjects.firstWhere((s) => s.id == v);
                                setState(() => _selectedSubject = subj);
                                _loadStudents();
                              },
                              dropdownColor: _surface,
                              iconEnabledColor: Colors.grey[500],
                              isExpanded: true,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                              items: widget.provider.subjects.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.subjectCode} — ${s.subjectTitle}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Search
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search name or USN...',
                              hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _accent))
                  : _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, color: Colors.grey[700], size: 48),
                              const SizedBox(height: 8),
                              Text('No students enrolled', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Share the enrollment QR so students can self-enroll',
                                  style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          itemCount: grouped.keys.length,
                          itemBuilder: (_, gi) {
                            final sectionKey = grouped.keys.elementAt(gi);
                            final sectionStudents = grouped[sectionKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section header
                                if (gi > 0) const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _accent.withValues(alpha: 0.18)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.school_rounded, color: _accent, size: 15),
                                      const SizedBox(width: 8),
                                      Text(
                                        sectionKey,
                                        style: GoogleFonts.inter(
                                          color: _accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${sectionStudents.length} student${sectionStudents.length != 1 ? 's' : ''}',
                                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Student rows
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Column(
                                      children: List.generate(sectionStudents.length, (si) {
                                        final s = sectionStudents[si];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _surface,
                                            border: si > 0 ? Border(top: BorderSide(color: _border)) : null,
                                          ),
                                          child: Row(
                                            children: [
                                              // Index
                                              SizedBox(
                                                width: 28,
                                                child: Text(
                                                  '${si + 1}',
                                                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                                                ),
                                              ),
                                              // Avatar
                                              Container(
                                                width: 30, height: 30,
                                                decoration: BoxDecoration(
                                                  color: _accent.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(7),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    s.firstName.isNotEmpty ? s.firstName[0].toUpperCase() : '?',
                                                    style: GoogleFonts.inter(color: _accent, fontSize: 13, fontWeight: FontWeight.w800),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Name
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  s.fullName,
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // USN
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  s.usn,
                                                  style: GoogleFonts.robotoMono(color: Colors.grey[400], fontSize: 12),
                                                ),
                                              ),
                                              // Status chip
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (s.isConfirmed ? _green : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  s.isConfirmed ? 'Confirmed' : 'Pending',
                                                  style: GoogleFonts.inter(
                                                    color: s.isConfirmed ? _green : const Color(0xFFF59E0B),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
