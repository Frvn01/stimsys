import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';

class DesktopSubjectManagementScreen extends StatefulWidget {
  const DesktopSubjectManagementScreen({super.key});
  @override
  State<DesktopSubjectManagementScreen> createState() =>
      _DesktopSubjectManagementScreenState();
}

class _DesktopSubjectManagementScreenState
    extends State<DesktopSubjectManagementScreen> {
  static const _bg      = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _accent  = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) => Container(
        color: _bg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Subject Management',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${provider.totalSubjects} subject${provider.totalSubjects != 1 ? 's' : ''} created',
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)),
              ])),
              // Refresh
              _iconBtn(Icons.refresh_rounded, () => provider.loadSubjects()),
              const SizedBox(width: 8),
              // New Subject
              Material(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showCreateDialog(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('New Subject', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),

          // ── Table header ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: _border),
            ),
            child: Row(children: [
              _th('Code', flex: 1),
              _th('Subject Title', flex: 3),
              _th('Schedule', flex: 2),
              _th('Room', flex: 1),
              _th('Units', flex: 1),
              _th('Actions', flex: 1, align: TextAlign.right),
            ]),
          ),

          // ── Table body ─────────────────────────────────────────────────
          Expanded(
            child: provider.subjects.isEmpty
                ? _empty()
                : Container(
                    margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      child: ListView.separated(
                        itemCount: provider.subjects.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: _border),
                        itemBuilder: (_, i) {
                          final s = provider.subjects[i];
                          return _SubjectRow(
                            subject: s,
                            onQR:     () => _showQRDialog(context, s),
                            onDelete: () => _confirmDelete(context, provider, s),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _th(String label, {int flex = 1, TextAlign align = TextAlign.left}) =>
      Expanded(flex: flex, child: Text(label, textAlign: align,
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 0.5)));

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: Icon(icon, color: Colors.grey[500], size: 18),
          ),
        ),
      );

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.book_outlined, color: Colors.grey[700], size: 48),
        const SizedBox(height: 12),
        Text('No subjects yet', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text('Click "New Subject" to create one', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12)),
      ]));

  void _confirmDelete(BuildContext ctx, AdminProvider provider, Subject s) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Subject', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Remove "${s.subjectTitle}"? This cannot be undone.',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500]))),
          TextButton(
            onPressed: () { provider.deleteSubject(s.id!); Navigator.pop(ctx); },
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.subjectCode, style: GoogleFonts.inter(color: _accent, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(s.subjectTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            Text('${s.scheduleDay}  ${s.scheduleStartTime}–${s.scheduleEndTime}  •  ${s.room}',
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: qrData, version: QrVersions.auto, size: 180,
                  backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.H),
            ),
            const SizedBox(height: 8),
            Text('Students scan this to self-enroll',
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _dialogBtn(Icons.download_rounded, 'Save PNG', _accent,
                  () => _downloadQR(ctx, qrData, s.subjectCode)),
              const SizedBox(width: 10),
              _dialogBtn(Icons.close_rounded, 'Close', Colors.grey,
                  () => Navigator.pop(ctx)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _dialogBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      Material(
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Future<void> _downloadQR(BuildContext ctx, String qrData, String code) async {
    try {
      final painter = QrPainter(data: qrData, version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          color: Colors.black, emptyColor: Colors.white);
      final img = await painter.toImageData(600, format: ui.ImageByteFormat.png);
      if (img == null) throw Exception('Failed');
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      final path = '$home/Downloads/STIMSYS_QR_$code.png';
      await File(path).writeAsBytes(img.buffer.asUint8List());
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Saved to $path', style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Failed: $e'), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  void _showCreateDialog(BuildContext ctx, AdminProvider provider) {
    showDialog(
      context: ctx,
      builder: (_) => _DesktopCreateSubjectDialog(provider: provider),
    );
  }
}

// ── Subject table row ─────────────────────────────────────────────────────────
class _SubjectRow extends StatefulWidget {
  final Subject subject;
  final VoidCallback onQR, onDelete;
  const _SubjectRow({required this.subject, required this.onQR, required this.onDelete});
  @override State<_SubjectRow> createState() => _SubjectRowState();
}

class _SubjectRowState extends State<_SubjectRow> {
  bool _hovered = false;
  static const _surface = Color(0xFF1E293B);
  static const _accent  = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? const Color(0xFF273548) : _surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(s.subjectCode, style: GoogleFonts.inter(color: _accent, fontSize: 11, fontWeight: FontWeight.w700)),
          )),
          Expanded(flex: 3, child: Text(s.subjectTitle,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${s.scheduleDay}  ${s.scheduleStartTime}–${s.scheduleEndTime}',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12))),
          Expanded(flex: 1, child: Text(s.room,
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12))),
          Expanded(flex: 1, child: Text('${s.units} units',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12))),
          Expanded(flex: 1, child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _btn(Icons.qr_code_rounded, _accent, widget.onQR, 'Enrollment QR'),
              const SizedBox(width: 6),
              _btn(Icons.delete_outline_rounded, const Color(0xFFEF4444), widget.onDelete, 'Delete'),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap, String tip) =>
      Tooltip(message: tip,
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(7),
          child: InkWell(borderRadius: BorderRadius.circular(7), onTap: onTap,
            child: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Icon(icon, color: color, size: 15)))));
}

// ── Create Subject Dialog ─────────────────────────────────────────────────────
class _DesktopCreateSubjectDialog extends StatefulWidget {
  final AdminProvider provider;
  const _DesktopCreateSubjectDialog({required this.provider});
  @override State<_DesktopCreateSubjectDialog> createState() => _DesktopCreateSubjectDialogState();
}

class _DesktopCreateSubjectDialogState extends State<_DesktopCreateSubjectDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _roomCtrl  = TextEditingController();
  String _day   = 'MWF';
  String _start = '07:30';
  String _end   = '09:00';
  int    _units = 3;
  bool   _loading = false;

  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _accent  = Color(0xFF6366F1);

  @override
  void dispose() {
    _codeCtrl.dispose(); _titleCtrl.dispose(); _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Subject', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_codeCtrl, 'Subject Code', hint: 'e.g. WAD101')),
              const SizedBox(width: 12),
              Expanded(child: _field(_titleCtrl, 'Subject Title', hint: 'e.g. Web App Development')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dropdown('Day', _day,
                  ['MWF', 'TTH', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
                  (v) => setState(() => _day = v!))),
              const SizedBox(width: 12),
              Expanded(child: _field(_roomCtrl, 'Room', hint: 'e.g. Room 301')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(TextEditingController(text: _start), 'Start', hint: '07:30',
                  onChanged: (v) => _start = v)),
              const SizedBox(width: 12),
              Expanded(child: _field(TextEditingController(text: _end), 'End', hint: '09:00',
                  onChanged: (v) => _end = v)),
              const SizedBox(width: 12),
              Expanded(child: _dropdown('Units', '$_units',
                  ['1', '2', '3', '4', '5'],
                  (v) => setState(() => _units = int.parse(v!)))),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500]))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: _accent, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Create Subject', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String? hint, void Function(String)? onChanged}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          onChanged: onChanged,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint, hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
            filled: true, fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent, width: 1.5)),
          ),
        ),
      ]);

  Widget _dropdown(String label, String value, List<String> items, void Function(String?) onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600)),
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
              value: value, onChanged: onChanged,
              dropdownColor: const Color(0xFF1E293B),
              iconEnabledColor: Colors.grey[500],
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              isExpanded: true,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            ),
          ),
        ),
      ]);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.provider.createSubject(
        subjectCode: _codeCtrl.text.trim(),
        subjectTitle: _titleCtrl.text.trim(),
        scheduleDay: _day,
        scheduleStartTime: _start,
        scheduleEndTime: _end,
        room: _roomCtrl.text.trim(),
        units: _units,
        instructorId: '',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      setState(() => _loading = false);
    }
  }
}
