import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/cards/activity_card.dart';
import 'package:stimsys/screens/logic_file.dart';
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
    final usn = context.watch<StudentManagement>().usn; // ← get usn here
    final lastName = context.watch<StudentManagement>().lastName;
    

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, lastName), // ← pass usn
          const SizedBox(height: 32),
          _buildAcademicOverview(isDark),
          const SizedBox(height: 24),
          _buildRecentActivity(isDark),
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
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
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

  Widget _buildAcademicOverview(bool isDark) {
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
          _buildStatRow(isDark, 'Active Courses', '5', const Color(0xFF6366F1)),
          const SizedBox(height: 12),
          _buildStatRow(isDark, 'Missed Tasks', '3', const Color(0xFF8B5CF6)),
          const SizedBox(height: 12),
          _buildStatRow(isDark, 'Current GPA', '3.8', const Color(0xFFA855F7)),
          const SizedBox(height: 12),
          _buildStatRow(isDark, 'Attendance', '95%', const Color(0xFF10B981)),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
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

  Widget _buildRecentActivity(bool isDark) {
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
        ActivityCard(
          title: 'Assignment Submitted',
          description: 'Information Assurance Security 2',
          time: '2h ago',
          icon: Icons.assessment_rounded,
        ),
        const SizedBox(height: 10),
        ActivityCard(
          title: 'Grade Posted',
          description: 'ADET Quiz 2: 92/100',
          time: '1d ago',
          icon: Icons.grade_rounded,
        ),
        const SizedBox(height: 10),
        ActivityCard(
          title: 'Course Updated',
          description: 'Database Management Systems 2',
          time: '3d ago',
          icon: Icons.update_rounded,
        ),
      ],
    );
  }
}