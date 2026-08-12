import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/enrollment_model.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {

  void _createSubject(AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSubjectSheet(provider: provider),
    );
  }

  void _enrollStudents(AdminProvider provider, Subject subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EnrollSheet(provider: provider, subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: SafeArea(
          child: Column(children: [

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Subjects', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('${provider.totalSubjects} subject${provider.totalSubjects != 1 ? 's' : ''} created',
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () => _createSubject(provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('New Subject', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── List ──
            Expanded(
              child: provider.subjects.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.book_outlined, color: Colors.grey[700], size: 52),
                    const SizedBox(height: 12),
                    Text('No subjects yet', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Tap "New Subject" to create one', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                  ]))
                : RefreshIndicator(
                    color: const Color(0xFF6366F1),
                    backgroundColor: const Color(0xFF111633),
                    onRefresh: () => provider.loadSubjects(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: provider.subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _SubjectCard(
                        subject: provider.subjects[i],
                        onEnroll: () => _enrollStudents(provider, provider.subjects[i]),
                        onDelete: () => _confirmDelete(context, provider, provider.subjects[i]),
                      ),
                    ),
                  ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminProvider provider, Subject s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111633),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Subject', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Delete "${s.subjectTitle}" (${s.subjectCode})? All enrollments and attendance will be removed.',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500]))),
          TextButton(
            onPressed: () { provider.deleteSubject(s.id!); Navigator.pop(ctx); },
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Subject Card ──
class _SubjectCard extends StatefulWidget {
  final Subject subject;
  final VoidCallback onEnroll, onDelete;
  const _SubjectCard({required this.subject, required this.onEnroll, required this.onDelete});

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  List<Enrollment> _enrollments = [];
  bool _loadedEnrollments = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    final provider = context.read<AdminProvider>();
    final list = await provider.getSubjectEnrollments(widget.subject.id!);
    if (mounted) setState(() { _enrollments = list; _loadedEnrollments = true; });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final s = widget.subject;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111633),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top accent bar
        Container(
          height: 4,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Code + actions row
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                ),
                child: Text(s.subjectCode, style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${s.units} units', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
              ),
              const Spacer(),
              _iconBtn(Icons.qr_code_rounded, const Color(0xFF6366F1), () => _showSubjectQR(context, s)),
              const SizedBox(width: 8),
              _iconBtn(Icons.person_add_rounded, const Color(0xFF10B981), widget.onEnroll),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), widget.onDelete),

            ]),

            const SizedBox(height: 12),

            // Title
            Text(s.subjectTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(s.instructorName ?? provider.currentInstructor?.fullName ?? 'Instructor',
              style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),

            const SizedBox(height: 12),

            // Info chips
            Wrap(spacing: 10, runSpacing: 6, children: [
              _chip(Icons.schedule_rounded, '${s.scheduleDay} • ${s.scheduleStartTime}–${s.scheduleEndTime}'),
              _chip(Icons.room_rounded, s.room),
              _chip(Icons.timer_outlined, '${s.lateThresholdMinutes}min grace'),
              _chip(Icons.people_rounded, _loadedEnrollments ? '${_enrollments.length} enrolled' : '...'),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _showSubjectQR(BuildContext context, Subject s) {
    final qrData = 'STIMSYSENROLL|${s.id}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111633),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.subjectCode, style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            Text(s.subjectTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            Text('${s.scheduleDay} ${s.scheduleStartTime}–${s.scheduleEndTime} • ${s.room}',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: qrData, version: QrVersions.auto, size: 200, backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.H),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 8),
                Text('Students scan this to self-enroll', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _qrDialogBtn(Icons.download_rounded, 'Save Image', const Color(0xFF6366F1), () => _downloadQR(context, qrData, s.subjectCode)),
              const SizedBox(width: 12),
              _qrDialogBtn(Icons.close_rounded, 'Close', Colors.grey, () => Navigator.pop(context)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _qrDialogBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Future<void> _downloadQR(BuildContext ctx, String qrData, String subjectCode) async {
    try {
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final imageData = await qrPainter.toImageData(600, format: ui.ImageByteFormat.png);
      if (imageData == null) throw Exception('Failed to generate QR image');

      // Determine save path
      String savePath;
      if (kIsWeb) {
        throw Exception('Downloading files directly is not supported on web in this demo.');
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop: save to Downloads folder
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
        final downloadsDir = Directory('$home/Downloads');
        if (!downloadsDir.existsSync()) downloadsDir.createSync(recursive: true);
        savePath = '${downloadsDir.path}/STIMSYS_QR_$subjectCode.png';
      } else {
        // Mobile: save to app documents directory
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/STIMSYS_QR_$subjectCode.png';
      }

      final file = File(savePath);
      await file.writeAsBytes(imageData.buffer.asUint8List());

      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('QR saved to: $savePath', style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Failed to save QR: $e', style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(

    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 17),
    ),
  );

  Widget _chip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
    ],
  );
}

// ── Create Subject Bottom Sheet ──
class _CreateSubjectSheet extends StatefulWidget {
  final AdminProvider provider;
  const _CreateSubjectSheet({required this.provider});

  @override
  State<_CreateSubjectSheet> createState() => _CreateSubjectSheetState();
}

class _MobileScheduleRow {
  final TextEditingController dayCtrl;
  TimeOfDay start;
  TimeOfDay end;

  _MobileScheduleRow({
    required String day,
    required this.start,
    required this.end,
  }) : dayCtrl = TextEditingController(text: day);

  void dispose() {
    dayCtrl.dispose();
  }
}

class _CreateSubjectSheetState extends State<_CreateSubjectSheet> {
  final _codeCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: '3');
  final _roomCtrl = TextEditingController();
  final List<_MobileScheduleRow> _scheduleRows = [];
  int _threshold = 15;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scheduleRows.add(_MobileScheduleRow(
      day: 'MWF',
      start: const TimeOfDay(hour: 7, minute: 30),
      end: const TimeOfDay(hour: 10, minute: 0),
    ));
  }

  @override
  void dispose() {
    _codeCtrl.dispose(); _titleCtrl.dispose(); _unitsCtrl.dispose(); _roomCtrl.dispose();
    for (final r in _scheduleRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.isEmpty || _titleCtrl.text.isEmpty || _roomCtrl.text.isEmpty || _scheduleRows.any((r) => r.dayCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    final instructor = widget.provider.currentInstructor ?? (widget.provider.instructors.isNotEmpty ? widget.provider.instructors.first : null);
    if (instructor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No instructor found. Run the SQL schema first.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fmtTime = (TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      final scheduleDayStr = _scheduleRows.map((r) => r.dayCtrl.text.trim()).join('; ');
      final scheduleStartStr = _scheduleRows.map((r) => fmtTime(r.start)).join('; ');
      final scheduleEndStr = _scheduleRows.map((r) => fmtTime(r.end)).join('; ');

      await widget.provider.createSubject(
        subjectCode: _codeCtrl.text,
        subjectTitle: _titleCtrl.text,
        units: int.tryParse(_unitsCtrl.text) ?? 3,
        scheduleStartTime: scheduleStartStr,
        scheduleEndTime: scheduleEndStr,
        scheduleDay: scheduleDayStr,
        room: _roomCtrl.text,
        instructorId: instructor.id!,
        lateThresholdMinutes: _threshold,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF111633),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          Text('Create New Subject', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Instructor: ${widget.provider.currentInstructor?.fullName ?? 'Instructor'}', style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          _sheetField(_codeCtrl, 'Subject Code *', 'e.g. IT6205A'),
          const SizedBox(height: 12),
          _sheetField(_titleCtrl, 'Subject Title *', 'e.g. Information Assurance'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _sheetField(_unitsCtrl, 'Units', '3', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _sheetField(_roomCtrl, 'Room *', 'e.g. CL3')),
          ]),
          const SizedBox(height: 16),

          // Dynamic Schedule Rows Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Schedules', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _scheduleRows.add(_MobileScheduleRow(
                      day: 'TTH',
                      start: const TimeOfDay(hour: 13, minute: 0),
                      end: const TimeOfDay(hour: 15, minute: 0),
                    ));
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF818CF8)),
                label: Text('Add Schedule', style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...List.generate(_scheduleRows.length, (i) {
            final row = _scheduleRows[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _dayDropdownMobile(row)),
                      if (_scheduleRows.length > 1) ...[
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 20),
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
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _timePicker('Start', row.start, (t) => setState(() => row.start = t))),
                    const SizedBox(width: 12),
                    Expanded(child: _timePicker('End', row.end, (t) => setState(() => row.end = t))),
                  ]),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Late threshold
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Late after (minutes)', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            Row(children: [
              _threshBtn(Icons.remove_rounded, () => setState(() => _threshold = (_threshold - 5).clamp(5, 60))),
              const SizedBox(width: 8),
              Container(
                width: 44, height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Text('$_threshold', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              _threshBtn(Icons.add_rounded, () => setState(() => _threshold = (_threshold + 5).clamp(5, 60))),
            ]),
          ]),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Create Subject', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  static const _dayOptions = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT',
    'MWF', 'TTH',
  ];

  Widget _dayDropdownMobile(_MobileScheduleRow row) {
    final current = row.dayCtrl.text.trim().toUpperCase();
    final value = _dayOptions.contains(current) ? current : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Day(s) *', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('Select day', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13)),
              onChanged: (v) {
                if (v != null) setState(() => row.dayCtrl.text = v);
              },
              dropdownColor: const Color(0xFF1E293B),
              iconEnabledColor: Colors.grey[500],
              isExpanded: true,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              items: _dayOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, String hint, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: _sheetDeco(label).copyWith(hintText: hint, hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13)),
    );
  }

  InputDecoration _sheetDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _timePicker(String label, TimeOfDay time, ValueChanged<TimeOfDay> onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
            child: Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1))), child: child!),
          ));
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time_rounded, color: Color(0xFF6366F1), size: 16),
            const SizedBox(width: 6),
            Text(time.format(context), style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  Widget _threshBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );
}

