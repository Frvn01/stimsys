import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../models/assessment_model.dart';
import '../services/answer_cache_service.dart';
import 'assessment_result_page.dart';

class TakeAssessmentPage extends StatefulWidget {
  final AssessmentConfig assessment;
  final bool isDark;
  final String? prefilledSessionCode;

  const TakeAssessmentPage({
    super.key,
    required this.assessment,
    required this.isDark,
    this.prefilledSessionCode,
  });

  @override
  State<TakeAssessmentPage> createState() => _TakeAssessmentPageState();
}

class _TakeAssessmentPageState extends State<TakeAssessmentPage> {
  bool _loading = true;
  bool _submitting = false;
  List<AssessmentQuestion> _questions = [];
  
  // questionId -> studentAnswer
  final Map<String, String> _answers = {};

  // Exam session validation (if it's an exam)
  bool _sessionVerified = false;
  final _sessionCodeCtrl = TextEditingController();

  // Timer
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.assessment.timeLimitSecs;
    
    if (widget.prefilledSessionCode != null && widget.assessment.sessionCode != null) {
      if (widget.prefilledSessionCode!.toUpperCase() == widget.assessment.sessionCode!.toUpperCase()) {
        _sessionVerified = true;
        _loadDataAndCache();
        return;
      }
    }

