import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/grade_capture_model.dart';
import '../../models/subject_model.dart';
import '../../providers/admin_provider.dart';

class GradeCaptureScreen extends StatefulWidget {
  const GradeCaptureScreen({super.key});

  @override
  State<GradeCaptureScreen> createState() => _GradeCaptureScreenState();
}

class _GradeCaptureScreenState extends State<GradeCaptureScreen>
    with SingleTickerProviderStateMixin {
  static const _bg      = Color(0xFF0A0E21);
  static const _surface = Color(0xFF111633);
  static const _border  = Color(0xFF1E2A45);
  static const _accent  = Color(0xFF6366F1);
  static const _amber   = Color(0xFFF59E0B);
  static const _red     = Color(0xFFEF4444);

  final ImagePicker _picker = ImagePicker();
  String? _selectedSubjectId;
  bool _isUploading = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<AdminProvider>();
    if (provider.subjects.isEmpty) await provider.loadSubjects();
    await provider.loadCaptures(subjectId: _selectedSubjectId);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (xFile == null || !mounted) return;

      // Show metadata bottom sheet before uploading
      final meta = await _showMetadataSheet(File(xFile.path));
      if (meta == null || !mounted) return; // cancelled

      setState(() => _isUploading = true);

      await context.read<AdminProvider>().captureAndUpload(
            file: File(xFile.path),
            fileType: 'image',
            subjectId: meta['subjectId'] as String?,
            studentName: meta['studentName'] as String?,
            section: meta['section'] as String?,
            studentNote: meta['note'] as String?,
          );

      if (mounted) _showSnack('✅ Photo uploaded successfully', _accent);
    } catch (e) {
      if (mounted) _showSnack('❌ Upload failed: $e', _red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Shows a bottom sheet for entering metadata. Returns a map or null if cancelled.
  Future<Map<String, dynamic>?> _showMetadataSheet(File imageFile) async {
    final provider = context.read<AdminProvider>();
    final subjects = provider.subjects;

    String? subjectId;
    final nameCtrl    = TextEditingController();
    final sectionCtrl = TextEditingController();
    final noteCtrl    = TextEditingController();

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111633),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Handle
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 16),

                // Preview thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),

                Text('Evidence Details',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Fill in the details for this grade evidence',
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 18),

                // Subject dropdown
                _sheetLabel('SUBJECT'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1226),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2A45))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: subjectId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF111633),
                      iconEnabledColor: Colors.grey[500],
                      hint: Text('Select subject (optional)',
                          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      onChanged: (v) => setSheet(() => subjectId = v),
                      items: subjects.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.subjectCode} – ${s.subjectTitle}',
                            overflow: TextOverflow.ellipsis),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Student name
                _sheetLabel('STUDENT NAME'),
                const SizedBox(height: 6),
                _sheetField(nameCtrl, 'e.g. Raven Ulrich Fabre', Icons.person_rounded),
                const SizedBox(height: 14),

                // Section
                _sheetLabel('SECTION'),
                const SizedBox(height: 6),
                _sheetField(sectionCtrl, 'e.g. WAD 3 AB', Icons.group_rounded),
                const SizedBox(height: 14),

                // Note
                _sheetLabel('NOTE / DESCRIPTION'),
                const SizedBox(height: 6),
                _sheetField(noteCtrl, 'What does this image show?',
                    Icons.notes_rounded, maxLines: 3),
                const SizedBox(height: 24),

                // Action buttons
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E2A45)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, {
                      'subjectId':   subjectId,
                      'studentName': nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                      'section':     sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
                      'note':        noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Upload Evidence',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(text,
    style: GoogleFonts.inter(
      color: const Color(0xFF4B5E78), fontSize: 10,
      fontWeight: FontWeight.w700, letterSpacing: 0.8));

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 18),
        filled: true,
        fillColor: const Color(0xFF0D1226),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E2A45))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E2A45))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 1.5)),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 12, vertical: maxLines > 1 ? 12 : 0),
      ),
    );
  }

  Future<void> _confirmDelete(GradeCapture capture) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete capture?',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This will permanently remove the image and its record.',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: _red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AdminProvider>().deleteCapture(capture.id!, capture.fileUrl);
      if (mounted) _showSnack('🗑️ Deleted', _red);
    } catch (e) {
      if (mounted) _showSnack('❌ Delete failed: $e', _red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
      backgroundColor: color.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final captures = provider.captures;
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(children: [
              _buildHeader(provider),
              _buildSubjectFilter(provider.subjects),
              Expanded(
                child: _isUploading
                    ? _buildUploading()
                    : captures.isEmpty
                        ? _buildEmptyState()
                        : _buildGrid(captures),
              ),
            ]),
          ),
          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  Widget _buildHeader(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Grade Evidence',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Capture & manage grade photos',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
        ])),
        _iconBtn(Icons.refresh_rounded, _load),
      ]),
    );
  }

  Widget _buildSubjectFilter(List<Subject> subjects) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'All',
            isActive: _selectedSubjectId == null,
            onTap: () {
              setState(() => _selectedSubjectId = null);
              context.read<AdminProvider>().loadCaptures();
            },
          ),
          ...subjects.map((s) => _FilterChip(
                label: s.subjectCode,
                isActive: _selectedSubjectId == s.id,
                onTap: () {
                  setState(() => _selectedSubjectId = s.id);
                  context.read<AdminProvider>().loadCaptures(subjectId: s.id);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildGrid(List<GradeCapture> captures) {
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: captures.length,
        itemBuilder: (ctx, i) => _CaptureCard(
          capture: captures[i],
          onDelete: () => _confirmDelete(captures[i]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.photo_camera_rounded, color: _accent, size: 38),
        ),
        const SizedBox(height: 16),
        Text('No captures yet',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Tap the camera button to add grade evidence',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildUploading() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Opacity(
            opacity: 0.5 + 0.5 * _pulseCtrl.value,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.cloud_upload_rounded, color: _accent, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('Uploading…',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Please wait', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
      ]),
    );
  }

  Widget _buildFab() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      FloatingActionButton(
        heroTag: 'fab_gallery',
        mini: true,
        backgroundColor: _amber,
        onPressed: () => _pickAndUpload(ImageSource.gallery),
        tooltip: 'Pick from gallery',
        child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(height: 10),
      FloatingActionButton(
        heroTag: 'fab_camera',
        backgroundColor: _accent,
        onPressed: () => _pickAndUpload(ImageSource.camera),
        tooltip: 'Take a photo',
        child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 24),
      ),
    ]);
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// CAPTURE CARD
// ══════════════════════════════════════════════════════

