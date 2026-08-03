import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/student_provider.dart';
import '../../models/assessment_model.dart';

class WebQuestionViewer extends StatefulWidget {
  final AssessmentConfig assessment;
  const WebQuestionViewer({super.key, required this.assessment});

  @override
  State<WebQuestionViewer> createState() => _WebQuestionViewerState();
}

class _WebQuestionViewerState extends State<WebQuestionViewer> {
  List<AssessmentQuestion> _questions = [];
  bool _loading = true;
  Timer? _pollingTimer;
  List<Map<String, dynamic>> _scannedStudents = [];
  String? _selectedSet;

  @override
  void initState() {
    super.initState();
    if (widget.assessment.setCount > 1) {
      _selectedSet = 'A';
    }
    _loadQuestions();
    _startPolling();
  }

  Widget _buildSkeleton() {
    return Container();
  }

  Widget _buildSetTab(String setLabel) {
    final isSelected = _selectedSet == setLabel;
    return GestureDetector(
      onTap: () => setState(() => _selectedSet = setLabel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF2D3B52)),
        ),
        child: Text(
          'Set $setLabel',
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 3 seconds for new submissions
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchScannedStudents();
    });
    _fetchScannedStudents(); // initial fetch
  }

  Future<void> _fetchScannedStudents() async {
    try {
      final res = await Supabase.instance.client
          .from('assessment_submissions')
          .select('id, submitted_at, student:students(first_name, last_name, usn)')
          .eq('assessment_id', widget.assessment.id!);
      
      if (mounted) {
        setState(() {
          _scannedStudents = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Poll error: $e');
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final provider = context.read<StudentProvider>();
      _questions = await provider.loadQuestions(widget.assessment.id!);
      // Sort by order
      _questions.sort((a, b) => a.questionOrder.compareTo(b.questionOrder));
    } catch (e) {
      debugPrint('Error loading questions: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Both sets use ALL questions, but shuffled deterministically
    final displayedQuestions = List<AssessmentQuestion>.from(_questions);
    
    // Sort by original order to ensure a deterministic baseline
    displayedQuestions.sort((a, b) => a.questionOrder.compareTo(b.questionOrder));
    
    if (widget.assessment.setCount > 1 && _selectedSet != null) {
      // Use the character code of the set ('A' = 65, 'B' = 66) as the random seed
      final seed = _selectedSet!.codeUnitAt(0);
      displayedQuestions.shuffle(Random(seed));
    }
    
    // Ensure we don't double-append the set (e.g., QQQQ-B-B)
    final baseCode = widget.assessment.sessionCode ?? "N/A";
    String displayCode = baseCode;
    if (_selectedSet != null && !baseCode.endsWith('-$_selectedSet')) {
      displayCode = '$baseCode-$_selectedSet';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF2D3B52))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.assessment.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${AssessmentConfig.termLabel(widget.assessment.term)} • ${widget.assessment.timeLimitSecs ~/ 60} Minutes',
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          if (widget.assessment.setCount > 1) ...[
                            _buildSetTab('A'),
                            const SizedBox(width: 8),
                            _buildSetTab('B'),
                            const SizedBox(width: 24),
                          ],
                          const Icon(Icons.key_rounded, color: Color(0xFF818CF8), size: 20),
                          const SizedBox(width: 8),
                          Text('Session Code: $displayCode',
                              style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: QR Code
                  Container(
                    width: 350,
                    padding: const EdgeInsets.all(40),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Color(0xFF2D3B52))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Scan to Start', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Open the Stimsys Mobile App to submit your answers.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: QrImageView(
                            data: 'STIMSYS_EXAM|${widget.assessment.id}|${widget.assessment.subjectId}|$displayCode',
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              children: [
                                const Icon(Icons.phone_iphone_rounded, color: Colors.grey, size: 32),
                                const SizedBox(height: 12),
                                Text('The options (A, B, C, D) will appear on your phone.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF2D3B52)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Submitted Students', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${_scannedStudents.length}', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _scannedStudents.isEmpty
                                ? Center(
                                    child: Text('Waiting for submissions...',
                                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic)))
                                : ListView.builder(
                                    itemCount: _scannedStudents.length,
                                    itemBuilder: (ctx, i) {
                                      final st = _scannedStudents[i]['student'];
                                      if (st == null) return const SizedBox.shrink();
                                      final name = '${st['first_name']} ${st['last_name']}';
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(name,
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                  // Right side: Questions
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(40),
                            itemCount: displayedQuestions.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 24),
                            itemBuilder: (context, index) {
                              final q = displayedQuestions[index];
                              return Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF2D3B52)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(8)),
                                          child: Text('Question ${index + 1}',
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                        ),
                                        const Spacer(),
                                        Text('${q.points.toStringAsFixed(1)} Points',
                                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      q.questionText,
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, height: 1.4),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