    if (widget.assessment.isQuiz) {
      _sessionVerified = true;
      _loadDataAndCache();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDataAndCache() async {
    final provider = context.read<StudentProvider>();
    final usn = provider.usn;

    try {
      _questions = await provider.loadQuestions(widget.assessment.id!);
      _questions.sort((a, b) => a.questionOrder.compareTo(b.questionOrder));

      // Check cache
      final cached = await AnswerCacheService.restoreAnswers(widget.assessment.id!, usn);
      if (cached != null) {
        _answers.addAll(cached);
      }

      // Check timer cache
      final startTime = await AnswerCacheService.getStartTime(widget.assessment.id!, usn);
      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        _secondsLeft = widget.assessment.timeLimitSecs - elapsed;
        if (_secondsLeft < 0) _secondsLeft = 0;
      } else {
        await AnswerCacheService.saveStartTime(widget.assessment.id!, usn, DateTime.now());
      }

      setState(() => _loading = false);
      _startTimer();
    } catch (e) {
      debugPrint('Load questions error: $e');
      setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        _autoSubmit();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _verifySessionCode() {
    if (_sessionCodeCtrl.text.trim().toUpperCase() == widget.assessment.sessionCode?.toUpperCase()) {
      setState(() => _sessionVerified = true);
      _loadDataAndCache();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid session code', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  void _updateAnswer(String qId, String answer) {
    setState(() => _answers[qId] = answer);
    final provider = context.read<StudentProvider>();
    AnswerCacheService.saveAnswers(widget.assessment.id!, provider.usn, _answers);
  }

  Future<void> _autoSubmit() async {
    if (_submitting) return;
    _submitAssessment(isAuto: true);
  }

  Future<void> _submitAssessment({bool isAuto = false}) async {
    if (!isAuto) {
      final unans = _questions.where((q) => !(_answers.containsKey(q.id) && _answers[q.id]!.isNotEmpty)).length;
      if (unans > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Text('Unanswered Questions', style: GoogleFonts.inter(color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700)),
            content: Text('You have $unans unanswered question(s). Are you sure you want to submit?',
                style: GoogleFonts.inter(color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Submit Anyway'),
              ),
            ],
          )
        );
        if (confirm != true) return;
      }
    }

    setState(() => _submitting = true);
    _timer?.cancel();

    final provider = context.read<StudentProvider>();
    
    // Check answers locally
    double totalScore = 0;
    List<AssessmentAnswer> finalAnswers = [];

    for (final q in _questions) {
      final studentAns = _answers[q.id] ?? '';
      final isCorrect = q.checkAnswer(studentAns);
      final pts = q.computePoints(studentAns);
      totalScore += pts;

      finalAnswers.add(AssessmentAnswer(
        submissionId: '',
        questionId: q.id!,
        studentAnswer: studentAns,
        isCorrect: isCorrect,
        pointsEarned: pts,
      ));
    }

    final usn = provider.usn;
    final lastDigit = int.tryParse(usn.characters.last) ?? 0;
    final setLabel = widget.assessment.setCount > 1 ? (lastDigit % 2 != 0 ? 'B' : 'A') : null;

    final submission = AssessmentSubmission(
      assessmentId: widget.assessment.id!,
      studentId: provider.currentStudent!.id!,
      score: totalScore,
      maxScore: _questions.fold(0.0, (sum, q) => sum + q.points),
      setLabel: setLabel,
      submittedAt: DateTime.now(),
    );

    try {
      final saved = await provider.submitAssessment(submission, finalAnswers);
      if (saved != null) {
        await AnswerCacheService.clearAll(widget.assessment.id!, provider.usn);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AssessmentResultPage(
            assessment: widget.assessment,
            submission: saved,
            isDark: widget.isDark,
          )),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);
    final surface = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = widget.isDark ? Colors.white : Colors.black87;
    final subCol = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final accent = widget.assessment.isExam ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);

    if (!_sessionVerified) {
      return _buildSessionVerification(bg, surface, textCol, subCol, accent);
    }

    return WillPopScope(
      onWillPop: () async {
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: surface,
            title: Text('Leave Assessment?', style: GoogleFonts.inter(color: textCol, fontWeight: FontWeight.w700)),
            content: Text('Your progress is saved locally. You can resume as long as the timer hasn\'t expired.',
                style: GoogleFonts.inter(color: subCol)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          )
        );
        return exit == true;
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: textCol),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(widget.assessment.title, style: GoogleFonts.inter(color: textCol, fontSize: 16, fontWeight: FontWeight.w700)),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondsLeft < 60 ? Colors.red.withValues(alpha: 0.1) : accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 14, color: _secondsLeft < 60 ? Colors.red : accent),
                    const SizedBox(width: 4),
                    Text(
                      '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        color: _secondsLeft < 60 ? Colors.red : accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()]
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: accent))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _questions.length,
                      itemBuilder: (_, i) => _buildQuestionCard(i, _questions[i], surface, textCol, subCol, accent),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
                      ]
                    ),
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Submit ${widget.assessment.isExam ? "Exam" : "Quiz"}',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildSessionVerification(Color bg, Color surface, Color textCol, Color subCol, Color accent) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton()),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 48, color: accent),
                const SizedBox(height: 16),
                Text('Exam Session Locked', style: GoogleFonts.inter(color: textCol, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Please ask your instructor for the 4-character session code.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: subCol, fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  controller: _sessionCodeCtrl,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: textCol, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: 'CODE',
                    filled: true,
                    fillColor: widget.isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifySessionCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Start Exam', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, AssessmentQuestion q, Color surface, Color textCol, Color subCol, Color accent) {
    final typeLabel = q.isMultipleChoice ? 'Multiple Choice' : q.isIdentification ? 'Identification' : 'Enumeration';
    final ans = _answers[q.id] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Question ${index + 1}', style: GoogleFonts.inter(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Text(typeLabel, style: GoogleFonts.inter(color: subCol, fontSize: 10, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${q.points} pts', style: GoogleFonts.inter(color: subCol, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),

          if (q.isMultipleChoice)
            ...q.choices!.map((c) {
              final isSelected = ans == c;
              return GestureDetector(
                onTap: () => _updateAnswer(q.id!, c),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withValues(alpha: 0.1) : (widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? accent : (widget.isDark ? Colors.transparent : Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? accent : subCol, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(c, style: GoogleFonts.inter(color: isSelected ? textCol : subCol, fontSize: 14))),
                    ],
                  ),
                ),
              );
            }).toList()
          else if (q.isIdentification)
            TextField(
              onChanged: (v) => _updateAnswer(q.id!, v),
              controller: TextEditingController.fromValue(
                TextEditingValue(text: ans, selection: TextSelection.collapsed(offset: ans.length))
              ),
              style: GoogleFonts.inter(color: textCol, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your answer here',
                hintStyle: GoogleFonts.inter(color: subCol, fontSize: 13),
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            )
          else
            TextField(
              onChanged: (v) => _updateAnswer(q.id!, v),
              controller: TextEditingController.fromValue(
                TextEditingValue(text: ans, selection: TextSelection.collapsed(offset: ans.length))
              ),
              maxLines: 3,
              style: GoogleFonts.inter(color: textCol, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your answers separated by commas\nExample: Red, Blue, Green',
                hintStyle: GoogleFonts.inter(color: subCol, fontSize: 13),
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
        ],
      ),
    );
  }
}
