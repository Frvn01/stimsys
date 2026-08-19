import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../models/assessment_model.dart';

class DesktopAppealsScreen extends StatefulWidget {
  const DesktopAppealsScreen({super.key});

  @override
  State<DesktopAppealsScreen> createState() => _DesktopAppealsScreenState();
}

class _DesktopAppealsScreenState extends State<DesktopAppealsScreen> {
  bool _loading = true;

  // ── Design tokens ─────────────────────────────────
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A2235);
  static const _border = Color(0xFF232D3F);
  static const _accent = Color(0xFF6366F1);
  static const _amber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadAppeals();
  }

  Future<void> _loadAppeals() async {
    setState(() => _loading = true);
    await context.read<AdminProvider>().loadPendingAppeals();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final appeals = provider.pendingAppeals;

    return Scaffold(
      backgroundColor: _bg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: _amber, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Appeals',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${appeals.length} pending appeal${appeals.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                          color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loadAppeals,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text('Refresh',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                    side: BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Content ──
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _accent))
                  : appeals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  color: Colors.grey[700], size: 64),
                              const SizedBox(height: 16),
                              Text('No pending appeals',
                                  style: GoogleFonts.inter(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'All student appeals have been resolved.',
                                style: GoogleFonts.inter(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: appeals.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) =>
                              _buildAppealCard(appeals[i], provider),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppealCard(
      AssessmentSubmission appeal, AdminProvider provider) {
    final submittedAt = appeal.submittedAt != null
        ? DateFormat('MMM d, yyyy – h:mm a').format(appeal.submittedAt!)
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Student + Assessment Info ──
          Row(
            children: [
              // Student avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (appeal.studentName?.isNotEmpty == true)
                        ? appeal.studentName![0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        color: _accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appeal.studentName ?? 'Unknown Student',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appeal.studentUsn ?? '',
                      style: GoogleFonts.inter(
                          color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Assessment badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_rounded,
                        color: _amber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      appeal.assessmentTitle ?? 'Assessment',
                      style: GoogleFonts.inter(
                          color: _amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Reason ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.comment_rounded,
                        color: Colors.grey[500], size: 14),
                    const SizedBox(width: 8),
                    Text('Appeal Reason',
                        style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  appeal.appealReason ?? 'No reason provided.',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Footer: Submitted time + Actions ──
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  color: Colors.grey[600], size: 14),
              const SizedBox(width: 6),
              Text(
                'Submitted: $submittedAt',
                style: GoogleFonts.inter(
                    color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              // Reject button
              OutlinedButton(
                onPressed: () => _handleReject(appeal, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: Text('Reject',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              // Approve button
              ElevatedButton.icon(
                onPressed: () => _handleApprove(appeal, provider),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text('Approve (Allow Retake)',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
      AssessmentSubmission appeal, AdminProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Appeal?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'This will delete the student\'s invalidated submission and allow them to retake the assessment.',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            child: Text('Approve',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.approveAppeal(appeal.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appeal approved. Student can now retake.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(
      AssessmentSubmission appeal, AdminProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Appeal?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'The student\'s score will remain at 0 and they will not be able to retake the assessment.',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.rejectAppeal(appeal.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appeal rejected.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
