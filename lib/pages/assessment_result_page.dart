import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/assessment_model.dart';
import '../providers/student_provider.dart';

class AssessmentResultPage extends StatefulWidget {
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
  State<AssessmentResultPage> createState() => _AssessmentResultPageState();
}

class _AssessmentResultPageState extends State<AssessmentResultPage> {
  late AssessmentSubmission _submission;

  @override
  void initState() {
    super.initState();
    _submission = widget.submission;
  }

  void _showAppealDialog() {
    final reasonCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = widget.isDark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('File an Appeal',
                      style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explain why you believe this invalidation was unfair. Your instructor will review your appeal.',
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. I accidentally switched tabs to check the time...',
                    hintStyle: GoogleFonts.inter(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 13),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (reasonCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Please provide a reason'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() => isSending = true);
                        try {
                          await this
                              .context
                              .read<StudentProvider>()
                              .submitAppeal(
                                  _submission.id!, reasonCtrl.text.trim());
                          if (mounted) {
                            Navigator.pop(ctx);
                            this.setState(() {
                              _submission = _submission.copyWith(
                                  appealStatus: 'pending',
                                  appealReason: reasonCtrl.text.trim());
                            });
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Appeal submitted successfully!',
                                    style:
                                        GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to submit appeal'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isSending = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B)),
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Submit Appeal',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
    final surface = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = widget.isDark ? Colors.white : Colors.black87;
    final subCol = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final accent = const Color(0xFF6366F1);
    final green = const Color(0xFF10B981);

    final isInvalidated = _submission.isInvalidated;
    final passed = !isInvalidated &&
        _submission.maxScore > 0 &&
        (_submission.score / _submission.maxScore) * 100 >= 75;
    final color = isInvalidated ? Colors.red : (passed ? green : Colors.red);

    final qrData =
        'STIMSYS_GRADE|${widget.assessment.id}|${_submission.studentId}|${_submission.score}|${_submission.maxScore}|${_submission.submittedAt?.toIso8601String() ?? DateTime.now().toIso8601String()}';

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
              // ── Invalidated Banner ──
              if (isInvalidated) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assessment Invalidated',
                                style: GoogleFonts.inter(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              'Your score was set to 0 due to suspicious activity (tab switching / minimizing).',
                              style: GoogleFonts.inter(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                isInvalidated ? 'Assessment Invalidated' : 'Assessment Completed!',
                style: GoogleFonts.inter(
                    color: textCol, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                widget.assessment.title,
                style: GoogleFonts.inter(color: subCol, fontSize: 14),
              ),
              const SizedBox(height: 32),

              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border:
                      Border.all(color: color.withValues(alpha: 0.3), width: 4),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _submission.score.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                            color: color,
                            fontSize: 36,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'out of ${_submission.maxScore.toStringAsFixed(0)}',
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
                _submission.percentage,
                style: GoogleFonts.inter(
                    color: textCol, fontSize: 20, fontWeight: FontWeight.w700),
              ),

              // ── Appeal Status Section ──
              if (isInvalidated) ...[
                const SizedBox(height: 32),
                if (_submission.appealStatus == 'none')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showAppealDialog,
                      icon: const Icon(Icons.gavel_rounded, size: 18),
                      label: Text('File an Appeal',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else if (_submission.appealStatus == 'pending')
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            color: Color(0xFFF59E0B), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appeal Pending',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFFF59E0B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                'Your instructor is reviewing your appeal.',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.8),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_submission.appealStatus == 'rejected')
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appeal Rejected',
                                  style: GoogleFonts.inter(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                'Your appeal has been reviewed and rejected by your instructor.',
                                style: GoogleFonts.inter(
                                    color: Colors.red.withValues(alpha: 0.8),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // ── QR Code Section (only if NOT invalidated) ──
              if (!isInvalidated) ...[
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!widget.isDark)
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
              ],

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