class _CaptureCard extends StatefulWidget {
  final GradeCapture capture;
  final VoidCallback onDelete;
  const _CaptureCard({required this.capture, required this.onDelete});

  @override
  State<_CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<_CaptureCard> {
  static const _surface = Color(0xFF111633);
  static const _border  = Color(0xFF1E2A45);
  static const _accent  = Color(0xFF6366F1);
  static const _red     = Color(0xFFEF4444);
  static const _amber   = Color(0xFFF59E0B);

  void _viewFull(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: widget.capture.id ?? widget.capture.fileUrl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.capture.fileUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 200, height: 200,
                  color: _surface,
                  child: const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    final daysLeft = capture.daysUntilExpiry;
    final expiringSoon = daysLeft <= 5;
    final hasStudentInfo = (capture.studentName != null && capture.studentName!.isNotEmpty)
        || (capture.section != null && capture.section!.isNotEmpty);

    return GestureDetector(
      onTap: () => _viewFull(context),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expiringSoon ? _amber.withValues(alpha: 0.4) : _border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Image ──
          Expanded(
            child: Hero(
              tag: capture.id ?? capture.fileUrl,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(fit: StackFit.expand, children: [
                  Image.network(
                    capture.fileUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: _accent,
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0D1226),
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.white24, size: 32),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_rounded, color: _red, size: 16),
                      ),
                    ),
                  ),
                  // Expiry badge
                  if (expiringSoon)
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysLeft <= 0 ? 'Expired' : '${daysLeft}d left',
                          style: GoogleFonts.inter(
                              color: Colors.black87, fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),

          // ── Metadata ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Subject code badge
              if (capture.subjectCode != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(capture.subjectCode!,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF818CF8),
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              // Student name
              if (hasStudentInfo)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.person_rounded, color: Color(0xFF4B5E78), size: 11),
                  const SizedBox(width: 3),
                  Expanded(child: Text(
                    [
                      if (capture.studentName != null && capture.studentName!.isNotEmpty)
                        capture.studentName!,
                      if (capture.section != null && capture.section!.isNotEmpty)
                        capture.section!,
                    ].join(' • '),
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
                ]),
              const SizedBox(height: 2),
              // Date
              Text(
                DateFormat('MMM d, yy • h:mm a').format(capture.capturedAt.toLocal()),
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 9),
              ),
              // Note
              if (capture.studentNote != null && capture.studentNote!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  capture.studentNote!,
                  style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// FILTER CHIP
// ══════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withValues(alpha: 0.18)
              : const Color(0xFF111633),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                : const Color(0xFF1E2A45),
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: isActive ? const Color(0xFF818CF8) : Colors.grey[500],
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }
}
