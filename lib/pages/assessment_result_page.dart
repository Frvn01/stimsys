import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/assessment_model.dart';

class AssessmentResultPage extends StatelessWidget {
  final AssessmentConfig assessment;
  final AssessmentSubmission submission;
  final bool isDark;

  const AssessmentResultPage({
    super.key,
    required this.assessment,
    required this.submission,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;
    final subCol = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final accent = const Color(0xFF6366F1);
    final green = const Color(0xFF10B981);

    final passed = submission.maxScore > 0 ? (submission.score / submission.maxScore) * 100 >= 75 : false;
    final color = passed ? green : Colors.red;

    final qrData =
        'STIMSYS_GRADE|${assessment.id}|${submission.studentId}|${submission.score}|${submission.maxScore}|${submission.submittedAt?.toIso8601String() ?? DateTime.now().toIso8601String()}';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: textCol),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Assessment Completed!',
                style: GoogleFonts.inter(
                    color: textCol, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                assessment.title,
                style: GoogleFonts.inter(color: subCol, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 4),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        submission.score.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                            color: color,
                            fontSize: 36,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'out of ${submission.maxScore.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                submission.percentage,
                style: GoogleFonts.inter(
                    color: textCol, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Show this QR code to your instructor',
                      style: GoogleFonts.inter(
                          color: textCol,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To record your grade automatically.',
                      style: GoogleFonts.inter(color: subCol, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: qrData,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back to Dashboard',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
