import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../models/enrollment_model.dart';
import 'student_modules_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'take_assessment_page.dart';
import 'assessment_result_page.dart';
import '../screens/qr_scanner_screen.dart';

class QuizPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const QuizPage({
    super.key,
    required this.themeProvider,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadModules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final enrollments = provider.enrollments;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 24),
              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                )
              else if (enrollments.isEmpty)
                _buildEmptyState(isDark)
              else
                ...enrollments.map((enrollment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCourseCard(
                      context,
                      isDark,
                      enrollment,
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

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, color: Colors.grey[400], size: 40),
          const SizedBox(height: 12),
          Text(
            'No subjects enrolled',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Enroll in subjects to view assessments',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz & Exams',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a subject to view assessments',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  static const _cardColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
  ];

  Color _getColorForSubject(String code) {
    final idx = code.hashCode.abs() % _cardColors.length;
    return _cardColors[idx];
  }

  Widget _buildCourseCard(
    BuildContext context,
    bool isDark,
    Enrollment enrollment,
  ) {
    final title = enrollment.subjectTitle ?? 'Unknown Subject';
    final instructor =
        enrollment.subject?.instructorName ?? 'Unknown Instructor';
    final code = enrollment.subjectCode ?? '';
    final color = _getColorForSubject(code);

    return GestureDetector(
      onTap: () async {
        final provider = context.read<StudentProvider>();
        showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: color)));
        await provider.loadAvailableAssessments(enrollment.subjectId!);
        await provider.loadMySubmissions(enrollment.subjectId!);
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) _showAssessmentsDialog(context, enrollment, isDark, color);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.book_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              code,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instructor,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssessmentsDialog(
    BuildContext context,
    Enrollment enrollment,
    bool isDark,
    Color subjectColor,
  ) {
    final terms = ['Prelim', 'Midterm', 'Semi-Finals', 'Finals'];
    final subjectTitle = enrollment.subjectTitle ?? 'Unknown Subject';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectTitle,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select an assessment to begin',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: terms.map((term) {
                        return _buildTermSection(
                          ctx,
                          enrollment,
                          term,
                          isDark,
                          subjectColor,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTermSection(
    BuildContext context,
    Enrollment enrollment,
    String term,
    bool isDark,
    Color subjectColor,
  ) {
    final subject = enrollment.subject!;
    final subjectIdentifier = '${subject.subjectCode} — ${subject.subjectTitle}';

    String getTermCode(String t) {
      switch (t) {
        case 'Prelim': return 'prelim';
        case 'Midterm': return 'midterm';
        case 'Semi-Finals': return 'semi_finals';
        case 'Finals': return 'finals';
        default: return t.toLowerCase();
      }
    }

    final termCode = getTermCode(term);
    final provider = context.watch<StudentProvider>();
    final isUnlocked = provider.isTermUnlocked(subject.id!, termCode);
    final termAssessments = provider.assessmentsForTerm(subject.id!, termCode);
    final moduleCount = provider.modules
        .where((m) => m.subject == subjectIdentifier && m.term == termCode)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                term,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              if (!isUnlocked) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_rounded, color: Colors.grey[500], size: 14),
                const SizedBox(width: 4),
                Text('Locked', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        
        // Modules Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // pop assessments dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentModulesScreen(
                  subjectCode: subject.subjectCode,
                  subjectTitle: subject.subjectTitle,
                  subjectIdentifier: subjectIdentifier,
                  initialTerm: termCode,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: subjectColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subjectColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_copy_rounded, color: subjectColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Learning Modules', style: GoogleFonts.inter(color: subjectColor, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('$moduleCount Material${moduleCount == 1 ? "" : "s"} available', style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: subjectColor, size: 20),
              ],
            ),
          ),
        ),

        // Assessments List
        if (!isUnlocked)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.transparent : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.grey[500], size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('Complete previous terms to unlock assessments.', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12))),
              ],
            ),
          )
        else if (termAssessments.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.grey[500], size: 16),
                const SizedBox(width: 10),
                Text('No assessments yet for this term.', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          )
        else
          ...termAssessments.map((assessment) {
            final isExam = assessment.isExam;
            final iconCol = isExam ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
            final icon = isExam ? Icons.school_rounded : Icons.assignment_rounded;
            final isSubmitted = provider.hasSubmittedLocally(assessment.id!);
            final submission = provider.submissionFor(assessment.id!);

            return GestureDetector(
              onTap: () async {
                if (isSubmitted && submission != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentResultPage(
                    assessment: assessment,
                    submission: submission,
                    isDark: isDark,
                  )));
                } else {
                  final code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                  );
                  if (code != null && context.mounted) {
                    final parts = code.split('|');
                    if (parts.length >= 4 && parts[0] == 'STIMSYS_EXAM' && parts[1] == assessment.id) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TakeAssessmentPage(
                        assessment: assessment,
                        isDark: isDark,
                        prefilledSessionCode: parts[3],
                      )));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or mismatched Exam QR Code'), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSubmitted ? const Color(0xFF10B981) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSubmitted ? const Color(0xFF10B981).withValues(alpha: 0.1) : iconCol.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(isSubmitted ? Icons.check_rounded : icon, color: isSubmitted ? const Color(0xFF10B981) : iconCol, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assessment.title, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(isSubmitted ? 'Completed — Tap to view result' : '${assessment.timeLimitSecs ~/ 60} mins', style: GoogleFonts.inter(color: isSubmitted ? const Color(0xFF10B981) : (isDark ? Colors.grey[400] : Colors.grey[600]), fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[600] : Colors.grey[400], size: 20),
                  ],
                ),
              ),
            );
          }).toList(),

        const SizedBox(height: 12),
        Divider(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
        ),
      ],
    );
  }
}