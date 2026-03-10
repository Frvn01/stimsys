import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/question_model.dart';

class QuizScreen extends StatefulWidget {
  final Assessment assessment;
  final String studentName;

  const QuizScreen({
    super.key,
    required this.assessment,
    required this.studentName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<int, String> _answers = {};
  final List<TextEditingController> _textControllers = [];
  final List<GlobalKey> _itemKeys = [];
  final ScrollController _scrollController = ScrollController();

  bool _isSubmitted = false;
  AssessmentResult? _result;

  static const int _totalSeconds = 3600;
  int _secondsRemaining = _totalSeconds;
  Timer? _timer;

  final List<String> _quotes = [
    "Every step you take is a step forward.",
    "You are capable of amazing things.",
    "Hard work always pays off.",
    "Keep pushing — you've got this.",
    "Success is built one answer at a time.",
    "Trust your preparation.",
    "Stay focused and give your best.",
  ];

  @override
  void initState() {
    super.initState();
    for (var _ in widget.assessment.questions) {
      _textControllers.add(TextEditingController());
      _itemKeys.add(GlobalKey());
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    for (final c in _textControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Timer ──────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          if (_secondsRemaining == 300) {
            _showTimerSnack('5 minutes remaining', Colors.orange.shade600);
          }
          if (_secondsRemaining == 60) {
            _showTimerSnack('1 minute remaining', Colors.red.shade600);
          }
        } else {
          timer.cancel();
          _submitAssessment();
        }
      });
    });
  }

  void _showTimerSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Color get _timerColor {
    if (_secondsRemaining <= 60) return Colors.red.shade600;
    if (_secondsRemaining <= 300) return Colors.orange.shade600;
    return const Color(0xFF6366F1);
  }

  // ─── State helpers ───────────────────────────────────────────────────────────

  bool _isAnswered(int index) {
    final q = widget.assessment.questions[index];
    if (q.type == QuestionType.multipleChoice) {
      return _answers.containsKey(index);
    }
    return _textControllers[index].text.trim().isNotEmpty;
  }

  int get _answeredCount =>
      List.generate(widget.assessment.questions.length, (i) => i)
          .where(_isAnswered)
          .length;

  void _scrollToItem(int index) {
    final ctx = _itemKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  // ─── Submission ──────────────────────────────────────────────────────────────

  void _submitAssessment() {
    for (int i = 0; i < _textControllers.length; i++) {
      final text = _textControllers[i].text.trim();
      if (text.isNotEmpty) _answers[i] = text;
    }
    setState(() {
      _isSubmitted = true;
      _result = AssessmentResult(
        assessmentId: widget.assessment.id,
        subjectName: widget.assessment.subjectName,
        term: widget.assessment.term,
        type: widget.assessment.type,
        studentName: widget.studentName,
        score: 0,
        totalItems: widget.assessment.questions.length,
        takenAt: DateTime.now(),
      );
    });
  }

  void _showSubmitDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unanswered =
        widget.assessment.questions.length - _answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Assessment?',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question${unanswered > 1 ? 's' : ''}. Once submitted, no changes can be made.'
              : 'All questions answered. Once submitted, no changes can be made.',
          style: TextStyle(
              color:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.6,
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Review',
                style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _timer?.cancel();
              _submitAssessment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    if (_isSubmitted && _result != null) {
      return _buildResultScreen(isDark);
    }

    final questions = widget.assessment.questions;
    final total = questions.length;
    final answered = _answeredCount;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDark),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress bar ──
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? answered / total : 0,
                    minHeight: 3,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$answered of $total answered',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey[500]
                          : Colors.grey[500]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Question number navigator ──
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: total,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final done = _isAnswered(i);
                return GestureDetector(
                  onTap: () => _scrollToItem(i),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? const Color(0xFF6366F1)
                          : Colors.transparent,
                      border: Border.all(
                        color: done
                            ? const Color(0xFF6366F1)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: done
                              ? Colors.white
                              : (isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0)),

          // ── Answer sheet list ──
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding:
                  const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: total,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
              ),
              itemBuilder: (_, index) {
                return KeyedSubtree(
                  key: _itemKeys[index],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    child: _buildAnswerRow(
                        questions[index], index, isDark),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  // ─── App bar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close_rounded,
            color: isDark
                ? Colors.grey[400]
                : Colors.grey[500]),
        onPressed: () => _showExitDialog(isDark),
      ),
      title: Column(
        children: [
          Text(
            widget.assessment.subjectName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF0F172A),
            ),
          ),
          Text(
            '${widget.assessment.term}  ·  ${widget.assessment.type}',
            style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Colors.grey[500]
                    : Colors.grey[500]),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _timerColor.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _secondsRemaining <= 60
                      ? Icons.timer_off_rounded
                      : Icons.timer_outlined,
                  size: 13,
                  color: _timerColor,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _timerColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Answer row ──────────────────────────────────────────────────────────────

  Widget _buildAnswerRow(
      Question question, int index, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Question number
        SizedBox(
          width: 32,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _isAnswered(index)
                  ? const Color(0xFF6366F1)
                  : (isDark
                      ? Colors.grey[500]
                      : Colors.grey[400]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child:
                _buildAnswerInput(question, index, isDark)),
      ],
    );
  }

  // ─── Answer inputs ────────────────────────────────────────────────────────────

  Widget _buildAnswerInput(
      Question question, int index, bool isDark) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        // Only show letter bubbles — actual choices are on the TV
        final count = (question.choices ?? []).length;
        const letters = ['A', 'B', 'C', 'D', 'E'];
        final choices = question.choices ?? [];

        return Wrap(
          spacing: 10,
          children: List.generate(count, (i) {
            final letter =
                i < letters.length ? letters[i] : '${i + 1}';
            final isSelected =
                _answers[index] == choices[i];

            return GestureDetector(
              onTap: () => setState(
                  () => _answers[index] = choices[i]),
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1)),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.grey[400]
                              : Colors.grey[500]),
                    ),
                  ),
                ),
              ),
            );
          }),
        );

      case QuestionType.identification:
        return SizedBox(
          height: 46,
          child: TextField(
            controller: _textControllers[index],
            onChanged: (_) => setState(() {}),
            style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF0F172A)),
            decoration: _inputDecoration(
                'Answer...', isDark),
          ),
        );

      case QuestionType.enumeration:
        return TextField(
          controller: _textControllers[index],
          onChanged: (_) => setState(() {}),
          maxLines: 3,
          style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF0F172A)),
          decoration: _inputDecoration(
              'Separate answers with commas...', isDark),
        );
    }
  }

  InputDecoration _inputDecoration(
      String hint, bool isDark) {
    final borderColor = isDark
        ? const Color(0xFF2D3F55)
        : const Color(0xFFE2E8F0);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 13,
          color:
              isDark ? Colors.grey[600] : Colors.grey[400]),
      filled: true,
      fillColor:
          isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF6366F1), width: 1.5)),
    );
  }

  // ─── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        border: Border(
            top: BorderSide(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _showSubmitDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Submit Assessment',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ─── Result screen ───────────────────────────────────────────────────────────

  Widget _buildResultScreen(bool isDark) {
    final quote = (_quotes..shuffle()).first;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 40, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 20),
              Text(
                'Assessment Submitted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: isDark
                      ? Colors.grey[400]
                      : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 36),
              if (_result != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Show to your teacher',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey[400]
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: QrImageView(
                          data: _result!.qrData,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel:
                              QrErrorCorrectLevel.H,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.studentName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.assessment.subjectName}  ·  ${widget.assessment.term}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[500]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Exit dialog ─────────────────────────────────────────────────────────────

  void _showExitDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Assessment?',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(
          'Your progress will be lost. Are you sure?',
          style: TextStyle(
              color: isDark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              height: 1.5,
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Stay',
                style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Exit',
                style: TextStyle(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}



// This file contains the main quiz-taking interface, including question display, V1 app
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:ui';
// import 'package:qr_flutter/qr_flutter.dart';
// import '../models/question_model.dart';

// class QuizScreen extends StatefulWidget {
//   final Assessment assessment;
//   final String studentName;

//   const QuizScreen({
//     super.key,
//     required this.assessment,
//     required this.studentName,
//   });

//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }

// class _QuizScreenState extends State<QuizScreen>
//     with SingleTickerProviderStateMixin {
//   int _currentQuestionIndex = 0;
//   final Map<int, String> _answers = {};
//   final List<TextEditingController> _textControllers = [];
//   bool _isSubmitted = false;
//   AssessmentResult? _result;
//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;

//   // Timer
//   static const int _totalSeconds = 3600; // 1 hour
//   int _secondsRemaining = _totalSeconds;
//   Timer? _timer;
//   bool _isTimeUp = false;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//     _fadeAnim =
//         CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
//     _animController.forward();

//     for (var _ in widget.assessment.questions) {
//       _textControllers.add(TextEditingController());
//     }

//     _startTimer();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _animController.dispose();
//     for (final c in _textControllers) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   // ─── Timer Methods ────────────────────────────────────────────────────────

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       setState(() {
//         if (_secondsRemaining > 0) {
//           _secondsRemaining--;

//           // Warn at 5 minutes remaining
//           if (_secondsRemaining == 300) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Row(
//                   children: [
//                     Icon(Icons.warning_amber_rounded,
//                         color: Colors.white, size: 18),
//                     SizedBox(width: 8),
//                     Text('5 minutes remaining!'),
//                   ],
//                 ),
//                 backgroundColor: Colors.orange,
//                 duration: const Duration(seconds: 4),
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10)),
//               ),
//             );
//           }

//           // Warn at 1 minute remaining
//           if (_secondsRemaining == 60) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Row(
//                   children: [
//                     Icon(Icons.timer_off_rounded,
//                         color: Colors.white, size: 18),
//                     SizedBox(width: 8),
//                     Text('1 minute remaining! Hurry up!'),
//                   ],
//                 ),
//                 backgroundColor: Colors.red,
//                 duration: const Duration(seconds: 4),
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10)),
//               ),
//             );
//           }
//         } else {
//           // Time is up — auto submit
//           _isTimeUp = true;
//           timer.cancel();
//           _autoSubmitOnTimeUp();
//         }
//       });
//     });
//   }

//   void _autoSubmitOnTimeUp() {
//     // Save any current text input before submitting
//     final q = _currentQuestion;
//     if (q.type == QuestionType.identification ||
//         q.type == QuestionType.enumeration) {
//       final text = _textControllers[_currentQuestionIndex].text.trim();
//       if (text.isNotEmpty) {
//         _answers[_currentQuestionIndex] = text;
//       }
//     }

//     int score = 0;
//     for (int i = 0; i < widget.assessment.questions.length; i++) {
//       final question = widget.assessment.questions[i];
//       final userAnswer = (_answers[i] ?? '').trim().toLowerCase();

//       if (question.type == QuestionType.enumeration) {
//         final correctList =
//             question.enumerationAnswers?.map((e) => e.toLowerCase()).toList() ??
//                 [];
//         final userList = userAnswer
//             .split(RegExp(r'[,\n]'))
//             .map((e) => e.trim())
//             .where((e) => e.isNotEmpty)
//             .toList();
//         int matched = 0;
//         for (final ans in userList) {
//           if (correctList.any((c) => c.contains(ans) || ans.contains(c))) {
//             matched++;
//           }
//         }
//         if (matched >= (correctList.length / 2).ceil()) score++;
//       } else {
//         if (userAnswer == question.correctAnswer.toLowerCase()) score++;
//       }
//     }

//     setState(() {
//       _isSubmitted = true;
//       _result = AssessmentResult(
//         assessmentId: widget.assessment.id,
//         subjectName: widget.assessment.subjectName,
//         term: widget.assessment.term,
//         type: widget.assessment.type,
//         studentName: widget.studentName,
//         score: score,
//         totalItems: widget.assessment.questions.length,
//         takenAt: DateTime.now(),
//       );
//     });
//   }

//   String _formatTime(int seconds) {
//     final h = (seconds ~/ 3600).toString().padLeft(2, '0');
//     final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
//     final s = (seconds % 60).toString().padLeft(2, '0');
//     return '$h:$m:$s';
//   }

//   Color _timerColor() {
//     if (_secondsRemaining <= 60) return Colors.red;
//     if (_secondsRemaining <= 300) return Colors.orange;
//     return const Color(0xFF6366F1);
//   }

//   // ─── Question Helpers ─────────────────────────────────────────────────────

//   Question get _currentQuestion =>
//       widget.assessment.questions[_currentQuestionIndex];

//   bool get _isLastQuestion =>
//       _currentQuestionIndex == widget.assessment.questions.length - 1;

//   void _nextQuestion() {
//     _saveTextAnswer();
//     if (_answers[_currentQuestionIndex] == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Please answer the question before proceeding.'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         ),
//       );
//       return;
//     }
//     setState(() {
//       _currentQuestionIndex++;
//     });
//     _animController.forward(from: 0);
//   }

//   void _previousQuestion() {
//     _saveTextAnswer();
//     setState(() {
//       _currentQuestionIndex--;
//     });
//     _animController.forward(from: 0);
//   }

//   void _saveTextAnswer() {
//     final q = _currentQuestion;
//     if (q.type == QuestionType.identification ||
//         q.type == QuestionType.enumeration) {
//       final text = _textControllers[_currentQuestionIndex].text.trim();
//       if (text.isNotEmpty) {
//         _answers[_currentQuestionIndex] = text;
//       }
//     }
//   }

//   void _submitQuiz() {
//     _saveTextAnswer();

//     // Check all questions are answered
//     for (int i = 0; i < widget.assessment.questions.length; i++) {
//       if (_answers[i] == null || _answers[i]!.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content:
//                 Text('Question ${i + 1} is not answered. Please review.'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10)),
//           ),
//         );
//         setState(() => _currentQuestionIndex = i);
//         return;
//       }
//     }

//     // Stop timer on manual submit
//     _timer?.cancel();

//     int score = 0;
//     for (int i = 0; i < widget.assessment.questions.length; i++) {
//       final q = widget.assessment.questions[i];
//       final userAnswer = (_answers[i] ?? '').trim().toLowerCase();

//       if (q.type == QuestionType.enumeration) {
//         final correctList =
//             q.enumerationAnswers?.map((e) => e.toLowerCase()).toList() ?? [];
//         final userList = userAnswer
//             .split(RegExp(r'[,\n]'))
//             .map((e) => e.trim())
//             .where((e) => e.isNotEmpty)
//             .toList();

//         int matched = 0;
//         for (final ans in userList) {
//           if (correctList.any((c) => c.contains(ans) || ans.contains(c))) {
//             matched++;
//           }
//         }
//         if (matched >= (correctList.length / 2).ceil()) score++;
//       } else {
//         if (userAnswer == q.correctAnswer.toLowerCase()) score++;
//       }
//     }

//     setState(() {
//       _isSubmitted = true;
//       _result = AssessmentResult(
//         assessmentId: widget.assessment.id,
//         subjectName: widget.assessment.subjectName,
//         term: widget.assessment.term,
//         type: widget.assessment.type,
//         studentName: widget.studentName,
//         score: score,
//         totalItems: widget.assessment.questions.length,
//         takenAt: DateTime.now(),
//       );
//     });
//   }

//   // ─── Build ────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (_isSubmitted && _result != null) {
//       return _buildResultScreen(isDark);
//     }

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               '${widget.assessment.term} ${widget.assessment.type}',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//             ),
//             Text(
//               widget.assessment.subjectName,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isDark ? Colors.grey[400] : Colors.grey[600],
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.close_rounded),
//           onPressed: () => _showExitDialog(isDark),
//         ),
//         actions: [
//           // ── Timer Chip ──────────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 500),
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: _timerColor().withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: _timerColor().withOpacity(0.4),
//                   width: 1.5,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     _secondsRemaining <= 60
//                         ? Icons.timer_off_rounded
//                         : Icons.timer_rounded,
//                     size: 15,
//                     color: _timerColor(),
//                   ),
//                   const SizedBox(width: 5),
//                   Text(
//                     _formatTime(_secondsRemaining),
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w700,
//                       color: _timerColor(),
//                       fontFeatures: const [FontFeature.tabularFigures()],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // ── Progress Bar ──────────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Question ${_currentQuestionIndex + 1} of ${widget.assessment.questions.length}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: isDark ? Colors.grey[400] : Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Text(
//                       _getQuestionTypeLabel(_currentQuestion.type),
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: _getTypeColor(_currentQuestion.type),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: LinearProgressIndicator(
//                     value: (_currentQuestionIndex + 1) /
//                         widget.assessment.questions.length,
//                     backgroundColor:
//                         isDark ? Colors.grey[800] : Colors.grey[200],
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                         _getTypeColor(_currentQuestion.type)),
//                     minHeight: 6,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // ── Question Content ──────────────────────────────────────────────
//           Expanded(
//             child: FadeTransition(
//               opacity: _fadeAnim,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Question type badge
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: _getTypeColor(_currentQuestion.type)
//                             .withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: _getTypeColor(_currentQuestion.type)
//                               .withOpacity(0.3),
//                         ),
//                       ),
//                       child: Text(
//                         _getQuestionTypeLabel(_currentQuestion.type),
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: _getTypeColor(_currentQuestion.type),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Question text
//                     Text(
//                       _currentQuestion.text,
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                         height: 1.5,
//                         color: isDark ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 28),

