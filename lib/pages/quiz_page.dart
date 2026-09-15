import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../models/enrollment_model.dart';
import 'student_modules_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/assessment_model.dart';
import 'take_assessment_page.dart';
import 'assessment_result_page.dart';
import '../widgets/exam_request_dialog.dart';


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
      final prov = context.read<StudentProvider>();
      prov.loadModules();
      prov.loadMyExamRequests();
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
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFEC4899), // Rose
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
    
    Color color = _getColorForSubject(code);
    if (enrollment.subject?.themeColor != null) {
      try {
        final hexString = enrollment.subject!.themeColor!.replaceFirst('#', '');
        color = Color(int.parse(hexString, radix: 16) + 0xFF000000);
      } catch (_) {}
    }

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
    final terms = ['Prelim', 'Midterm', 'Pre-Finals', 'Finals'];
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
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: subjectColor,
                            side: BorderSide(
                                color: subjectColor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 18),
                          label: Text(
                            'Submit Exam Request / Permit',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ExamRequestDialog(
                                enrollment: enrollment,
                                isDark: isDark,
                                primaryColor: subjectColor,
                              ),
                            );
                          },
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
        case 'Pre-Finals': return 'semi_finals';
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

    final activeOrSubmittedAssessments = termAssessments.where((a) {
      final isSubmitted = provider.hasSubmittedLocally(a.id!);
      return isSubmitted || a.isAvailable;
    }).toList();

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
        else if (activeOrSubmittedAssessments.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.grey[500], size: 16),
                const SizedBox(width: 10),
                Text('No active assessments open for submission.', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          )
        else
          ...activeOrSubmittedAssessments.map((assessment) {
            final isExam = assessment.isExam;
            final iconCol = isExam ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
            final icon = isExam ? Icons.school_rounded : Icons.assignment_rounded;
            final isSubmitted = provider.hasSubmittedLocally(assessment.id!);
            final submission = provider.submissionFor(assessment.id!);

            String subtitle;
            if (isSubmitted) {
              subtitle = 'Completed — Tap to view result';
            } else if (assessment.availableUntil != null) {
              subtitle = '${assessment.timeLimitSecs ~/ 60} mins • Closes in ${assessment.remainingAvailabilityFormatted}';
            } else {
              subtitle = '${assessment.timeLimitSecs ~/ 60} mins';
            }

            return GestureDetector(
              onTap: () async {
                if (isSubmitted && submission != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AssessmentResultPage(
                    assessment: assessment,
                    submission: submission,
                    isDark: isDark,
                  )));
                } else {
                  if (!assessment.isAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('The submission window for this assessment has closed.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // For Exams: Check per-term exam permit requirement
                  if (isExam) {
                    final hasPermit = provider.hasExamPermit(
                      subjectId: subject.id!,
                      term: assessment.term,
                      assessmentId: assessment.id,
                    );

                    if (!hasPermit) {
                      _showExamPermitRequiredDialog(
                        context: context,
                        enrollment: enrollment,
                        assessment: assessment,
                        termLabel: term,
                        termCode: termCode,
                        isDark: isDark,
                        primaryColor: subjectColor,
                      );
                      return;
                    }
                  }

                  // Launch TakeAssessmentPage
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TakeAssessmentPage(
                    assessment: assessment,
                    isDark: isDark,
                  )));
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assessment.title,
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!isSubmitted && assessment.availableUntil != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule_rounded, color: Color(0xFF60A5FA), size: 11),
                                      const SizedBox(width: 3),
                                      Text(
                                        assessment.remainingAvailabilityFormatted,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF60A5FA),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: isSubmitted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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

  void _showExamPermitRequiredDialog({
    required BuildContext context,
    required Enrollment enrollment,
    required AssessmentConfig assessment,
    required String termLabel,
    required String termCode,
    required bool isDark,
    required Color primaryColor,
  }) {
    final provider = Provider.of<StudentProvider>(context, listen: false);
    final existingReq = provider.getExamRequestForTerm(
      subjectId: enrollment.subjectId,
      term: assessment.term,
      assessmentId: assessment.id,
    );

    final status = existingReq?.status.toLowerCase();
    final isPending = status == 'submitted';
    final isRejected = status == 'rejected';

    final Color headerColor = isRejected
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    final IconData headerIcon = isRejected
        ? Icons.cancel_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.assignment_late_rounded;

    final String dialogTitle = isRejected
        ? 'Exam Permit Rejected'
        : isPending
            ? 'Permit Pending Approval'
            : 'Exam Permit Required';

    final String mainMessage = isRejected
        ? 'Your exam permit for the $termLabel Exam was rejected by the instructor. Please review your permit photo and proctor details, and resubmit.'
        : isPending
            ? 'Your exam permit for the $termLabel Exam has been submitted and is currently awaiting approval from your instructor.'
            : 'An approved Exam Permit is required before taking the $termLabel Exam for ${enrollment.subjectTitle ?? "this subject"}.';

    final String helpMessage = isRejected
        ? 'Status: REJECTED — Please take a clear photo of your valid exam permit and resubmit.'
        : isPending
            ? 'Status: PENDING APPROVAL — Once your instructor approves your permit, you will be able to start the exam.'
            : 'Please submit your proctor details and permit image to proceed.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(headerIcon, color: headerColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dialogTitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mainMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isRejected
                        ? Icons.error_outline_rounded
                        : isPending
                            ? Icons.timer_outlined
                            : Icons.info_outline_rounded,
                    color: headerColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      helpMessage,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isPending) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              icon: Icon(Icons.refresh_rounded, color: primaryColor, size: 16),
              label: Text(
                'Check Status',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.loadMyExamRequests();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permit status refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 6),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isRejected ? const Color(0xFFEF4444) : primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            label: Text(
              isRejected
                  ? 'Resubmit Permit Now'
                  : isPending
                      ? 'Update / Resubmit'
                      : 'Submit Permit Now',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) => ExamRequestDialog(
                  enrollment: enrollment,
                  initialTerm: termCode,
                  assessmentId: assessment.id,
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}