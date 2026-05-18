import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/grade_capture_model.dart';
import '../../models/subject_model.dart';
import '../../providers/admin_provider.dart';

class DesktopGradeGalleryScreen extends StatefulWidget {
  const DesktopGradeGalleryScreen({super.key});

  @override
  State<DesktopGradeGalleryScreen> createState() =>
      _DesktopGradeGalleryScreenState();
}

class _DesktopGradeGalleryScreenState
    extends State<DesktopGradeGalleryScreen> {
  // ── Design tokens ──────────────────────────────────
  static const _bg      = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A2235);
  static const _border  = Color(0xFF232D3F);
  static const _accent  = Color(0xFF6366F1);
  static const _amber   = Color(0xFFF59E0B);
  static const _red     = Color(0xFFEF4444);

  String? _selectedSubjectId;
  GradeCapture? _preview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<AdminProvider>();
    if (provider.subjects.isEmpty) await provider.loadSubjects();
    await provider.loadCaptures(subjectId: _selectedSubjectId);
  }

  Future<void> _confirmDelete(GradeCapture capture) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete capture?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        content: Text(
            'This permanently removes the image and its database record.',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: _red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Close preview if we're deleting the previewed item
    if (_preview?.id == capture.id) setState(() => _preview = null);
    try {
      await context.read<AdminProvider>().deleteCapture(capture.id!, capture.fileUrl);
      if (mounted) _showSnack('Deleted successfully', _red);
    } catch (e) {
      if (mounted) _showSnack('Delete failed: $e', _red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
      backgroundColor: color.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final captures = provider.captures;
        return Container(
          color: _bg,
          child: Column(children: [
            _buildHeader(provider, captures.length),
            Expanded(
              child: Row(children: [
                // ── Left: filter panel + grid ──────────────────────
                Expanded(
                  child: Column(children: [
                    _buildSubjectFilter(provider.subjects),
                    Expanded(
                      child: captures.isEmpty
                          ? _buildEmptyState()
                          : _buildGrid(captures),
                    ),
                  ]),
                ),
                // ── Right: preview panel ────────────────────────────
                if (_preview != null) ...[
                  Container(width: 1, color: _border),
                  _buildPreviewPanel(_preview!),
                ],
              ]),
            ),
          ]),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────
  Widget _buildHeader(AdminProvider provider, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Grade Evidence Gallery',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('Read-only view · $count capture${count != 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                  color: const Color(0xFF4B5E78), fontSize: 12)),
        ]),
        const Spacer(),
        // Refresh
        _headerBtn(Icons.refresh_rounded, 'Refresh', _load),
      ]),
    );
  }

  // ── Subject filter chips ─────────────────────────────
  Widget _buildSubjectFilter(List<Subject> subjects) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All captures',
            isActive: _selectedSubjectId == null,
            onTap: () {
              setState(() {
                _selectedSubjectId = null;
                _preview = null;
              });
              context.read<AdminProvider>().loadCaptures();
            },
          ),
          ...subjects.map((s) => _FilterChip(
                label: s.subjectCode,
                isActive: _selectedSubjectId == s.id,
                onTap: () {
                  setState(() {
                    _selectedSubjectId = s.id;
                    _preview = null;
                  });
                  context
                      .read<AdminProvider>()
                      .loadCaptures(subjectId: s.id);
                },
              )),
        ],
      ),
    );
  }

  // ── Image grid ──────────────────────────────────────
  Widget _buildGrid(List<GradeCapture> captures) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: captures.length,
      itemBuilder: (ctx, i) {
        final c = captures[i];
        final isSelected = _preview?.id == c.id;
        return _DesktopCaptureCard(
          capture: c,
          isSelected: isSelected,
          onTap: () => setState(() => _preview = isSelected ? null : c),
          onDelete: () => _confirmDelete(c),
        );
      },
    );
  }

  // ── Empty state ─────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.photo_library_rounded,
              color: _accent, size: 34),
        ),
        const SizedBox(height: 16),
        Text('No captures yet',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Captures uploaded from the mobile app will appear here.',
            style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78), fontSize: 12)),
      ]),
    );
  }

  // ── Preview panel ────────────────────────────────────
  Widget _buildPreviewPanel(GradeCapture capture) {
    final daysLeft = capture.daysUntilExpiry;
    final expiringSoon = daysLeft <= 5;

    return Container(
      width: 300,
      color: _surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Image ──
        Container(
          height: 220,
          width: double.infinity,
          color: const Color(0xFF0D1226),
          child: Image.network(
            capture.fileUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  color: Colors.white24, size: 48),
            ),
          ),
        ),
        Container(height: 1, color: _border),

        // ── Details ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _previewRow(
                Icons.calendar_today_rounded,
                'Captured',
                DateFormat('MMM d, yyyy • h:mm a')
                    .format(capture.capturedAt.toLocal()),
              ),
              const SizedBox(height: 12),
              _previewRow(
                Icons.schedule_rounded,
                'Expires',
                DateFormat('MMM d, yyyy')
                    .format(capture.expiresAt.toLocal()),
                valueColor: expiringSoon ? _amber : null,
              ),
              const SizedBox(height: 12),
              _previewRow(
                Icons.book_rounded,
                'Subject',
                capture.subjectCode ?? '—',
              ),
              if (capture.studentNote != null &&
                  capture.studentNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _previewRow(
                  Icons.notes_rounded,
                  'Note',
                  capture.studentNote!,
                ),
              ],
              const SizedBox(height: 20),
              // Expiry chip
              if (expiringSoon)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: _amber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      daysLeft <= 0
                          ? 'Expired'
                          : 'Expires in $daysLeft day${daysLeft != 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                          color: _amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),
              // Delete button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(capture),
                  icon: const Icon(Icons.delete_rounded,
                      size: 16, color: _red),
                  label: Text('Delete Capture',
                      style: GoogleFonts.inter(
                          color: _red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: _red.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _previewRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: const Color(0xFF4B5E78)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: const Color(0xFF4B5E78),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.inter(
                  color: valueColor ?? Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    ]);
  }

  Widget _headerBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: const Color(0xFF4B5E78), size: 17),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DESKTOP CAPTURE CARD
