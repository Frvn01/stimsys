import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class GradesPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const GradesPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  int? _selectedSubjectIndex;

  final List<Map<String, dynamic>> _gradeSubjects = [
    {
      'name': 'Application Development and Emerging Technologies',
      'shortName': 'ADET',
      'grade': 'A',
      'percentage': '92%',
      'gpa': '1.25',
      'color': const Color(0xFF10B981),
      'icon': Icons.code_rounded,
    },
    {
      'name': 'Database Management Systems 2',
      'shortName': 'DBMS 2',
      'grade': 'A-',
      'percentage': '88%',
      'gpa': '1.50',
      'color': const Color(0xFF3B82F6),
      'icon': Icons.storage_rounded,
    },
    {
      'name': 'Information Assurance Security 2',
      'shortName': 'IAS 2',
      'grade': 'B+',
      'percentage': '85%',
      'gpa': '1.75',
      'color': const Color(0xFFF59E0B),
      'icon': Icons.security_rounded,
    },
  ];

  final Map<int, Map<String, dynamic>> _subjectData = {
    0: {
      'quizzes': [
        {'name': 'Prelim Quiz 1', 'score': '18/20', 'date': 'Feb 10'},
        {'name': 'Prelim Quiz 2', 'score': '17/20', 'date': 'Feb 17'},
        {'name': 'Midterm Quiz 1', 'score': '19/20', 'date': 'Mar 5'},
        {'name': 'Midterm Quiz 2', 'score': '20/20', 'date': 'Mar 12'},
        {'name': 'Final Quiz', 'score': '19/20', 'date': 'Apr 8'},
      ],
      'exams': [
        {'name': 'Prelim Exam', 'score': '88/100', 'date': 'Feb 24'},
        {'name': 'Midterm Exam', 'score': '92/100', 'date': 'Mar 19'},
        {'name': 'Final Exam', 'score': '95/100', 'date': 'Apr 15'},
      ],
      'attendance': {'present': 38, 'total': 40, 'percentage': '95%'},
    },
    1: {
      'quizzes': [
        {'name': 'Prelim Quiz 1', 'score': '16/20', 'date': 'Feb 10'},
        {'name': 'Prelim Quiz 2', 'score': '15/20', 'date': 'Feb 17'},
        {'name': 'Midterm Quiz 1', 'score': '18/20', 'date': 'Mar 5'},
        {'name': 'Midterm Quiz 2', 'score': '19/20', 'date': 'Mar 12'},
        {'name': 'Final Quiz', 'score': '17/20', 'date': 'Apr 8'},
      ],
      'exams': [
        {'name': 'Prelim Exam', 'score': '85/100', 'date': 'Feb 24'},
        {'name': 'Midterm Exam', 'score': '90/100', 'date': 'Mar 19'},
        {'name': 'Final Exam', 'score': '93/100', 'date': 'Apr 15'},
      ],
      'attendance': {'present': 36, 'total': 40, 'percentage': '90%'},
    },
    2: {
      'quizzes': [
        {'name': 'Prelim Quiz 1', 'score': '14/20', 'date': 'Feb 10'},
        {'name': 'Prelim Quiz 2', 'score': '13/20', 'date': 'Feb 17'},
        {'name': 'Midterm Quiz 1', 'score': '16/20', 'date': 'Mar 5'},
        {'name': 'Midterm Quiz 2', 'score': '17/20', 'date': 'Mar 12'},
        {'name': 'Final Quiz', 'score': '15/20', 'date': 'Apr 8'},
      ],
      'exams': [
        {'name': 'Prelim Exam', 'score': '80/100', 'date': 'Feb 24'},
        {'name': 'Midterm Exam', 'score': '85/100', 'date': 'Mar 19'},
        {'name': 'Final Exam', 'score': '88/100', 'date': 'Apr 15'},
      ],
      'attendance': {'present': 34, 'total': 40, 'percentage': '85%'},
    },
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double overallGpa = _gradeSubjects
            .map((s) => double.parse(s['gpa']))
            .reduce((a, b) => a + b) /
        _gradeSubjects.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 20),
          _buildGPABanner(isDark, overallGpa),
          const SizedBox(height: 24),
          _buildSubjectLabel(isDark),
          const SizedBox(height: 12),
          ..._buildSubjectCards(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Grades',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Current semester performance',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildGPABanner(bool isDark, double overallGpa) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF6366F1).withOpacity(0.3),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                ]
              : [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall GPA',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  overallGpa.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_gradeSubjects.length} subjects enrolled',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectLabel(bool isDark) {
    return Text(
      'Subject Breakdown',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
        letterSpacing: 0.2,
      ),
    );
  }

  List<Widget> _buildSubjectCards(bool isDark) {
    return _gradeSubjects.asMap().entries.map((entry) {
      final idx = entry.key;
      final subject = entry.value;
      final isExpanded = _selectedSubjectIndex == idx;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildGradeSubjectCard(
          isDark: isDark,
          index: idx,
          name: subject['name'],
          shortName: subject['shortName'],
          grade: subject['grade'],
          percentage: subject['percentage'],
          gpa: subject['gpa'],
          color: subject['color'],
          icon: subject['icon'],
          isExpanded: isExpanded,
        ),
      );
    }).toList();
  }

  Widget _buildGradeSubjectCard({
    required bool isDark,
    required int index,
    required String name,
    required String shortName,
    required String grade,
    required String percentage,
    required String gpa,
    required Color color,
    required IconData icon,
    required bool isExpanded,
  }) {
    final data = _subjectData[index]!;
    final attendance = data['attendance'] as Map<String, dynamic>;
    final quizzes = data['quizzes'] as List;
    final exams = data['exams'] as List;
    final int present = attendance['present'];
    final int total = attendance['total'];
    final double attendanceRatio = present / total;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubjectIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? color.withOpacity(0.6)
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isExpanded ? 16 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildCardHeader(
              isDark,
              name,
              shortName,
              grade,
              percentage,
              gpa,
              color,
              icon,
              isExpanded,
            ),
            _buildProgressBar(isDark, percentage, color, isExpanded),
            _buildExpandedDetails(
              isDark,
              isExpanded,
              color,
              attendance,
              quizzes,
              exams,
              attendanceRatio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    bool isDark,
    String name,
    String shortName,
    String grade,
    String percentage,
    String gpa,
    Color color,
    IconData icon,
    bool isExpanded,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        shortName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GPA $gpa',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    bool isDark,
    String percentage,
    Color color,
    bool isExpanded,
  ) {
    return ClipRRect(
      borderRadius: isExpanded
          ? BorderRadius.zero
          : const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: LinearProgressIndicator(
        value: double.parse(percentage.replaceAll('%', '')) / 100,
        backgroundColor:
            isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
        minHeight: 3,
      ),
    );
  }

  Widget _buildExpandedDetails(
    bool isDark,
    bool isExpanded,
    Color color,
    Map<String, dynamic> attendance,
    List quizzes,
    List exams,
    double attendanceRatio,
  ) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 350),
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.shade100,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownSection(
                  isDark: isDark,
                  color: color,
                  icon: Icons.how_to_reg_rounded,
                  label: 'Attendance',
                  child: _buildAttendanceContent(
                    isDark,
                    attendance,
                    attendanceRatio,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDropdownSection(
                  isDark: isDark,
                  color: const Color(0xFF6366F1),
                  icon: Icons.assignment_outlined,
                  label: 'Quiz Performance',
                  child: _buildScoreList(isDark, quizzes),
                ),
                const SizedBox(height: 12),
                _buildDropdownSection(
                  isDark: isDark,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.school_outlined,
                  label: 'Exam Performance',
                  child: _buildScoreList(isDark, exams),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent(
    bool isDark,
    Map<String, dynamic> attendance,
    double attendanceRatio,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Classes Attended',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '${attendance['present']}/${attendance['total']}  (${attendance['percentage']})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: attendanceRatio,
            backgroundColor:
                isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreList(bool isDark, List scores) {
    return Column(
      children: scores.asMap().entries.map((entry) {
        final idx = entry.key;
        final score = entry.value;
        return _buildDetailRow(
          isDark: isDark,
          name: score['name'],
          score: score['score'],
          date: score['date'],
          isLast: idx == scores.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildDropdownSection({
    required bool isDark,
    required Color color,
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required String name,
    required String score,
    required String date,
    required bool isLast,
  }) {
    double ratio = 0;
    try {
      final parts = score.split('/');
      ratio = double.parse(parts[0]) / double.parse(parts[1]);
    } catch (_) {}

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                score,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor:
                isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio >= 0.9
                  ? Colors.green
                  : ratio >= 0.75
                      ? const Color(0xFF6366F1)
                      : Colors.orange,
            ),
            minHeight: 4,
          ),
        ),
        if (!isLast)
          Divider(
            height: 16,
            color:
                isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          ),
      ],
    );
  }
}