//                     // Answer area
//                     _buildAnswerArea(isDark),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // ── Navigation Bar ────────────────────────────────────────────────
//           _buildNavigationBar(isDark),
//         ],
//       ),
//     );
//   }

//   // ─── Answer Widgets ───────────────────────────────────────────────────────

//   Widget _buildAnswerArea(bool isDark) {
//     switch (_currentQuestion.type) {
//       case QuestionType.multipleChoice:
//         return _buildMultipleChoice(isDark);
//       case QuestionType.identification:
//         return _buildIdentification(isDark);
//       case QuestionType.enumeration:
//         return _buildEnumeration(isDark);
//     }
//   }

//   Widget _buildMultipleChoice(bool isDark) {
//     final choices = _currentQuestion.choices ?? [];
//     return Column(
//       children: choices.asMap().entries.map((entry) {
//         final index = entry.key;
//         final choice = entry.value;
//         final labels = ['A', 'B', 'C', 'D'];
//         final isSelected = _answers[_currentQuestionIndex] == choice;

//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _answers[_currentQuestionIndex] = choice;
//             });
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 12),
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? const Color(0xFF6366F1).withOpacity(0.15)
//                   : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isSelected
//                     ? const Color(0xFF6366F1)
//                     : (isDark
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.grey.shade200),
//                 width: isSelected ? 2 : 1,
//               ),
//               boxShadow: isSelected
//                   ? [
//                       BoxShadow(
//                         color: const Color(0xFF6366F1).withOpacity(0.2),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       )
//                     ]
//                   : [],
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? const Color(0xFF6366F1)
//                         : (isDark
//                             ? Colors.white.withOpacity(0.1)
//                             : Colors.grey.shade100),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       labels[index],
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: isSelected
//                             ? Colors.white
//                             : (isDark ? Colors.grey[300] : Colors.grey[600]),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Text(
//                     choice,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight:
//                           isSelected ? FontWeight.w600 : FontWeight.w400,
//                       color: isSelected
//                           ? const Color(0xFF6366F1)
//                           : (isDark ? Colors.grey[200] : Colors.black87),
//                     ),
//                   ),
//                 ),
//                 if (isSelected)
//                   const Icon(Icons.check_circle_rounded,
//                       color: Color(0xFF6366F1), size: 20),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildIdentification(bool isDark) {
//     if (_textControllers[_currentQuestionIndex].text.isEmpty &&
//         _answers[_currentQuestionIndex] != null) {
//       _textControllers[_currentQuestionIndex].text =
//           _answers[_currentQuestionIndex]!;
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Type your answer below:',
//           style: TextStyle(
//             fontSize: 13,
//             color: isDark ? Colors.grey[400] : Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextField(
//           controller: _textControllers[_currentQuestionIndex],
//           onChanged: (val) {
//             _answers[_currentQuestionIndex] = val.trim();
//           },
//           style: TextStyle(
//             fontSize: 14,
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//           decoration: InputDecoration(
//             hintText: 'Enter your answer here...',
//             hintStyle: TextStyle(
//               color: isDark ? Colors.grey[600] : Colors.grey[400],
//             ),
//             filled: true,
//             fillColor:
//                 isDark ? Colors.white.withOpacity(0.05) : Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide:
//                   const BorderSide(color: Color(0xFF6366F1), width: 1.5),
//             ),
//             contentPadding: const EdgeInsets.all(16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEnumeration(bool isDark) {
//     if (_textControllers[_currentQuestionIndex].text.isEmpty &&
//         _answers[_currentQuestionIndex] != null) {
//       _textControllers[_currentQuestionIndex].text =
//           _answers[_currentQuestionIndex]!;
//     }

