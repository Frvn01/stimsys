import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/theme_provider.dart';
import '../models/database_helper.dart';
import '../models/models.dart';
import '../screens/qr_scanner_screen.dart';
import '../widgets/cards/course_card.dart';

class CoursesPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const CoursesPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<Map<String, dynamic>> subjects = [
    {
      'name': 'Information Assurance Security 2',
      'id': 'IT6205A',
      'teacher': 'Rens Cardaña',
      'hours': 'Wed 7:30-10:00 AM',
      'color': Colors.blueAccent,
    },
    {
      'name': 'Application Development and Emerging Technologies',
      'id': 'ITE6220',
      'teacher': 'Godfrey Roa',
      'hours': 'Sat 4:00-7:30 PM',
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Database Management Systems 2',
      'id': 'IT6202',
      'teacher': 'Rens Cardaña',
      'hours': 'Fri 10:30-1:00 PM',
      'color': Colors.pinkAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildAddSubjectButton(isDark),
          const SizedBox(height: 20),
          _buildCoursesList(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Courses',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${subjects.length} active courses this semester',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAddSubjectButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _scanQRCode,
        icon: const Icon(Icons.qr_code_scanner, size: 20),
        label: const Text('Add Subject via QR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(bool isDark) {
    return Column(
      children: subjects.map((subject) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _showCourseActionDialog(
              subject['name'],
              subject['teacher'],
              subject['hours'],
              subject['id'],
            ),
            child: CourseCard(
              title: subject['name'],
              instructor: subject['teacher'],
              id: subject['id'],
              hours: subject['hours'],
              color: subject['color'],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _scanQRCode() async {
    String? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null) {
      debugPrint('Scanned QR Code: $result');
      // Parse and add subject logic here
    }
  }

  void _showCourseActionDialog(
    String courseName,
    String instructor,
    String hours,
    String id,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF6366F1).withOpacity(0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.3)
                      : const Color(0xFF6366F1).withOpacity(0.08),
                  width: isDark ? 1.5 : 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
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
                    courseName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCourseInfoCard(isDark, instructor, hours),
                  const SizedBox(height: 20),
                  _buildAttendanceButton(context, courseName),
                  const SizedBox(height: 12),
                  _buildCancelButton(context, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseInfoCard(bool isDark, String instructor, String hours) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF6366F1).withOpacity(0.15)
            : const Color(0xFF6366F1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withOpacity(0.2)
              : const Color(0xFF6366F1).withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            isDark,
            Icons.person_outline,
            'Instructor',
            instructor,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            isDark,
            Icons.schedule,
            'Schedule',
            hours,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    bool isDark,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6366F1).withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(BuildContext context, String courseName) {
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
          _showAttendanceQRCode(courseName);
        },
        icon: const Icon(Icons.qr_code_rounded, size: 20),
        label: const Text('Mark Attendance'),
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

  Widget _buildCancelButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAttendanceQRCode(String courseName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final qrData = 'ATTENDANCE|$courseName|student@email.com|$timestamp';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF6366F1).withOpacity(0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.3)
                      : const Color(0xFF6366F1).withOpacity(0.08),
                  width: isDark ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: Colors.green.shade500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attendance QR Code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                      ),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 180.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan this QR code to mark attendance',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        _markAttendance(courseName, qrData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAttendance(String courseName, String qrData) async {
    try {
      final dbHelper = DatabaseHelper();
      final attendanceRecord = AttendanceRecord(
        courseName: courseName,
        email: 'student@email.com',
        markedAt: DateTime.now(),
        qrCode: qrData,
      );

      await dbHelper.insertAttendanceRecord(attendanceRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance marked successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}