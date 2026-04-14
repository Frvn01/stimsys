import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';

class GradesPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const GradesPage({super.key, required this.themeProvider});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Refresh attendance data when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final enrollments = provider.enrollments;
        final allAttendance = provider.attendanceRecords;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 20),
              _buildAttendanceBanner(isDark, allAttendance, enrollments.length),
              const SizedBox(height: 24),
              _buildSectionLabel('Subject Breakdown', isDark),
              const SizedBox(height: 12),
              if (provider.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ))
              else if (enrollments.isEmpty)
                _buildEmptyState(isDark)
              else
                ...enrollments.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final enrollment = entry.value;
                  final subjectAttendance = _getAttendanceForEnrollment(
                    allAttendance, enrollment.id ?? '');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SubjectCard(
                      isDark: isDark,
                      enrollment: enrollment,
                      attendance: subjectAttendance,
                      isExpanded: _selectedIndex == idx,
                      onTap: () => setState(() =>
                          _selectedIndex = _selectedIndex == idx ? null : idx),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  List<AttendanceRecord> _getAttendanceForEnrollment(
      List<AttendanceRecord> all, String enrollmentId) {
    return all.where((a) => a.enrollmentId == enrollmentId).toList();
  }

  Widget _buildHeader(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('My Grades',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      const SizedBox(height: 4),
      Text('Attendance & subject performance',
        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[600])),
    ]);
  }

  Widget _buildAttendanceBanner(bool isDark, List<AttendanceRecord> all, int subjectCount) {
    final present = all.where((r) => r.isPresent).length;
    final late = all.where((r) => r.isLate).length;
    final absent = all.where((r) => r.isAbsent).length;
    final total = all.length;
    final rate = total == 0 ? 0.0 : (present + late) / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF6366F1).withValues(alpha: 0.28), const Color(0xFF8B5CF6).withValues(alpha: 0.18)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overall Attendance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Text('${(rate * 100).round()}%',
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            Text('$subjectCount subject${subjectCount != 1 ? 's' : ''} enrolled',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          ])),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 28),
          ),
        ]),
        const SizedBox(height: 16),
        // Mini stat row
        Row(children: [
          _bannerStat('Present', present, const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _bannerStat('Late', late, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _bannerStat('Absent', absent, const Color(0xFFEF4444)),
        ]),
        const SizedBox(height: 14),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: rate,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _bannerStat(String label, int count, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(color: color == const Color(0xFF10B981) ? Colors.white : color, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: isDark ? Colors.grey[300] : Colors.grey[700], letterSpacing: 0.2));
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
      ),
      child: Column(children: [
        Icon(Icons.book_outlined, color: Colors.grey[400], size: 40),
        const SizedBox(height: 12),
        Text('No subjects enrolled yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(height: 4),
        Text('Contact your instructor to enroll', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }
}

// ─── Subject Card ───────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final bool isDark;
  final Enrollment enrollment;
  final List<AttendanceRecord> attendance;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.isDark,
    required this.enrollment,
    required this.attendance,
    required this.isExpanded,
    required this.onTap,
  });

  static const _colors = [
    Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFFEF4444),
  ];

  Color get _color {
    final idx = (enrollment.subjectCode?.hashCode ?? 0).abs() % _colors.length;
    return _colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final present = attendance.where((r) => r.isPresent).length;
    final late = attendance.where((r) => r.isLate).length;
    final absent = attendance.where((r) => r.isAbsent).length;
    final total = attendance.length;
    final rate = total == 0 ? 0.0 : (present + late) / total;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? color.withValues(alpha: 0.5) : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(
            color: isExpanded ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
            blurRadius: isExpanded ? 16 : 6,
            offset: const Offset(0, 4),
          )],
        ),
        child: Column(children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(Icons.book_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(enrollment.subjectTitle ?? 'Unknown Subject',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(enrollment.subjectCode ?? '-',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(width: 8),
                  Text(enrollment.scheduleDay != null ? '${enrollment.scheduleDay}' : '',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[500])),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${(rate * 100).round()}%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[500]),
                ),
              ]),
            ]),
          ),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: isExpanded ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
              minHeight: 3,
            ),
          ),

          // ── Expanded details ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(children: [
                _divider(isDark),
                const SizedBox(height: 12),
                // Attendance section — real data
                _Section(
                  isDark: isDark, color: const Color(0xFF10B981),
                  icon: Icons.how_to_reg_rounded, label: 'Attendance',
                  child: _AttendanceContent(
                    isDark: isDark,
                    present: present, late: late, absent: absent, total: total, rate: rate,
                  ),
                ),
                const SizedBox(height: 12),
                // Quiz — coming soon
                _Section(
                  isDark: isDark, color: const Color(0xFF6366F1),
                  icon: Icons.assignment_outlined, label: 'Quiz Performance',
                  child: _ComingSoon(isDark: isDark),
                ),
                const SizedBox(height: 12),
                // Exam — coming soon
                _Section(
                  isDark: isDark, color: const Color(0xFFF59E0B),
                  icon: Icons.school_outlined, label: 'Exam Performance',
                  child: _ComingSoon(isDark: isDark),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Row(children: [
      Expanded(child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text('Details', style: TextStyle(fontSize: 11,
          color: isDark ? Colors.grey[500] : Colors.grey[400], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
      Expanded(child: Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100)),
    ]);
  }
}

// ── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final bool isDark;
  final Color color;
  final IconData icon;
  final String label;
  final Widget child;

  const _Section({required this.isDark, required this.color, required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[200] : Colors.grey[800], letterSpacing: 0.1)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

// ── Live attendance content ──────────────────────────────────────────────────

class _AttendanceContent extends StatelessWidget {
  final bool isDark;
  final int present, late, absent, total;
  final double rate;

  const _AttendanceContent({
    required this.isDark, required this.present, required this.late,
    required this.absent, required this.total, required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Text('No attendance records yet.',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]));
    }

    return Column(children: [
      // Stat chips row
      Row(children: [
        _chip(isDark, 'Present', present, const Color(0xFF10B981), Icons.check_circle_rounded),
        const SizedBox(width: 8),
        _chip(isDark, 'Late', late, const Color(0xFFF59E0B), Icons.watch_later_rounded),
        const SizedBox(width: 8),
        _chip(isDark, 'Absent', absent, const Color(0xFFEF4444), Icons.cancel_rounded),
      ]),
      const SizedBox(height: 12),

      // Classes attended text
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Total sessions', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        Text('$total classes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87)),
      ]),
      const SizedBox(height: 10),

      // Color-segmented progress bar
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(children: [
          _progressBar(present, total, const Color(0xFF10B981)),
          _progressBar(late, total, const Color(0xFFF59E0B)),
          _progressBar(absent, total, const Color(0xFFEF4444)),
          if (total == 0)
            Expanded(child: Container(height: 8, color: Colors.grey[200])),
        ]),
      ),

      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Attendance rate', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[500])),
        Text('${(rate * 100).round()}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: rate >= 0.8 ? const Color(0xFF10B981) : rate >= 0.6 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))),
      ]),
    ]);
  }

  Widget _chip(bool isDark, String label, int count, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 3),
        Text('$count', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _progressBar(int count, int total, Color color) {
    if (count == 0 || total == 0) return const SizedBox.shrink();
    return Expanded(
      flex: count,
      child: Container(height: 8, color: color),
    );
  }
}

// ── Coming soon panel ────────────────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final bool isDark;
  const _ComingSoon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(children: [
        Icon(Icons.rocket_launch_rounded, color: const Color(0xFF6366F1).withValues(alpha: 0.5), size: 28),
        const SizedBox(height: 8),
        const Text('Coming Soon', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
        const SizedBox(height: 4),
        Text('This feature is being developed', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
    );
  }
}