//     final count = _currentQuestion.enumerationAnswers?.length ?? 3;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.amber.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.amber.withOpacity(0.3)),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.info_outline, color: Colors.amber, size: 16),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'List $count items. Separate with commas (e.g., Item1, Item2, Item3)',
//                   style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.amber,
//                       fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 14),
//         Text(
//           'Type your answers below:',
//           style: TextStyle(
//             fontSize: 13,
//             color: isDark ? Colors.grey[400] : Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextField(
//           controller: _textControllers[_currentQuestionIndex],
//           onChanged: (val) {
//             _answers[_currentQuestionIndex] = val.trim();
//           },
//           maxLines: 4,
//           style: TextStyle(
//             fontSize: 14,
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//           decoration: InputDecoration(
//             hintText: 'e.g., Answer1, Answer2, Answer3',
//             hintStyle: TextStyle(
//               color: isDark ? Colors.grey[600] : Colors.grey[400],
//             ),
//             filled: true,
//             fillColor:
//                 isDark ? Colors.white.withOpacity(0.05) : Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide:
//                   const BorderSide(color: Color(0xFF6366F1), width: 1.5),
//             ),
//             contentPadding: const EdgeInsets.all(16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNavigationBar(bool isDark) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1E293B) : Colors.white,
//         border: Border(
//           top: BorderSide(
//             color: isDark
//                 ? Colors.white.withOpacity(0.1)
//                 : Colors.grey.shade100,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           if (_currentQuestionIndex > 0)
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: _previousQuestion,
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   side: BorderSide(
//                     color: isDark
//                         ? Colors.white.withOpacity(0.2)
//                         : Colors.grey.shade300,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text('Previous'),
//               ),
//             ),
//           if (_currentQuestionIndex > 0) const SizedBox(width: 12),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton(
//               onPressed: _isLastQuestion ? _submitQuiz : _nextQuestion,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _isLastQuestion
//                     ? Colors.green.shade500
//                     : const Color(0xFF6366F1),
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text(
//                 _isLastQuestion ? 'Submit' : 'Next',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Result Screen ────────────────────────────────────────────────────────

//   Widget _buildResultScreen(bool isDark) {
//     final result = _result!;
//     final isPassed = result.score >= (result.totalItems * 0.6).ceil();

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),

//               // ── Result Icon ───────────────────────────────────────────────
//               // Container(
//               //   padding: const EdgeInsets.all(24),
//               //   decoration: BoxDecoration(
//               //     color:
//               //         (isPassed ? Colors.green : Colors.red).withOpacity(0.1),
//               //     shape: BoxShape.circle,
//               //   ),
//               //   child: Icon(
//               //     isPassed
//               //         ? Icons.emoji_events_rounded
//               //         : Icons.sentiment_dissatisfied_rounded,
//               //     size: 60,
//               //     color: isPassed ? Colors.green : Colors.red,
//               //   ),
//               // ),
//               // const SizedBox(height: 20),

//               // ── Time's Up Badge (shown only on auto-submit) ───────────────
//               if (_isTimeUp)
//                 Container(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border:
//                         Border.all(color: Colors.red.withOpacity(0.3)),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.timer_off_rounded,
//                           color: Colors.red, size: 16),
//                       SizedBox(width: 6),
//                       Text(
//                         "Time's Up — Auto Submitted",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.red,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Text(
//               //   isPassed ? 'Great Job!' : 'Keep Trying!',
//               //   style: const TextStyle(
//               //     fontSize: 26,
//               //     fontWeight: FontWeight.w800,
//               //     letterSpacing: -0.5,
//               //   ),
//               // ),
//               // const SizedBox(height: 8),
//               // Text(
//               //   '${result.term} ${result.type} — ${result.subjectName}',
//               //   style: TextStyle(
//               //     fontSize: 13,
//               //     color: isDark ? Colors.grey[400] : Colors.grey[600],
//               //   ),
//               //   textAlign: TextAlign.center,
//               // ),
//               // const SizedBox(height: 28),

//               // ── Score Card ────────────────────────────────────────────────
//               // Container(
//               //   padding: const EdgeInsets.all(24),
//               //   decoration: BoxDecoration(
//               //     color: isDark
//               //         ? Colors.white.withOpacity(0.05)
//               //         : Colors.white,
//               //     borderRadius: BorderRadius.circular(16),
//               //     border: Border.all(
//               //       color: isDark
//               //           ? Colors.white.withOpacity(0.1)
//               //           : Colors.grey.shade200,
//               //     ),
//               //   ),
//               //   child: Column(
//               //     children: [
//               //       Text(
//               //         '${result.score}/${result.totalItems}',
//               //         style: TextStyle(
//               //           fontSize: 52,
//               //           fontWeight: FontWeight.w900,
//               //           color: isPassed ? Colors.green : Colors.red,
//               //           letterSpacing: -1,
//               //         ),
//               //       ),
//               //       Text(
//               //         result.percentage,
//               //         style: TextStyle(
//               //           fontSize: 18,
//               //           fontWeight: FontWeight.w600,
//               //           color:
//               //               isDark ? Colors.grey[300] : Colors.grey[700],
//               //         ),
//               //       ),
//               //       const SizedBox(height: 16),
//               //       ClipRRect(
//               //         borderRadius: BorderRadius.circular(8),
//               //         child: LinearProgressIndicator(
//               //           value: result.score / result.totalItems,
//               //           backgroundColor:
//               //               isDark ? Colors.grey[800] : Colors.grey[200],
//               //           valueColor: AlwaysStoppedAnimation<Color>(
//               //               isPassed ? Colors.green : Colors.red),
//               //           minHeight: 10,
//               //         ),
//               //       ),
//               //       const SizedBox(height: 16),
//               //       // Time used info
//               //       Row(
//               //         mainAxisAlignment: MainAxisAlignment.center,
//               //         children: [
//               //           Icon(Icons.access_time_rounded,
//               //               size: 14,
//               //               color: isDark
//               //                   ? Colors.grey[500]
//               //                   : Colors.grey[600]),
//               //           const SizedBox(width: 6),
//               //           Text(
//               //             'Time used: ${_formatTime(_totalSeconds - _secondsRemaining)}',
//               //             style: TextStyle(
//               //               fontSize: 12,
//               //               color: isDark
//               //                   ? Colors.grey[500]
//               //                   : Colors.grey[600],
//               //               fontWeight: FontWeight.w500,
//               //             ),
//               //           ),
//               //         ],
//               //       ),
//               //     ],
//               //   ),
//               // ),
//               // const SizedBox(height: 24),

//               // ── QR Code Section ───────────────────────────────────────────
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: isDark
//                       ? Colors.white.withOpacity(0.05)
//                       : Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: isDark
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.grey.shade200,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Assessment Result QR Code',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color:
//                             isDark ? Colors.grey[300] : Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Present this to your instructor',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color:
//                             isDark ? Colors.grey[500] : Colors.grey[500],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: QrImageView(
//                         data: result.qrData,
//                         version: QrVersions.auto,
//                         size: 200,
//                         backgroundColor: Colors.white,
//                         errorCorrectionLevel: QrErrorCorrectLevel.H,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildResultInfoRow(
//                         'Assessment', '${result.term} ${result.type}', isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow('Subject', result.subjectName, isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow('Student', result.studentName, isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow(
//                         'Score',
//                         '${result.score}/${result.totalItems} (${result.percentage})',
//                         isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow(
//                         'Date',
//                         '${result.takenAt.month}/${result.takenAt.day}/${result.takenAt.year}',
//                         isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow(
//                         'Time Used',
//                         _formatTime(_totalSeconds - _secondsRemaining),
//                         isDark),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // ── Back Button ───────────────────────────────────────────────
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF6366F1),
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Back to Assessments',
//                     style: TextStyle(
//                         fontSize: 14, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResultInfoRow(String label, String value, bool isDark) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: isDark ? Colors.grey[500] : Colors.grey[600],
//           ),
//         ),
//         Flexible(
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: isDark ? Colors.grey[200] : Colors.grey[800],
//             ),
//             textAlign: TextAlign.end,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   // ─── Dialogs ──────────────────────────────────────────────────────────────

