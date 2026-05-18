import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/attendance_model.dart';
import '../../services/supabase_service.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen>
    with SingleTickerProviderStateMixin {
  Subject? _selectedSubject;
  bool _isScanning = false;
  bool _isProcessing = false;
  String? _scheduleError;
  final List<AttendanceRecord> _scannedRecords = [];
  MobileScannerController? _scanCtrl;
  late AnimationController _pulseCtrl;
  AttendanceRecord? _lastScan;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    if (_selectedSubject == null) return;
    setState(() {
      _isScanning = !_isScanning;
      _lastScan = null;
      if (_isScanning) {
        _scanCtrl = MobileScannerController();
      } else {
        _scanCtrl?.dispose();
        _scanCtrl = null;
      }
    });
  }

  Future<void> _handleScan(BarcodeCapture capture, AdminProvider provider) async {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.startsWith('STIMSYSATT|')) return;

    final parts = raw.split('|');
    if (parts.length < 4) return;

    final usn = parts[1];
    final subjectId = parts[2];
    final enrollmentId = parts[3];

    if (_selectedSubject?.id != subjectId) {
      HapticFeedback.heavyImpact();
      _showFeedback(success: false, message: 'Wrong subject QR!');
      return;
    }

    if (_scannedRecords.any((r) => r.enrollmentId == enrollmentId)) {
      _showFeedback(success: false, message: 'Already scanned this session', isWarning: true);
      return;
    }

    setState(() => _isProcessing = true);
    _scanCtrl?.stop();
    HapticFeedback.mediumImpact();

    try {
      final record = await provider.markAttendance(
        enrollmentId: enrollmentId,
        subject: _selectedSubject!,
      );

      if (record != null && mounted) {
        final matchedStudent = provider.students
            .where((s) => s.usn == usn)
            .firstOrNull;
        final displayName = matchedStudent?.fullName ?? 'USN: $usn';

        final display = AttendanceRecord(
          id: record.id,
          enrollmentId: record.enrollmentId,
          date: record.date,
          status: record.status,
          scannedAt: record.scannedAt,
          minutesLate: record.minutesLate,
          markedAt: record.markedAt,
          remarks: record.remarks,
          studentName: displayName,
          studentUsn: usn,
        );
        setState(() {
          _scannedRecords.insert(0, display);
          _lastScan = display;
        });
        HapticFeedback.lightImpact();
      }
    } on ScheduleValidationException catch (e) {
      // Show the schedule rejection overlay
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _scheduleError = e.message);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() { _scheduleError = null; _isProcessing = false; });
      _scanCtrl?.start();
      return;
    } catch (e) {
      _showFeedback(success: false, message: 'Error marking attendance');
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isProcessing = false);
      _scanCtrl?.start();
    }
  }

  void _showFeedback({required bool success, required String message, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: isWarning ? const Color(0xFFF59E0B) : (success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _endSession(AdminProvider provider) async {
    if (_selectedSubject == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111633),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Session', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              'All students who haven\'t scanned will be marked ABSENT.\n\nThis action cannot be undone.',
              style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 13, height: 1.5),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('End Session', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final count = await provider.markAbsentees(_selectedSubject!.id!);
      if (mounted) {
        _showFeedback(success: true, message: count > 0 ? '$count marked absent' : 'All students accounted for ✓');
        setState(() {
          _isScanning = false;
          _scanCtrl?.dispose();
          _scanCtrl = null;
        });
      }
    } catch (e) {
      _showFeedback(success: false, message: 'Error: $e');
    }
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Attendance Scanner', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text('Select subject then scan student QR codes', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 16),

                // Subject picker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111633),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedSubject != null
                          ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Subject>(
                      value: _selectedSubject,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A2140),
                      hint: Text('— Select Subject —', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
                      items: provider.subjects.map((s) => DropdownMenuItem(
                        value: s,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${s.subjectCode} — ${s.subjectTitle}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                          Text('${s.scheduleDay} ${s.scheduleStartTime} • ${s.room}',
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
                        ]),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _selectedSubject = v;
                        _scannedRecords.clear();
                        _lastScan = null;
                        if (_isScanning) _toggleScanner();
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(children: [
                  Expanded(child: _ActionBtn(
                    icon: _isScanning ? Icons.stop_rounded : Icons.qr_code_scanner_rounded,
                    label: _isScanning ? 'Stop Scan' : 'Start Scan',
                    color: _isScanning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    enabled: _selectedSubject != null,
                    onTap: _toggleScanner,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionBtn(
                    icon: Icons.stop_circle_rounded,
                    label: 'End Session',
                    color: const Color(0xFFF59E0B),
                    enabled: _selectedSubject != null,
                    onTap: () => _endSession(provider),
                  )),
                ]),
              ]),
            ),

            // ── Camera or list ──
            Expanded(child: _isScanning
              ? _buildCameraView(provider)
              : _buildScannedList()),
          ]),
        ),
      ),
    );
  }

  Widget _buildCameraView(AdminProvider provider) {
    return Column(children: [
      // Camera
      Expanded(
        flex: 3,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.15), blurRadius: 20)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              MobileScanner(controller: _scanCtrl!, onDetect: (c) => _handleScan(c, provider)),
              // Corner guides
              _ScanOverlay(),
              // Processing overlay
              if (_isProcessing)
                _buildScanStatus(),
              if (_scheduleError != null)
                _buildScheduleRejection(_scheduleError!),
            ]),
          ),
        ),
      ),

      const SizedBox(height: 8),
      Text('Align QR code within the frame', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11)),
      const SizedBox(height: 8),

      // Recent scans (compact)
      if (_scannedRecords.isNotEmpty)
        Expanded(
          flex: 2,
          child: _buildScannedList(),
        ),
    ]);
  }

  Widget _buildScanStatus() {
    final s = _lastScan;
    final color = s == null
        ? Colors.blue
        : s.isPresent ? const Color(0xFF10B981)
        : s.isLate ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final icon = s == null ? Icons.hourglass_top_rounded
        : s.isPresent ? Icons.check_circle_rounded
        : s.isLate ? Icons.watch_later_rounded
        : Icons.cancel_rounded;
    final msg = s == null ? 'Processing...'
        : s.isPresent ? '✓ PRESENT'
        : s.isLate ? '⚠ LATE — ${s.minutesLate} min'
        : '✗ ABSENT';

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 52),
        const SizedBox(height: 8),
        Text(msg, style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        if (s?.studentName != null)
          Text(s!.studentName!, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        if (s?.studentUsn != null)
          Text('USN: ${s!.studentUsn}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
      ])),
    );
  }

  Widget _buildScheduleRejection(String message) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 2)),
          child: const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 48),
        ),
        const SizedBox(height: 14),
        Text('INVALID SCAN', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
        ),
      ])),
    );
  }

  Widget _buildScannedList() {
    if (_scannedRecords.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.qr_code_2_rounded, color: Colors.grey[700], size: 52),
        const SizedBox(height: 12),
        Text(
          _selectedSubject == null ? 'Select a subject to begin' : 'Start scanning student QR codes',
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
        ),
      ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Scanned (${_scannedRecords.length})',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
          _StatusLegend(),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _scannedRecords.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ScannedTile(record: _scannedRecords[i]),
        ),
      ),
    ]);
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerPainter());
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const l = 30.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    const hw = 90.0;
    const hh = 90.0;

    final corners = [
      [cx - hw, cy - hh, l, 0.0, 0.0, l],
      [cx + hw, cy - hh, -l, 0.0, 0.0, l],
      [cx - hw, cy + hh, l, 0.0, 0.0, -l],
      [cx + hw, cy + hh, -l, 0.0, 0.0, -l],
    ];

    for (final c in corners) {
      canvas.drawPath(Path()
        ..moveTo(c[0] + c[2], c[1])
        ..lineTo(c[0], c[1])
        ..lineTo(c[0], c[1] + c[5]), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _StatusLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _legendDot(const Color(0xFF10B981), 'P'),
      const SizedBox(width: 8),
      _legendDot(const Color(0xFFF59E0B), 'L'),
      const SizedBox(width: 8),
      _legendDot(const Color(0xFFEF4444), 'A'),
    ]);
  }

  Widget _legendDot(Color c, String t) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 3),
    Text(t, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
  ]);
}

class _ScannedTile extends StatelessWidget {
  final AttendanceRecord record;
  const _ScannedTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.isPresent ? const Color(0xFF10B981)
        : record.isLate ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final icon = record.isPresent ? Icons.check_circle_rounded
        : record.isLate ? Icons.watch_later_rounded
        : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111633),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.studentName ?? record.studentUsn ?? record.enrollmentId,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(record.remarks ?? record.statusLabel,
            style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        if (record.scannedAt != null)
          Text(DateFormat('h:mm a').format(record.scannedAt!),
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.14) : Colors.grey[900],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: enabled ? color.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: enabled ? color : Colors.grey[700], size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(
            color: enabled ? color : Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
