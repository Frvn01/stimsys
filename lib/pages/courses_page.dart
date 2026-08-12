import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../models/enrollment_model.dart';

class CoursesPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const CoursesPage({super.key, required this.themeProvider});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  bool _scannerOpen = false;
  bool _enrolling = false;
  MobileScannerController? _scanCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      if (provider.enrollments.isEmpty) {
        provider.loadEnrollments();
      }
    });
  }

  @override
  void dispose() {
    _scanCtrl?.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    setState(() {
      _scannerOpen = !_scannerOpen;
      if (_scannerOpen) {
        _scanCtrl = MobileScannerController();
      } else {
        _scanCtrl?.dispose();
        _scanCtrl = null;
      }
    });
  }

  Future<void> _handleEnrollScan(BarcodeCapture capture) async {
    if (_enrolling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.startsWith('STIMSYSENROLL|')) return;
    final parts = raw.split('|');
    if (parts.length < 2) return;
    final subjectId = parts[1];

    setState(() => _enrolling = true);
    _scanCtrl?.stop();

    final provider = context.read<StudentProvider>();
    final (success, message) = await provider.enrollBySubjectQR(subjectId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
      setState(() { _enrolling = false; _scannerOpen = false; });
      _scanCtrl?.dispose();
      _scanCtrl = null;
    }
  }

  final List<Color> _subjectColors = [
    const Color(0xFF6366F1),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final enrollments = provider.enrollments;

        return RefreshIndicator(
          onRefresh: () => provider.loadEnrollments(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark, enrollments.length),
                const SizedBox(height: 16),
                _buildScanBanner(isDark),
                const SizedBox(height: 16),
                if (enrollments.isEmpty)
                  _buildEmptyState(isDark)
                else
                  _buildCoursesList(isDark, enrollments),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: Text('Your Courses',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3))),
          GestureDetector(
            onTap: _toggleScanner,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _scannerOpen
                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                    : const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _scannerOpen
                      ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                      : const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_scannerOpen ? Icons.close_rounded : Icons.qr_code_scanner_rounded,
                  color: _scannerOpen ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 18),
                const SizedBox(width: 6),
                Text(_scannerOpen ? 'Cancel' : 'Scan to Enroll',
                  style: TextStyle(
                    color: _scannerOpen ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text('$count enrolled course${count == 1 ? '' : 's'} this semester',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[600])),
      ],
    );
  }

  Widget _buildScanBanner(bool isDark) {
    if (!_scannerOpen) return const SizedBox.shrink();
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 240,
          child: Stack(children: [
            MobileScanner(
              controller: _scanCtrl!,
              onDetect: _handleEnrollScan,
            ),
            // Overlay frame
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 2),
              ),
            ),
            if (_enrolling)
              Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 12),
                  Text('Enrolling...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ])),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          const Expanded(child: Text('Point camera at the subject enrollment QR shown by your instructor',
            style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      ),
    ]);
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Courses Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your instructor will enroll you in subjects.\nCheck back soon!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(bool isDark, List<Enrollment> enrollments) {
    return Column(
      children: enrollments.asMap().entries.map((entry) {
        final idx = entry.key;
        final enrollment = entry.value;
        final subject = enrollment.subject;
        if (subject == null) return const SizedBox.shrink();

        final color = _subjectColors[idx % _subjectColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _showCourseActionDialog(enrollment, color),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.15),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cast_for_education_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.subjectTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.subjectCode} • ${subject.formattedSchedule}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subject.instructorName ?? 'Instructor',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCourseActionDialog(Enrollment enrollment, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = enrollment.subject!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subjectTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCourseInfoTile(
                    isDark, Icons.code, 'Code', subject.subjectCode, color),
                _buildCourseInfoTile(isDark, Icons.person_outline,
                    'Instructor', subject.instructorName ?? '-', color),
                _buildCourseInfoTile(isDark, Icons.schedule, 'Schedule',
                    subject.formattedSchedule, color),
                _buildCourseInfoTile(
                    isDark, Icons.room, 'Room', subject.room, color),
                _buildCourseInfoTile(isDark, Icons.book, 'Units',
                    '${subject.units}', color),
                const SizedBox(height: 20),
                _buildAttendanceButton(context, enrollment, color),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseInfoTile(
      bool isDark, IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(
      BuildContext context, Enrollment enrollment, Color color) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green.shade500,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          _showAttendanceQRCode(enrollment);
        },
        icon: const Icon(Icons.qr_code_rounded, size: 20),
        label: const Text('Show Attendance QR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showAttendanceQRCode(Enrollment enrollment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = enrollment.subject!;
    final provider = context.read<StudentProvider>();

    // QR data: STIMSYSATT|<USN>|<subject_id>|<enrollment_id>
    final qrData =
        'STIMSYSATT|${provider.usn}|${subject.id}|${enrollment.id}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 40,
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                Text(
                  subject.subjectTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subject.subjectCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
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
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Show this QR to your instructor\nto mark attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}