//   void _showExitDialog(bool isDark) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Exit Assessment?',
//             style: TextStyle(fontWeight: FontWeight.w700)),
//         content: const Text(
//             'Your progress will be lost. Are you sure you want to exit?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('Stay'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _timer?.cancel();
//               Navigator.of(ctx).pop();
//               Navigator.of(context).pop();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//             ),
//             child: const Text('Exit'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Helpers ──────────────────────────────────────────────────────────────

//   String _getQuestionTypeLabel(QuestionType type) {
//     switch (type) {
//       case QuestionType.multipleChoice:
//         return 'Multiple Choice';
//       case QuestionType.identification:
//         return 'Identification';
//       case QuestionType.enumeration:
//         return 'Enumeration';
//     }
//   }

//   Color _getTypeColor(QuestionType type) {
//     switch (type) {
//       case QuestionType.multipleChoice:
//         return const Color(0xFF6366F1);
//       case QuestionType.identification:
//         return const Color(0xFF10B981);
//       case QuestionType.enumeration:
//         return const Color(0xFFF59E0B);
//     }
//   }
// }










//Old

// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'package:qr_flutter/qr_flutter.dart';
// import '../models/question_model.dart';

// class QuizScreen extends StatefulWidget {
//   final Assessment assessment;
//   final String studentName;

