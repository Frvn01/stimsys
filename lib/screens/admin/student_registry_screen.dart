import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/admin_provider.dart';
import '../../models/student_model.dart';

class StudentRegistryScreen extends StatefulWidget {
  const StudentRegistryScreen({super.key});

  @override
  State<StudentRegistryScreen> createState() => _StudentRegistryScreenState();
}

class _StudentRegistryScreenState extends State<StudentRegistryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterCourse = 'All';
  bool _showScanner = false;
  bool _isProcessingScan = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onQRDetected(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final raw = barcode!.rawValue!;
    if (!raw.startsWith('STIMSYSREG|')) return;

    setState(() => _isProcessingScan = true);

    // Format: STIMSYSREG|usn|lastName|firstName|middleName|course|yearSection|date
    final parts = raw.split('|');
    if (parts.length < 7) {
      _showResult(success: false, message: 'Invalid registration QR code');
      setState(() => _isProcessingScan = false);
      return;
    }

    final usn = parts[1];
    final provider = context.read<AdminProvider>();

    // Find student by USN in already-loaded list
    final match = provider.students.where((s) => s.usn == usn).firstOrNull;

    if (match == null) {
      _showResult(success: false, message: 'Student USN: $usn not found in system');
      setState(() => _isProcessingScan = false);
      return;
    }

    if (match.isConfirmed) {
      _showResult(
        success: false,
        message: '${match.fullName} is already confirmed',
        isWarning: true,
      );
      setState(() => _isProcessingScan = false);
      return;
    }

    try {
      await provider.confirmStudent(match.id!);
      _showResult(
        success: true,
        message: '${match.fullName} confirmed!',
        detail: 'USN: ${match.usn} • ${match.course} ${match.yearSection}',
      );
      // Switch to list tab to show confirmed student
      _tabController.animateTo(0);
    } catch (e) {
      _showResult(success: false, message: 'Failed to confirm student');
    }

    setState(() => _isProcessingScan = false);
  }

  void _showResult({
    required bool success,
    required String message,
    String? detail,
    bool isWarning = false,
  }) {
    final color = isWarning
        ? const Color(0xFFF59E0B)
        : success
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF111633),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(
                isWarning ? Icons.warning_amber_rounded : success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: color, size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(message,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(detail,
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('OK', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        var students = provider.students;
        if (_filterCourse != 'All') {
          students = students.where((s) => s.course == _filterCourse).toList();
        }
        if (_searchQuery.isNotEmpty) {
          students = students
              .where((s) =>
                  s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.usn.contains(_searchQuery))
              .toList();
        }

        final pending = students.where((s) => !s.isConfirmed).toList();
        final confirmed = students.where((s) => s.isConfirmed).toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E21),
          body: SafeArea(
            child: Column(
              children: [
                // ─── Header ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student Registry',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                Text('${provider.totalStudents} registered • ${provider.confirmedStudents} confirmed',
                                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          // QR Scan Button
                          GestureDetector(
                            onTap: () => setState(() => _showScanner = !_showScanner),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _showScanner
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: Row(children: [
                                Icon(
                                  _showScanner ? Icons.close_rounded : Icons.qr_code_scanner_rounded,
                                  color: _showScanner ? Colors.white : const Color(0xFF10B981),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _showScanner ? 'Close' : 'Scan QR',
                                  style: GoogleFonts.inter(
                                    color: _showScanner ? Colors.white : const Color(0xFF10B981),
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Scanner area
                      if (_showScanner) ...[
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              MobileScanner(onDetect: _onQRDetected),
                              // Scan overlay hint
                              Center(
                                child: Container(
                                  width: 150, height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              if (_isProcessingScan)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Scan student\'s registration QR to confirm',
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Search
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111633),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by name or USN...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', ...StudentConstants.courses].map((course) {
                            final isActive = _filterCourse == course;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _filterCourse = course),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFF6366F1) : const Color(0xFF111633),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isActive ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Text(course,
                                    style: GoogleFonts.inter(
                                      color: isActive ? Colors.white : Colors.grey[500],
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111633),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[500],
                          tabs: [
                            Tab(text: 'All (${students.length})'),
                            Tab(text: 'Pending (${pending.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ─── List ───
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _StudentList(
                        students: students,
                        onConfirm: (s) => provider.confirmStudent(s.id!),
                        onDelete: (s) => _confirmDelete(context, provider, s),
                      ),
                      _StudentList(
                        students: pending,
                        onConfirm: (s) => provider.confirmStudent(s.id!),
                        onDelete: (s) => _confirmDelete(context, provider, s),
                        emptyMessage: 'No pending students',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AdminProvider provider, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111633),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Student', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove ${student.fullName} (${student.usn})? This cannot be undone.',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () {
              provider.deleteStudent(student.id!);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  final List<Student> students;
  final Future<void> Function(Student) onConfirm;
  final void Function(Student) onDelete;
  final String emptyMessage;

  const _StudentList({
    required this.students,
    required this.onConfirm,
    required this.onDelete,
    this.emptyMessage = 'No students found',
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: Colors.grey[700], size: 48),
            const SizedBox(height: 12),
            Text(emptyMessage, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final student = students[index];
        return _StudentTile(student: student, onConfirm: onConfirm, onDelete: onDelete);
      },
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final Future<void> Function(Student) onConfirm;
  final void Function(Student) onDelete;

  const _StudentTile({
    required this.student,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = student.isConfirmed;
    final accentColor = isConfirmed ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111633),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                student.firstName[0].toUpperCase(),
                style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('USN: ${student.usn} • ${student.course} ${student.yearSection}',
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isConfirmed ? 'Confirmed' : 'Pending',
              style: GoogleFonts.inter(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(width: 8),

          // Actions
          if (!isConfirmed)
            GestureDetector(
              onTap: () => onConfirm(student),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
              ),
            ),

          const SizedBox(width: 6),

          GestureDetector(
            onTap: () => onDelete(student),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.grey[600], size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
