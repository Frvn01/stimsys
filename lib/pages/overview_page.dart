import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/cards/activity_card.dart';
import '../providers/student_provider.dart';
import 'package:provider/provider.dart';

class OverviewPage extends StatelessWidget {
  final String email;
  final ThemeProvider themeProvider;

  const OverviewPage({
    super.key,
    required this.email,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final lastName = provider.currentStudent?.lastName ?? '-';
    final enrollmentCount = provider.enrollments.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, lastName),
          const SizedBox(height: 32),
          _buildAcademicOverview(isDark, enrollmentCount),
          const SizedBox(height: 24),
          _buildRecentActivity(isDark, provider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String lastName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, $lastName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 18,
              color: isDark ? Colors.yellow[300] : Colors.orange[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicOverview(bool isDark, int enrollmentCount) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(isDark, 'Active Courses', '$enrollmentCount', const Color(0xFF6366F1)),
          const SizedBox(height: 12),
          _buildStatRow(isDark, 'Current GPA', '-', const Color(0xFFA855F7)),
          const SizedBox(height: 12),
          _buildStatRow(isDark, 'Attendance', '-', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildStatRow(bool isDark, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.check_circle, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isDark, StudentProvider provider) {
    // Collect all activities
    final List<Map<String, dynamic>> activities = [];

    // 1. Account Created
    if (provider.currentStudent?.createdAt != null) {
      activities.add({
        'title': 'Account Created',
        'description': provider.currentStudent!.isConfirmed 
            ? 'Registered and confirmed' 
            : 'Registered (Pending confirmation)',
        'date': provider.currentStudent!.createdAt!,
        'icon': Icons.person_add_rounded,
      });
    }

    // 2. Enrollments
    for (var enrollment in provider.enrollments) {
      if (enrollment.enrolledAt != null) {
        activities.add({
          'title': 'Enrolled in Subject',
          'description': enrollment.subjectTitle ?? 'Unknown Subject',
          'date': enrollment.enrolledAt!,
          'icon': Icons.bookmark_added_rounded,
        });
      }
    }

    // 3. Attendance
    for (var record in provider.attendanceRecords) {
      final date = record.markedAt ?? record.date;
      activities.add({
        'title': 'Attendance Marked',
        'description': '${record.statusLabel} for ${record.subjectTitle ?? record.subjectCode ?? "Subject"}',
        'date': date,
        'icon': Icons.how_to_reg_rounded,
      });
    }

    // Sort by date descending
    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No recent activity',
                style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
              ),
            ),
          )
        else
          ...activities.take(5).map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActivityCard(
                title: activity['title'],
                description: activity['description'],
                time: _formatTimeAgo(activity['date'] as DateTime),
                icon: activity['icon'],
              ),
            );
          }),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y ago';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}