//   const QuizScreen({
//     super.key,
//     required this.assessment,
//     required this.studentName,
//   });

//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }

// class _QuizScreenState extends State<QuizScreen>
//     with SingleTickerProviderStateMixin {
//   int _currentQuestionIndex = 0;
//   final Map<int, String> _answers = {};
//   final List<TextEditingController> _textControllers = [];
//   bool _isSubmitted = false;
//   AssessmentResult? _result;
//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//     _fadeAnim =
//         CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
//     _animController.forward();

//     for (var _ in widget.assessment.questions) {
//       _textControllers.add(TextEditingController());
//     }
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     for (final c in _textControllers) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   Question get _currentQuestion =>
//       widget.assessment.questions[_currentQuestionIndex];

//   bool get _isLastQuestion =>
//       _currentQuestionIndex == widget.assessment.questions.length - 1;

//   void _nextQuestion() {
//     _saveTextAnswer();
//     if (_answers[_currentQuestionIndex] == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Please answer the question before proceeding.'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         ),
//       );
//       return;
//     }
//     setState(() {
//       _currentQuestionIndex++;
//     });
//     _animController.forward(from: 0);
//   }

//   void _previousQuestion() {
//     _saveTextAnswer();
//     setState(() {
//       _currentQuestionIndex--;
//     });
//     _animController.forward(from: 0);
//   }