// ── Enroll Student Sheet ──
class _EnrollSheet extends StatefulWidget {
  final AdminProvider provider;
  final Subject subject;
  const _EnrollSheet({required this.provider, required this.subject});

  @override
  State<_EnrollSheet> createState() => _EnrollSheetState();
}

class _EnrollSheetState extends State<_EnrollSheet> {
  String _search = '';
  final Set<String> _enrolling = {};

  @override
  Widget build(BuildContext context) {
    var students = widget.provider.students.where((s) => s.isConfirmed).toList();
    if (_search.isNotEmpty) {
      students = students.where((s) =>
        s.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        s.usn.contains(_search)).toList();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111633),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Enroll Students', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(widget.subject.subjectCode, style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search confirmed students...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ]),
          ),

          Expanded(
            child: students.isEmpty
              ? Center(child: Text('No confirmed students found', style: GoogleFonts.inter(color: Colors.grey[500])))
              : ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = students[i];
                    final isEnrolling = _enrolling.contains(s.id);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1226),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(s.firstName[0].toUpperCase(),
                            style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 16, fontWeight: FontWeight.w700))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.fullName, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${s.usn} • ${s.course} ${s.yearSection}',
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                        ])),
                        GestureDetector(
                          onTap: isEnrolling ? null : () async {
                            setState(() => _enrolling.add(s.id!));
                            try {
                              await widget.provider.enrollStudent(s.id!, widget.subject.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${s.fullName} enrolled!'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(e.toString().contains('duplicate') ? 'Already enrolled' : 'Error: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ));
                              }
                            }
                            if (mounted) setState(() => _enrolling.remove(s.id));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: isEnrolling
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2))
                              : Text('Enroll', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
          ),
        ]),
      ),
    );
  }
}
