import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../models/assessment_model.dart';
import '../services/answer_cache_service.dart';
import 'assessment_result_page.dart';
import 'dart:math';

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

class _TakeAssessmentPageState extends State<TakeAssessmentPage> with WidgetsBindingObserver {
  bool _loading = true;
  bool _submitting = false;
  List<AssessmentQuestion> _questions = [];
  final Map<int, GlobalKey> _questionKeys = {};
  
  // questionId -> studentAnswer
  final Map<String, String> _answers = {};

  // questionId -> per-blank controllers for identification questions
  final Map<String, List<TextEditingController>> _idControllers = {};

  // Session verified (always true now — QR removed)
  bool _sessionVerified = false;

  // Timer
  Timer? _timer;
  int _secondsLeft = 0;

  // Anti-Cheat
  int _leaveCount = 0;
  double _penaltyPoints = 0.0;
  bool _isInvalidated = false;
  bool _isWarningVisible = false;

  // Set A/B Logic
  String? _assignedSet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = widget.assessment.timeLimitSecs;
    
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // Bypass session verification completely
    setState(() => _sessionVerified = true);
    _loadDataAndCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final ctrls in _idControllers.values) {
      for (final c in ctrls) { c.dispose(); }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // paused or hidden triggers when switching tabs on mobile or web
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_sessionVerified && !_submitting && _secondsLeft > 0 && !_isInvalidated && !_isWarningVisible) {
        _leaveCount++;
        if (_leaveCount >= 3) {
          _isInvalidated = true;
          _autoSubmit();
        } else {
          _showAntiCheatWarning();
        }
      }
    }
  }

  void _showAntiCheatWarning() {
    _isWarningVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text('Warning', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.red)),
            ],
          ),
          content: Text(
            'You have left the exam tab. This is warning $_leaveCount of 3.\n\n'
            'If you click Okay, 5 penalty points will be deducted.\n'
            'If you click Exit, your exam will be invalidated immediately.',
            style: GoogleFonts.inter(color: widget.isDark ? Colors.white : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _isWarningVisible = false;
                _isInvalidated = true;
                _autoSubmit();
              },
              child: Text('Exit', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _penaltyPoints += 5.0;
                Navigator.pop(ctx);
                _isWarningVisible = false;
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Okay', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDataAndCache() async {
    final provider = context.read<StudentProvider>();
    final usn = provider.usn;

    try {
      _questions = await provider.loadQuestions(widget.assessment.id!);
      
      // Sort to establish deterministic baseline
      _questions.sort((a, b) => a.questionOrder.compareTo(b.questionOrder));
      
      // Shuffle using the Set's deterministic seed, matching the web projector exactly
      if (widget.assessment.setCount > 1 && _assignedSet != null) {
        final seed = _assignedSet!.codeUnitAt(0);
        _questions.shuffle(Random(seed));
      }

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



  void _updateAnswer(String qId, String answer) {
    setState(() => _answers[qId] = answer);
    final provider = context.read<StudentProvider>();
    AnswerCacheService.saveAnswers(widget.assessment.id!, provider.usn, _answers);
  }

  Future<void> _autoSubmit() async {
    if (_submitting) return;
    _submitAssessment(isAuto: true);
  }

  void _scrollToQuestion(int index) {
    final key = _questionKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _submitAssessment({bool isAuto = false}) async {
    if (!isAuto) {
      final unansweredIndices = <int>[];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final ans = _answers[q.id]?.trim() ?? '';
        // For identification, consider it unanswered only if ALL blanks are empty
        final isUnanswered = q.isIdentification
            ? ans.isEmpty || ans.split('||').every((b) => b.trim().isEmpty)
            : ans.isEmpty;
        if (isUnanswered) {
          unansweredIndices.add(i);
        }
      }

      Color accent = widget.assessment.isExam ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
      if (widget.assessment.themeColor != null) {
        try {
          final hexString = widget.assessment.themeColor!.replaceFirst('#', '');
          accent = Color(int.parse(hexString, radix: 16) + 0xFF000000);
        } catch (_) {}
      }

      int? jumpToQuestionIndex;
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final isDark = widget.isDark;
          final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
          final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
          final subCol = isDark ? Colors.grey[400]! : Colors.grey[600]!;
          final bool hasUnanswered = unansweredIndices.isNotEmpty;

          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (hasUnanswered ? Colors.amber : accent).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasUnanswered ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    color: hasUnanswered ? Colors.amber[600] : accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasUnanswered ? 'Check Your Answers' : 'Confirm Submission',
                    style: GoogleFonts.inter(
                      color: textCol,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kindly check your answers before submitting.',
                      style: GoogleFonts.inter(
                        color: textCol,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (hasUnanswered) ...[
                      Text(
                        'You have ${unansweredIndices.length} blank answer${unansweredIndices.length > 1 ? "s" : ""} on the following question number${unansweredIndices.length > 1 ? "s" : ""}:',
                        style: GoogleFonts.inter(
                          color: subCol,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: unansweredIndices.map((idx) {
                          final num = idx + 1;
                          return Material(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                jumpToQuestionIndex = idx;
                                Navigator.pop(ctx, false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Question #$num',
                                      style: GoogleFonts.inter(
                                        color: isDark ? Colors.amber[300] : Colors.amber[900],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_outward_rounded,
                                      size: 12,
                                      color: isDark ? Colors.amber[300] : Colors.amber[900],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: subCol),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'If you don\'t want to answer these, click "Done" to submit anyway or "Cancel" to return to your assessment.',
                                style: GoogleFonts.inter(
                                  color: subCol,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'All questions have been answered. Would you like to finalize and submit your assessment now?',
                        style: GoogleFonts.inter(
                          color: subCol,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: subCol,
                  side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasUnanswered ? const Color(0xFFF59E0B) : accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) {
        if (jumpToQuestionIndex != null) {
          _scrollToQuestion(jumpToQuestionIndex!);
        }
        return;
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

    if (_isInvalidated) {
      totalScore = 0;
    } else {
      totalScore -= _penaltyPoints;
      if (totalScore < 0) totalScore = 0;
    }


    final setLabel = widget.assessment.setCount > 1 ? _assignedSet : null;

    final submission = AssessmentSubmission(
      assessmentId: widget.assessment.id!,
      studentId: provider.currentStudent!.id!,
      score: totalScore,
      maxScore: _questions.fold(0.0, (sum, q) => sum + q.points),
      setLabel: setLabel,
      submittedAt: DateTime.now(),
      isInvalidated: _isInvalidated,
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
    
    Color accent = widget.assessment.isExam ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
    if (widget.assessment.themeColor != null) {
      try {
        final hexString = widget.assessment.themeColor!.replaceFirst('#', '');
        accent = Color(int.parse(hexString, radix: 16) + 0xFF000000);
      } catch (_) {}
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
            if (widget.assessment.availableUntil != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF60A5FA)),
                      const SizedBox(width: 4),
                      Text(
                        'Period: ${widget.assessment.remainingAvailabilityFormatted}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Done — Submit ${widget.assessment.isExam ? "Exam" : "Quiz"}',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, AssessmentQuestion q, Color surface, Color textCol, Color subCol, Color accent) {
    final key = _questionKeys.putIfAbsent(index, () => GlobalKey());
    final typeLabel = q.isTrueFalse
        ? 'True / False'
        : q.isMultipleChoice
            ? 'Multiple Choice'
            : q.isIdentification
                ? 'Identification'
                : q.isEssay
                    ? 'Essay'
                    : 'Enumeration';
    final ans = _answers[q.id] ?? '';

    return Container(
      key: key,
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
          Text(
            q.questionText,
            style: GoogleFonts.inter(
              color: textCol,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          if (q.isTrueFalse)
            Row(
              children: ['True', 'False'].map((opt) {
                final isSelected = ans.toLowerCase() == opt.toLowerCase();
                final optColor = opt == 'True'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _updateAnswer(q.id!, opt),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: opt == 'True' ? 8 : 0,
                        left: opt == 'False' ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? optColor.withValues(alpha: 0.15)
                            : (widget.isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey[50]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? optColor
                              : (widget.isDark
                                  ? Colors.transparent
                                  : Colors.grey[200]!),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected
                                ? (opt == 'True'
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded)
                                : (opt == 'True'
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined),
                            color: isSelected ? optColor : subCol,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            opt,
                            style: GoogleFonts.inter(
                              color: isSelected ? textCol : subCol,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else if (q.isMultipleChoice)
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
            _buildIdentificationBlanks(q, textCol, subCol, accent)
          else if (q.isEssay)
            TextField(
              onChanged: (v) => _updateAnswer(q.id!, v),
              controller: TextEditingController.fromValue(
                TextEditingValue(text: ans, selection: TextSelection.collapsed(offset: ans.length))
              ),
              maxLines: 6,
              style: GoogleFonts.inter(color: textCol, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your essay answer here...',
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

  /// Builds multiple labeled blank fields for an Identification question.
  /// Each pipe-separated entry in [q.correctAnswer] becomes one blank.
  /// The student must fill every blank; answers are joined with '||' and
  /// stored in [_answers] for grading.
  Widget _buildIdentificationBlanks(
    AssessmentQuestion q,
    Color textCol,
    Color subCol,
    Color accent,
  ) {
    final blanks = q.identificationBlanks;
    final count = blanks.isNotEmpty ? blanks.length : 1;
    final qid = q.id!;

    // Initialise controllers once per question
    if (!_idControllers.containsKey(qid)) {
      final existing = (_answers[qid] ?? '').split('||');
      _idControllers[qid] = List.generate(count, (i) {
        final initial = i < existing.length ? existing[i] : '';
        return TextEditingController(text: initial);
      });
    }

    final controllers = _idControllers[qid]!;
    // Ensure controller count always matches blank count
    while (controllers.length < count) {
      controllers.add(TextEditingController());
    }

    void onBlankChanged() {
      final combined = controllers.map((c) => c.text).join('||');
      _updateAnswer(qid, combined);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (count > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (q.isInterchangeable ? accent : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (q.isInterchangeable ? accent : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    q.isInterchangeable
                        ? Icons.shuffle_rounded
                        : Icons.format_list_numbered_rounded,
                    size: 14,
                    color: q.isInterchangeable ? accent : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    q.isInterchangeable
                        ? 'Interchangeable — blanks can be answered in any order'
                        : 'Strict order — fill in blanks in the correct sequence',
                    style: GoogleFonts.inter(
                      color: q.isInterchangeable ? accent : const Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...List.generate(count, (i) {
          final filled = controllers[i].text.trim().isNotEmpty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: filled
                            ? accent.withValues(alpha: 0.15)
                            : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (filled)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_circle_rounded, size: 11, color: accent),
                            ),
                          Text(
                            'Blank ${i + 1}',
                            style: GoogleFonts.inter(
                              color: filled ? accent : subCol,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: controllers[i],
                  onChanged: (_) {
                    setState(() {});
                    onBlankChanged();
                  },
                  style: GoogleFonts.inter(color: textCol, fontSize: 14),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: q.isInterchangeable
                        ? 'Type an answer for this blank'
                        : 'Type your answer for blank ${i + 1}',
                    hintStyle: GoogleFonts.inter(color: subCol, fontSize: 13),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: filled
                          ? accent.withValues(alpha: 0.4)
                          : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey[200]!),
                      width: filled ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        );
      }),
      ],
    );
  }
}