//   void _saveTextAnswer() {
//     final q = _currentQuestion;
//     if (q.type == QuestionType.identification ||
//         q.type == QuestionType.enumeration) {
//       final text = _textControllers[_currentQuestionIndex].text.trim();
//       if (text.isNotEmpty) {
//         _answers[_currentQuestionIndex] = text;
//       }
//     }
//   }

//   void _submitQuiz() {
//     _saveTextAnswer();

//     // Check all questions answered
//     for (int i = 0; i < widget.assessment.questions.length; i++) {
//       if (_answers[i] == null || _answers[i]!.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content:
//                 Text('Question ${i + 1} is not answered. Please review.'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10)),
//           ),
//         );
//         setState(() => _currentQuestionIndex = i);
//         return;
//       }
//     }

//     int score = 0;
//     for (int i = 0; i < widget.assessment.questions.length; i++) {
//       final q = widget.assessment.questions[i];
//       final userAnswer = (_answers[i] ?? '').trim().toLowerCase();

//       if (q.type == QuestionType.enumeration) {
//         final correctList =
//             q.enumerationAnswers?.map((e) => e.toLowerCase()).toList() ?? [];
//         // Split user answer by comma or newline
//         final userList = userAnswer
//             .split(RegExp(r'[,\n]'))
//             .map((e) => e.trim())
//             .where((e) => e.isNotEmpty)
//             .toList();

//         int matched = 0;
//         for (final ans in userList) {
//           if (correctList.any((c) => c.contains(ans) || ans.contains(c))) {
//             matched++;
//           }
//         }
//         if (matched >= (correctList.length / 2).ceil()) score++;
//       } else {
//         if (userAnswer == q.correctAnswer.toLowerCase()) score++;
//       }
//     }