// ══════════════════════════════════════════════════════

class _DesktopCaptureCard extends StatefulWidget {
  final GradeCapture capture;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DesktopCaptureCard({
    required this.capture,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_DesktopCaptureCard> createState() => _DesktopCaptureCardState();
}

class _DesktopCaptureCardState extends State<_DesktopCaptureCard> {
  static const _surface = Color(0xFF1A2235);
  static const _border  = Color(0xFF232D3F);
  static const _accent  = Color(0xFF6366F1);
  static const _amber   = Color(0xFFF59E0B);
  static const _red     = Color(0xFFEF4444);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.capture;
    final daysLeft = c.daysUntilExpiry;
    final expiringSoon = daysLeft <= 5;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? _accent
                  : expiringSoon
                      ? _amber.withValues(alpha: 0.4)
                      : _hovered
                          ? const Color(0xFF2E3D54)
                          : _border,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                        color: _accent.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Image ──
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(fit: StackFit.expand, children: [
                  Image.network(
                    c.fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0D1226),
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.white12, size: 30),
                    ),
                  ),
                  // Delete overlay on hover
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.delete_rounded,
                                  color: _red, size: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Expiry badge
                  if (expiringSoon)
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _amber,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          daysLeft <= 0
                              ? 'Expired'
                              : '${daysLeft}d left',
                          style: GoogleFonts.inter(
                              color: Colors.black87,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  // Selected indicator
                  if (widget.isSelected)
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(
                          color: _accent, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ]),
              ),
            ),

            // ── Meta ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (c.subjectCode != null)
                  Text(c.subjectCode!,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF818CF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                Text(
                  DateFormat('MMM d • h:mm a').format(c.capturedAt.toLocal()),
                  style: GoogleFonts.inter(
                      color: const Color(0xFF4B5E78), fontSize: 10),
                ),
              ]),
            ),
          ]),
        ),
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
  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                : const Color(0xFF232D3F),
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: isActive
                  ? const Color(0xFF818CF8)
                  : const Color(0xFF4B5E78),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }
}