//     setState(() {
//       _isSubmitted = true;
//       _result = AssessmentResult(
//         assessmentId: widget.assessment.id,
//         subjectName: widget.assessment.subjectName,
//         term: widget.assessment.term,
//         type: widget.assessment.type,
//         studentName: widget.studentName,
//         score: score,
//         totalItems: widget.assessment.questions.length,
//         takenAt: DateTime.now(),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (_isSubmitted && _result != null) {
//       return _buildResultScreen(isDark);
//     }

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               '${widget.assessment.term} ${widget.assessment.type}',
//               style: const TextStyle(
//                   fontSize: 16, fontWeight: FontWeight.w700),
//             ),
//             Text(
//               widget.assessment.subjectName,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isDark ? Colors.grey[400] : Colors.grey[600],
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.close_rounded),
//           onPressed: () => _showExitDialog(isDark),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Progress bar
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Question ${_currentQuestionIndex + 1} of ${widget.assessment.questions.length}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: isDark ? Colors.grey[400] : Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Text(
//                       _getQuestionTypeLabel(_currentQuestion.type),
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: _getTypeColor(_currentQuestion.type),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: LinearProgressIndicator(
//                     value: (_currentQuestionIndex + 1) /
//                         widget.assessment.questions.length,
//                     backgroundColor:
//                         isDark ? Colors.grey[800] : Colors.grey[200],
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                         _getTypeColor(_currentQuestion.type)),
//                     minHeight: 6,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Question content
//           Expanded(
//             child: FadeTransition(
//               opacity: _fadeAnim,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Question number badge
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: _getTypeColor(_currentQuestion.type)
//                             .withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: _getTypeColor(_currentQuestion.type)
//                               .withOpacity(0.3),
//                         ),
//                       ),
//                       child: Text(
//                         _getQuestionTypeLabel(_currentQuestion.type),
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: _getTypeColor(_currentQuestion.type),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Question text
//                     Text(
//                       _currentQuestion.text,
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                         height: 1.5,
//                         color: isDark ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 28),

//                     // Answer area
//                     _buildAnswerArea(isDark),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Navigation buttons
//           _buildNavigationBar(isDark),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnswerArea(bool isDark) {
//     switch (_currentQuestion.type) {
//       case QuestionType.multipleChoice:
//         return _buildMultipleChoice(isDark);
//       case QuestionType.identification:
//         return _buildIdentification(isDark);
//       case QuestionType.enumeration:
//         return _buildEnumeration(isDark);
//     }
//   }

//   Widget _buildMultipleChoice(bool isDark) {
//     final choices = _currentQuestion.choices ?? [];
//     return Column(
//       children: choices.asMap().entries.map((entry) {
//         final index = entry.key;
//         final choice = entry.value;
//         final labels = ['A', 'B', 'C', 'D'];
//         final isSelected = _answers[_currentQuestionIndex] == choice;

//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _answers[_currentQuestionIndex] = choice;
//             });
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             margin: const EdgeInsets.only(bottom: 12),
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? const Color(0xFF6366F1).withOpacity(0.15)
//                   : (isDark
//                       ? Colors.white.withOpacity(0.05)
//                       : Colors.white),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isSelected
//                     ? const Color(0xFF6366F1)
//                     : (isDark
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.grey.shade200),
//                 width: isSelected ? 2 : 1,
//               ),
//               boxShadow: isSelected
//                   ? [
//                       BoxShadow(
//                         color:
//                             const Color(0xFF6366F1).withOpacity(0.2),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       )
//                     ]
//                   : [],
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? const Color(0xFF6366F1)
//                         : (isDark
//                             ? Colors.white.withOpacity(0.1)
//                             : Colors.grey.shade100),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       labels[index],
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: isSelected
//                             ? Colors.white
//                             : (isDark
//                                 ? Colors.grey[300]
//                                 : Colors.grey[600]),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Text(
//                     choice,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: isSelected
//                           ? FontWeight.w600
//                           : FontWeight.w400,
//                       color: isSelected
//                           ? const Color(0xFF6366F1)
//                           : (isDark ? Colors.grey[200] : Colors.black87),
//                     ),
//                   ),
//                 ),
//                 if (isSelected)
//                   const Icon(Icons.check_circle_rounded,
//                       color: Color(0xFF6366F1), size: 20),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildIdentification(bool isDark) {
//     // Restore saved answer to controller
//     if (_textControllers[_currentQuestionIndex].text.isEmpty &&
//         _answers[_currentQuestionIndex] != null) {
//       _textControllers[_currentQuestionIndex].text =
//           _answers[_currentQuestionIndex]!;
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Type your answer below:',
//           style: TextStyle(
//             fontSize: 13,
//             color: isDark ? Colors.grey[400] : Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextField(
//           controller: _textControllers[_currentQuestionIndex],
//           onChanged: (val) {
//             _answers[_currentQuestionIndex] = val.trim();
//           },
//           style: TextStyle(
//             fontSize: 14,
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//           decoration: InputDecoration(
//             hintText: 'Enter your answer here...',
//             hintStyle: TextStyle(
//               color: isDark ? Colors.grey[600] : Colors.grey[400],
//             ),
//             filled: true,
//             fillColor: isDark
//                 ? Colors.white.withOpacity(0.05)
//                 : Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                   color: Color(0xFF6366F1), width: 1.5),
//             ),
//             contentPadding: const EdgeInsets.all(16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEnumeration(bool isDark) {
//     if (_textControllers[_currentQuestionIndex].text.isEmpty &&
//         _answers[_currentQuestionIndex] != null) {
//       _textControllers[_currentQuestionIndex].text =
//           _answers[_currentQuestionIndex]!;
//     }

//     final count =
//         _currentQuestion.enumerationAnswers?.length ?? 3;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.amber.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.amber.withOpacity(0.3)),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.info_outline, color: Colors.amber, size: 16),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'List $count items. Separate with commas (e.g., Item1, Item2, Item3)',
//                   style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.amber,
//                       fontWeight: FontWeight.w500),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 14),
//         Text(
//           'Type your answers below:',
//           style: TextStyle(
//             fontSize: 13,
//             color: isDark ? Colors.grey[400] : Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextField(
//           controller: _textControllers[_currentQuestionIndex],
//           onChanged: (val) {
//             _answers[_currentQuestionIndex] = val.trim();
//           },
//           maxLines: 4,
//           style: TextStyle(
//             fontSize: 14,
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//           decoration: InputDecoration(
//             hintText: 'e.g., Answer1, Answer2, Answer3',
//             hintStyle: TextStyle(
//               color: isDark ? Colors.grey[600] : Colors.grey[400],
//             ),
//             filled: true,
//             fillColor: isDark
//                 ? Colors.white.withOpacity(0.05)
//                 : Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(
//                 color: isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.shade200,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                   color: Color(0xFF6366F1), width: 1.5),
//             ),
//             contentPadding: const EdgeInsets.all(16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNavigationBar(bool isDark) {
//     return Container(
//       padding:
//           const EdgeInsets.fromLTRB(20, 12, 20, 24),
//       decoration: BoxDecoration(
//         color: isDark
//             ? const Color(0xFF1E293B)
//             : Colors.white,
//         border: Border(
//           top: BorderSide(
//             color: isDark
//                 ? Colors.white.withOpacity(0.1)
//                 : Colors.grey.shade100,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           if (_currentQuestionIndex > 0)
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: _previousQuestion,
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   side: BorderSide(
//                     color: isDark
//                         ? Colors.white.withOpacity(0.2)
//                         : Colors.grey.shade300,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text('Previous'),
//               ),
//             ),
//           if (_currentQuestionIndex > 0) const SizedBox(width: 12),
//           Expanded(
//             flex: 2,
//             child: ElevatedButton(
//               onPressed: _isLastQuestion ? _submitQuiz : _nextQuestion,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _isLastQuestion
//                     ? Colors.green.shade500
//                     : const Color(0xFF6366F1),
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text(
//                 _isLastQuestion ? 'Submit' : 'Next',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultScreen(bool isDark) {
//     final result = _result!;
//     final isPassed = result.score >= (result.totalItems * 0.6).ceil();

//     return Scaffold(
//       backgroundColor:
//           isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               // Result icon
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: (isPassed ? Colors.green : Colors.red)
//                       .withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   isPassed
//                       ? Icons.emoji_events_rounded
//                       : Icons.sentiment_dissatisfied_rounded,
//                   size: 60,
//                   color:
//                       isPassed ? Colors.green : Colors.red,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 isPassed ? 'Great Job!' : 'Keep Trying!',
//                 style: const TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.w800,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 '${result.term} ${result.type} — ${result.subjectName}',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: isDark ? Colors.grey[400] : Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 28),

//               // Score card
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: isDark
//                       ? Colors.white.withOpacity(0.05)
//                       : Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: isDark
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.grey.shade200,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '${result.score}/${result.totalItems}',
//                       style: TextStyle(
//                         fontSize: 52,
//                         fontWeight: FontWeight.w900,
//                         color: isPassed
//                             ? Colors.green
//                             : Colors.red,
//                         letterSpacing: -1,
//                       ),
//                     ),
//                     Text(
//                       result.percentage,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: isDark ? Colors.grey[300] : Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: LinearProgressIndicator(
//                         value: result.score / result.totalItems,
//                         backgroundColor: isDark
//                             ? Colors.grey[800]
//                             : Colors.grey[200],
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                             isPassed ? Colors.green : Colors.red),
//                         minHeight: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // QR Code section
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: isDark
//                       ? Colors.white.withOpacity(0.05)
//                       : Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: isDark
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.grey.shade200,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Assessment Result QR Code',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: isDark ? Colors.grey[300] : Colors.grey[700],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Present this to your instructor',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: isDark ? Colors.grey[500] : Colors.grey[500],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: QrImageView(
//                         data: result.qrData,
//                         version: QrVersions.auto,
//                         size: 200,
//                         backgroundColor: Colors.white,
//                         errorCorrectionLevel: QrErrorCorrectLevel.H,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     // QR info rows
//                     _buildResultInfoRow(
//                         'Assessment', '${result.term} ${result.type}', isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow('Subject',
//                         result.subjectName, isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow('Student', result.studentName, isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow(
//                         'Score', '${result.score}/${result.totalItems}', isDark),
//                     const SizedBox(height: 6),
//                     _buildResultInfoRow(
//                         'Date',
//                         '${result.takenAt.month}/${result.takenAt.day}/${result.takenAt.year}',
//                         isDark),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF6366F1),
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Back to Assessments',
//                     style: TextStyle(
//                         fontSize: 14, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResultInfoRow(String label, String value, bool isDark) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: isDark ? Colors.grey[500] : Colors.grey[600],
//           ),
//         ),
//         Flexible(
//           child: Text(
//             value,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: isDark ? Colors.grey[200] : Colors.grey[800],
//             ),
//             textAlign: TextAlign.end,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   void _showExitDialog(bool isDark) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Exit Assessment?',
//             style: TextStyle(fontWeight: FontWeight.w700)),
//         content: const Text(
//             'Your progress will be lost. Are you sure you want to exit?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('Stay'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(ctx).pop();
//               Navigator.of(context).pop();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//             ),
//             child: const Text('Exit'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getQuestionTypeLabel(QuestionType type) {
//     switch (type) {
//       case QuestionType.multipleChoice:
//         return 'Multiple Choice';
//       case QuestionType.identification:
//         return 'Identification';
//       case QuestionType.enumeration:
//         return 'Enumeration';
//     }
//   }

//   Color _getTypeColor(QuestionType type) {
//     switch (type) {
//       case QuestionType.multipleChoice:
//         return const Color(0xFF6366F1);
//       case QuestionType.identification:
//         return const Color(0xFF10B981);
//       case QuestionType.enumeration:
//         return const Color(0xFFF59E0B);
//     }
//   }
// }