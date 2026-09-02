import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/admin_provider.dart';
import '../../models/assessment_model.dart';
import '../../models/subject_model.dart';
import '../../models/exam_request_model.dart';
import '../../core/supabase_config.dart';

class DesktopAssessmentScreen extends StatefulWidget {
  const DesktopAssessmentScreen({super.key});

  @override
  State<DesktopAssessmentScreen> createState() =>
      _DesktopAssessmentScreenState();
}

class _DesktopAssessmentScreenState extends State<DesktopAssessmentScreen> {
  String? _selectedSubjectId;
  String _selectedTerm = 'prelim';
  String? _selectedAssessmentId;
  bool _showQuestions = false;

  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A2235);
  static const _border = Color(0xFF232D3F);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);

  static const _terms = [
    ('prelim', 'Prelim'),
    ('midterm', 'Midterm'),
    ('semi_finals', 'Pre-Finals'),
    ('finals', 'Finals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        return Container(
          color: _bg,
          child: Column(
            children: [
              _buildHeader(provider),
              Expanded(
                child: _showQuestions && _selectedAssessmentId != null
                    ? _buildQuestionsEditor(provider)
                    : _buildAssessmentList(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════

  Widget _buildHeader(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_showQuestions)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () =>
                      setState(() => _showQuestions = false),
                ),
              Expanded(
                child: Text(
                  _showQuestions ? 'Question Editor' : 'Assessments',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!_showQuestions) ...[
                _buildSubjectDropdown(provider),
                const SizedBox(width: 12),
                _buildExamRequestsButton(provider),
                const SizedBox(width: 12),
                _buildCreateButton(),
              ],
            ],
          ),
          if (!_showQuestions) ...[
            const SizedBox(height: 14),
            _buildTermTabs(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubjectId,
          hint: Text('Select Subject',
              style: GoogleFonts.inter(
                  color: const Color(0xFF4B5E78), fontSize: 12)),
          dropdownColor: _surface,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.expand_more_rounded,
              color: Color(0xFF4B5E78), size: 18),
          items: provider.subjects.map((s) {
            return DropdownMenuItem(
              value: s.id,
              child: Text('${s.subjectCode} — ${s.subjectTitle}',
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) {
            setState(() => _selectedSubjectId = v);
            if (v != null) provider.loadAssessments(v);
          },
        ),
      ),
    );
  }

  Widget _buildTermTabs() {
    return Row(
      children: _terms.map((t) {
        final isActive = _selectedTerm == t.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _selectedTerm = t.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? _accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isActive
                          ? _accent.withValues(alpha: 0.3)
                          : _border),
                ),
                child: Text(
                  t.$2,
                  style: GoogleFonts.inter(
                    color: isActive ? _accent : const Color(0xFF4B5E78),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreateButton() {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _selectedSubjectId != null ? _showCreateDialog : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('Create',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ASSESSMENT LIST
  // ═══════════════════════════════════════════════════

  Widget _buildAssessmentList(AdminProvider provider) {
    if (_selectedSubjectId == null) {
      return _emptyState(
          Icons.book_rounded, 'Select a subject', 'Choose a subject above to manage assessments');
    }

    final termAssessments = provider.assessmentsForTerm(_selectedTerm);
    if (termAssessments.isEmpty) {
      return _emptyState(Icons.assignment_rounded, 'No assessments yet',
          'Create a quiz or exam for this term');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: termAssessments.length,
      itemBuilder: (_, idx) =>
          _buildAssessmentCard(provider, termAssessments[idx]),
    );
  }

  Widget _buildAssessmentCard(
      AdminProvider provider, AssessmentConfig assessment) {
    final isExam = assessment.isExam;
    final color = isExam ? _amber : _accent;
    final minutes = assessment.timeLimitSecs ~/ 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExam ? 'EXAM' : 'QUIZ',
                  style: GoogleFonts.inter(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  assessment.title,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: !assessment.isPublished
                      ? const Color(0xFF374151).withValues(alpha: 0.5)
                      : assessment.isExpired
                          ? Colors.amber.withValues(alpha: 0.15)
                          : _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  !assessment.isPublished
                      ? 'Draft'
                      : assessment.isExpired
                          ? 'Expired (Closed)'
                          : assessment.availableUntil != null
                              ? 'Active • ${assessment.remainingAvailabilityFormatted}'
                              : 'Published',
                  style: GoogleFonts.inter(
                    color: !assessment.isPublished
                        ? const Color(0xFF6B7280)
                        : assessment.isExpired
                            ? Colors.amber
                            : _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip(Icons.timer_rounded, '$minutes min exam time'),
              if (assessment.isPublished && assessment.availableUntil != null) ...[
                const SizedBox(width: 10),
                _infoChip(
                  Icons.schedule_rounded,
                  assessment.isExpired
                      ? 'Window Expired'
                      : 'Closes in ${assessment.remainingAvailabilityFormatted}',
                ),
              ],
              if (isExam && assessment.setCount > 1) ...[
                const SizedBox(width: 10),
                _infoChip(Icons.copy_rounded, 'Set A/B'),
              ],
              if (isExam && assessment.sessionCode != null) ...[
                const SizedBox(width: 10),
                _infoChip(
                    Icons.check_circle_rounded, 
                    assessment.sessionCode!.contains('-') 
                        ? 'Notified: Set ${assessment.sessionCode!.split('-').last}'
                        : 'Notified'),
              ],
              const Spacer(),
              _actionBtn(
                  Icons.edit_note_rounded, 'Questions', _accent, () {
                setState(() {
                  _selectedAssessmentId = assessment.id;
                  _showQuestions = true;
                });
                provider.loadQuestions(assessment.id!);
              }),
              const SizedBox(width: 6),
              _actionBtn(
                  Icons.tune_rounded, 'Edit', const Color(0xFF8B5CF6), () {
                _showEditAssessmentDialog(provider, assessment);
              }),
              const SizedBox(width: 6),
              if (!assessment.isPublished) ...[
                _actionBtn(
                  Icons.publish_rounded,
                  'Publish',
                  _green,
                  () => _showPublishDialog(provider, assessment),
                ),
              ] else if (assessment.isExpired) ...[
                _actionBtn(
                  Icons.replay_rounded,
                  'Re-publish / Extend',
                  _amber,
                  () => _showPublishDialog(provider, assessment),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  Icons.visibility_off_rounded,
                  'Unpublish',
                  const Color(0xFF6B7280),
                  () => provider.publishAssessment(assessment.id!, false),
                ),
              ] else ...[
                _actionBtn(
                  Icons.schedule_rounded,
                  'Extend Period',
                  const Color(0xFF06B6D4),
                  () => _showPublishDialog(provider, assessment),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  Icons.visibility_off_rounded,
                  'Unpublish',
                  const Color(0xFF6B7280),
                  () => provider.publishAssessment(assessment.id!, false),
                ),
              ],
              if (isExam) ...[
                if (assessment.setCount > 1) ...[
                  const SizedBox(width: 6),
                  _actionBtn(Icons.play_arrow_rounded, 'Start Set A', _green, () {
                    provider.generateExamSessionCode(assessment.id!, targetSet: 'A');
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.play_arrow_rounded, 'Start Set B', _green, () {
                    provider.generateExamSessionCode(assessment.id!, targetSet: 'B');
                  }),
                ] else ...[
                  const SizedBox(width: 6),
                  _actionBtn(Icons.play_arrow_rounded, 'Start Exam', _green, () {
                    provider.generateExamSessionCode(assessment.id!);
                  }),
                ],
              ],
              const SizedBox(width: 6),
              _actionBtn(Icons.people_rounded, 'Submissions', const Color(0xFF3B82F6), () {
                _showSubmissionsDialog(provider, assessment);
              }),
              const SizedBox(width: 6),
              _actionBtn(Icons.copy_all_rounded, 'Duplicate', const Color(0xFF06B6D4), () {
                _confirmDuplicate(provider, assessment);
              }),
              const SizedBox(width: 6),
              _actionBtn(Icons.delete_rounded, 'Delete', Colors.red, () {
                _confirmDelete(provider, assessment);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF4B5E78), size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        hoverColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2E3D54), size: 48),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.inter(
                  color: const Color(0xFF4B5E78),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(sub,
              style: GoogleFonts.inter(
                  color: const Color(0xFF2E3D54), fontSize: 12)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // QUESTIONS EDITOR
  // ═══════════════════════════════════════════════════

  Widget _buildQuestionsEditor(AdminProvider provider) {
    final questions = provider.currentQuestions;

    return Column(
      children: [
        // Add question button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Text('${questions.length} Questions',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              _buildCreateButton2('Multiple Choice', () {
                _showAddQuestionDialog(provider, 'multiple_choice');
              }),
              const SizedBox(width: 8),
              _buildCreateButton2('Identification', () {
                _showAddQuestionDialog(provider, 'identification');
              }),
              const SizedBox(width: 8),
              _buildCreateButton2('Enumeration', () {
                _showAddQuestionDialog(provider, 'enumeration');
              }),
              const SizedBox(width: 8),
              _buildCreateButton2('Essay', () {
                _showAddQuestionDialog(provider, 'essay');
              }),
            ],
          ),
        ),
        Expanded(
          child: questions.isEmpty
              ? _emptyState(Icons.quiz_rounded, 'No questions yet',
                  'Add questions using the buttons above')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: questions.length,
                  itemBuilder: (_, idx) =>
                      _buildQuestionCard(provider, questions[idx], idx),
                ),
        ),
      ],
    );
  }

  Widget _buildCreateButton2(String label, VoidCallback onTap) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        hoverColor: _accent.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: _accent, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
      AdminProvider provider, AssessmentQuestion question, int idx) {
    final typeColor = question.isMultipleChoice
        ? _accent
        : question.isIdentification
            ? _green
            : question.isEnumeration
                ? _amber
                : Colors.purpleAccent;
    final typeLabel = question.isMultipleChoice
        ? 'MC'
        : question.isIdentification
            ? 'ID'
            : question.isEnumeration
                ? 'ENUM'
                : 'ESSAY';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF232D3F),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text('${idx + 1}',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(typeLabel,
                              style: GoogleFonts.inter(
                                  color: typeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Text('${question.points} pt${question.points > 1 ? "s" : ""}',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF4B5E78),
                                fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(question.questionText,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded,
                    color: const Color(0xFF4B5E78), size: 16),
                onPressed: () =>
                    _showEditQuestionDialog(provider, question),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.red[400], size: 16),
                onPressed: () => provider.deleteQuestion(question.id!),
              ),
            ],
          ),
          if (question.isMultipleChoice && question.choices != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: question.choices!.map((c) {
                final isCorrect =
                    c.trim().toLowerCase() ==
                        question.correctAnswer.trim().toLowerCase();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? _green.withValues(alpha: 0.12)
                        : const Color(0xFF232D3F),
                    borderRadius: BorderRadius.circular(6),
                    border: isCorrect
                        ? Border.all(color: _green.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCorrect) ...[
                        Icon(Icons.check_circle_rounded,
                            color: _green, size: 12),
                        const SizedBox(width: 4),
                      ],
                      Text(c,
                          style: GoogleFonts.inter(
                              color: isCorrect
                                  ? _green
                                  : const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: isCorrect
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: _green, size: 12),
                const SizedBox(width: 4),
                Text(
                  question.isEnumeration
                      ? (question.enumerationAnswers?.join(', ') ??
                          question.correctAnswer)
                      : question.correctAnswer,
                  style: GoogleFonts.inter(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final timeLimitCtrl = TextEditingController(text: '30');
    String type = 'quiz';
    int timeLimit = 30;
    int setCount = 1;
    bool isCreating = false;
    String? themeColor = '#6366F1';

    final colorOptions = [
      ('#6366F1', 'Indigo (Focus & Calm)'),
      ('#10B981', 'Emerald (Balance & Relief)'),
      ('#0EA5E9', 'Sky Blue (Clarity & Peace)'),
      ('#8B5CF6', 'Purple (Wisdom & Thought)'),
      ('#F59E0B', 'Amber (Energy & Warmth)'),
      ('#EC4899', 'Rose (Soft Accent)'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Text('Create Assessment',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogField('Title', titleCtrl, 'e.g. Prelim Quiz 1'),
                  const SizedBox(height: 14),
                  Text('Type',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _typeChip('Quiz', type == 'quiz', _accent, () {
                        setDialogState(() {
                          type = 'quiz';
                          setCount = 1;
                        });
                      }),
                      const SizedBox(width: 8),
                      _typeChip('Exam', type == 'exam', _amber, () {
                        setDialogState(() {
                          type = 'exam';
                          setCount = 2;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time Limit (Timer)',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$timeLimit min limit',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF60A5FA),
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [5, 10, 15, 20, 30, 45, 60, 90, 120].map((m) {
                      return _typeChip(
                        '$m min',
                        timeLimit == m,
                        const Color(0xFF3B82F6),
                        () => setDialogState(() {
                          timeLimit = m;
                          timeLimitCtrl.text = '$m';
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF60A5FA), size: 16),
                      const SizedBox(width: 8),
                      Text('Custom Minutes:',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          controller: timeLimitCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Mins',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF374151), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF232D3F),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v.trim());
                            if (parsed != null && parsed > 0) {
                              setDialogState(() => timeLimit = parsed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (type == 'exam') ...[
                    const SizedBox(height: 14),
                    Text('Set Count',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8B9AB2),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _typeChip('1 Set', setCount == 1,
                            const Color(0xFF8B5CF6), () {
                          setDialogState(() => setCount = 1);
                        }),
                        const SizedBox(width: 8),
                        _typeChip('2 Sets (A/B)', setCount == 2,
                            const Color(0xFF8B5CF6), () {
                          setDialogState(() => setCount = 2);
                        }),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text('Theme Color',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((c) {
                      final hex = c.$1;
                      final name = c.$2;
                      final colorObj = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
                      return _typeChip(
                        name,
                        themeColor == hex,
                        colorObj,
                        () => setDialogState(() => themeColor = hex),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: isCreating ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                
                final finalMinutes = int.tryParse(timeLimitCtrl.text.trim()) ?? timeLimit;
                final validMinutes = finalMinutes > 0 ? finalMinutes : 30;

                setDialogState(() => isCreating = true);
                try {
                  final config = AssessmentConfig(
                    subjectId: _selectedSubjectId!,
                    term: _selectedTerm,
                    type: type,
                    title: titleCtrl.text.trim(),
                    timeLimitSecs: validMinutes * 60,
                    setCount: setCount,
                    themeColor: themeColor,
                  );
                  await context
                      .read<AdminProvider>()
                      .createAssessment(config);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create assessment: $e'),
                        backgroundColor: Colors.red,
                      )
                    );
                  }
                } finally {
                  if (ctx.mounted) {
                    setDialogState(() => isCreating = false);
                  }
                }
              },
              child: isCreating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Create',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAssessmentDialog(
      AdminProvider provider, AssessmentConfig assessment) {
    final titleCtrl = TextEditingController(text: assessment.title);
    final initialMinutes = (assessment.timeLimitSecs / 60).round();
    final timeLimitCtrl = TextEditingController(text: '$initialMinutes');
    String type = assessment.type;
    String term = assessment.term;
    int timeLimit = initialMinutes > 0 ? initialMinutes : 30;
    int setCount = assessment.setCount;
    bool isSaving = false;
    String? themeColor = assessment.themeColor ?? '#6366F1';

    final colorOptions = [
      ('#6366F1', 'Indigo (Focus & Calm)'),
      ('#10B981', 'Emerald (Balance & Relief)'),
      ('#0EA5E9', 'Sky Blue (Clarity & Peace)'),
      ('#8B5CF6', 'Purple (Wisdom & Thought)'),
      ('#F59E0B', 'Amber (Energy & Warmth)'),
      ('#EC4899', 'Rose (Soft Accent)'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              Text('Edit Assessment Settings',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogField('Title', titleCtrl, 'e.g. Prelim Quiz 1'),
                  const SizedBox(height: 14),
                  Text('Term',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _terms.map((t) {
                      return _typeChip(
                        t.$2,
                        term == t.$1,
                        _accent,
                        () => setDialogState(() => term = t.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Type',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _typeChip('Quiz', type == 'quiz', _accent, () {
                        setDialogState(() {
                          type = 'quiz';
                          setCount = 1;
                        });
                      }),
                      const SizedBox(width: 8),
                      _typeChip('Exam', type == 'exam', _amber, () {
                        setDialogState(() {
                          type = 'exam';
                          if (setCount < 2) setCount = 2;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time Limit (Timer)',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$timeLimit min limit',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF60A5FA),
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [5, 10, 15, 20, 30, 45, 60, 90, 120].map((m) {
                      return _typeChip(
                        '$m min',
                        timeLimit == m,
                        const Color(0xFF3B82F6),
                        () => setDialogState(() {
                          timeLimit = m;
                          timeLimitCtrl.text = '$m';
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF60A5FA), size: 16),
                      const SizedBox(width: 8),
                      Text('Custom Minutes:',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          controller: timeLimitCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Mins',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF374151), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF232D3F),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v.trim());
                            if (parsed != null && parsed > 0) {
                              setDialogState(() => timeLimit = parsed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (type == 'exam') ...[
                    const SizedBox(height: 14),
                    Text('Set Count',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8B9AB2),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _typeChip('1 Set', setCount == 1,
                            const Color(0xFF8B5CF6), () {
                          setDialogState(() => setCount = 1);
                        }),
                        const SizedBox(width: 8),
                        _typeChip('2 Sets (A/B)', setCount == 2,
                            const Color(0xFF8B5CF6), () {
                          setDialogState(() => setCount = 2);
                        }),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text('Theme Color',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((c) {
                      final hex = c.$1;
                      final name = c.$2;
                      final colorObj = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
                      return _typeChip(
                        name,
                        themeColor == hex,
                        colorObj,
                        () => setDialogState(() => themeColor = hex),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: isSaving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                
                final finalMinutes = int.tryParse(timeLimitCtrl.text.trim()) ?? timeLimit;
                final validMinutes = finalMinutes > 0 ? finalMinutes : 30;

                setDialogState(() => isSaving = true);
                try {
                  final updated = assessment.copyWith(
                    title: titleCtrl.text.trim(),
                    term: term,
                    type: type,
                    timeLimitSecs: validMinutes * 60,
                    setCount: setCount,
                    themeColor: themeColor,
                  );
                  await provider.updateAssessment(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update assessment: $e'),
                        backgroundColor: Colors.red,
                      )
                    );
                  }
                } finally {
                  if (ctx.mounted) {
                    setDialogState(() => isSaving = false);
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Changes',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublishDialog(
      AdminProvider provider, AssessmentConfig assessment) {
    int durationHours = 3;
    int durationMinutes = 0;
    bool isCustom = false;
    bool noExpiration = false;
    final hoursCtrl = TextEditingController(text: '3');
    final minsCtrl = TextEditingController(text: '0');
    bool isPublishing = false;

    final presets = [
      (0, 30, '30 mins'),
      (1, 0, '1 hour'),
      (2, 0, '2 hours'),
      (3, 0, '3 hours'),
      (6, 0, '6 hours'),
      (12, 0, '12 hours'),
      (24, 0, '24 hours (1 day)'),
      (48, 0, '48 hours (2 days)'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          DateTime? calculatedExpiry;
          if (!noExpiration) {
            final totalMinutes = (durationHours * 60) + durationMinutes;
            if (totalMinutes > 0) {
              calculatedExpiry = DateTime.now().add(Duration(minutes: totalMinutes));
            }
          }

          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.schedule_send_rounded, color: _green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Publish & Set Submission Period',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(assessment.title,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose how long this ${assessment.isExam ? "exam" : "quiz"} will appear and accept submissions from students.',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF8B9AB2),
                          fontSize: 13,
                          height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Text('Quick Duration Presets',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8B9AB2),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...presets.map((p) {
                          final isSelected = !noExpiration && !isCustom && durationHours == p.$1 && durationMinutes == p.$2;
                          return _typeChip(
                            p.$3,
                            isSelected,
                            _green,
                            () => setDialogState(() {
                              noExpiration = false;
                              isCustom = false;
                              durationHours = p.$1;
                              durationMinutes = p.$2;
                              hoursCtrl.text = '${p.$1}';
                              minsCtrl.text = '${p.$2}';
                            }),
                          );
                        }),
                        _typeChip(
                          'No Expiration',
                          noExpiration,
                          _accent,
                          () => setDialogState(() {
                            noExpiration = true;
                            isCustom = false;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Or Custom Duration',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8B9AB2),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hours', style: GoogleFonts.inter(color: const Color(0xFF8B9AB2), fontSize: 10)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: hoursCtrl,
                                enabled: !noExpiration,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF232D3F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (v) {
                                  final h = int.tryParse(v.trim()) ?? 0;
                                  setDialogState(() {
                                    isCustom = true;
                                    noExpiration = false;
                                    durationHours = h;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Minutes', style: GoogleFonts.inter(color: const Color(0xFF8B9AB2), fontSize: 10)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: minsCtrl,
                                enabled: !noExpiration,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF232D3F),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (v) {
                                  final m = int.tryParse(v.trim()) ?? 0;
                                  setDialogState(() {
                                    isCustom = true;
                                    noExpiration = false;
                                    durationMinutes = m;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232D3F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            noExpiration ? Icons.all_inclusive_rounded : Icons.info_outline_rounded,
                            color: noExpiration ? _accent : _green,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  noExpiration
                                      ? 'Published with No Time Limit'
                                      : 'Available for ${durationHours > 0 ? "$durationHours hr " : ""}${durationMinutes > 0 ? "$durationMinutes min" : ""}',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  noExpiration
                                      ? 'Students can take this assessment until you manually click Unpublish.'
                                      : 'Students can take and submit this assessment until ${calculatedExpiry != null ? _formatDateTime(calculatedExpiry) : "the period expires"}. Afterwards, it will automatically disappear for students.',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF8B9AB2),
                                      fontSize: 11,
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: isPublishing
                    ? null
                    : () async {
                        setDialogState(() => isPublishing = true);
                        try {
                          await provider.publishAssessment(
                            assessment.id!,
                            true,
                            availableUntil: calculatedExpiry,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Publish error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isPublishing = false);
                          }
                        }
                      },
                child: isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Publish Now',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${monthNames[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }

  Widget _typeChip(
      String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : const Color(0xFF232D3F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? color.withValues(alpha: 0.4) : _border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: active ? color : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _dialogField(
      String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xFF8B9AB2),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFF374151), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF232D3F),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _showAddQuestionDialog(
      AdminProvider provider, String questionType) {
    final textCtrl = TextEditingController();
    final answerCtrl = TextEditingController();
    final choicesCtrls = List.generate(4, (_) => TextEditingController());
    final enumCtrls = List.generate(5, (_) => TextEditingController());
    final pointsCtrl = TextEditingController(text: '1');
    int correctIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            title: Text(
              'Add ${questionType == 'multiple_choice' ? 'Multiple Choice' : questionType == 'identification' ? 'Identification' : questionType == 'essay' ? 'Essay' : 'Enumeration'}',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogField('Question', textCtrl, 'Enter question text'),
                    const SizedBox(height: 12),
                    _dialogField('Points', pointsCtrl, '1'),
                    const SizedBox(height: 12),
                    if (questionType == 'multiple_choice') ...[
                      Text('Choices (tap to mark correct)',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...List.generate(4, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setDialogState(() => correctIdx = i),
                                child: Icon(
                                  correctIdx == i
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: correctIdx == i
                                      ? _green
                                      : const Color(0xFF4B5E78),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: choicesCtrls[i],
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Choice ${String.fromCharCode(65 + i)}',
                                    hintStyle: GoogleFonts.inter(
                                        color: const Color(0xFF374151),
                                        fontSize: 12),
                                    filled: true,
                                    fillColor: const Color(0xFF232D3F),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else if (questionType == 'identification') ...[
                      _dialogField(
                          'Correct Answer', answerCtrl, 'Enter correct answer'),
                    ] else if (questionType == 'essay') ...[
                      const SizedBox(height: 12),
                      Text('Essays do not have predefined correct answers. They will require manual grading.',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ] else ...[
                      Text('Correct Answers (fill in all)',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...List.generate(5, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: TextField(
                            controller: enumCtrls[i],
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Answer ${i + 1} (optional)',
                              hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFF374151),
                                  fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF232D3F),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style:
                        GoogleFonts.inter(color: const Color(0xFF4B5E78))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  if (textCtrl.text.trim().isEmpty) return;

                  String correctAnswer = '';
                  List<String>? choices;
                  List<String>? enumAnswers;

                  if (questionType == 'multiple_choice') {
                    choices = choicesCtrls
                        .map((c) => c.text.trim())
                        .where((c) => c.isNotEmpty)
                        .toList();
                    if (choices.isEmpty) return;
                    correctAnswer = choices[correctIdx];
                  } else if (questionType == 'identification') {
                    correctAnswer = answerCtrl.text.trim();
                    if (correctAnswer.isEmpty) return;
                  } else if (questionType == 'essay') {
                    correctAnswer = 'Requires Manual Grading';
                  } else {
                    enumAnswers = enumCtrls
                        .map((c) => c.text.trim())
                        .where((c) => c.isNotEmpty)
                        .toList();
                    if (enumAnswers.isEmpty) return;
                    correctAnswer = enumAnswers.join(',');
                  }

                  final question = AssessmentQuestion(
                    assessmentId: _selectedAssessmentId!,
                    questionOrder: provider.currentQuestions.length,
                    questionText: textCtrl.text.trim(),
                    questionType: questionType,
                    choices: choices,
                    correctAnswer: correctAnswer,
                    enumerationAnswers: enumAnswers,
                    points: double.tryParse(pointsCtrl.text) ?? 1,
                  );
                  
                  try {
                    await provider.addQuestion(question);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add question: $e'),
                          backgroundColor: Colors.red,
                        )
                      );
                    }
                  }
                },
                child: Text('Add',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditQuestionDialog(
      AdminProvider provider, AssessmentQuestion question) {
    final textCtrl = TextEditingController(text: question.questionText);
    final answerCtrl = TextEditingController(text: question.correctAnswer);
    final pointsCtrl =
        TextEditingController(text: question.points.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('Edit Question',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Question', textCtrl, ''),
                const SizedBox(height: 12),
                _dialogField('Correct Answer', answerCtrl, ''),
                const SizedBox(height: 12),
                _dialogField('Points', pointsCtrl, '1'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final updated = question.copyWith(
                questionText: textCtrl.text.trim(),
                correctAnswer: answerCtrl.text.trim(),
                points: double.tryParse(pointsCtrl.text) ?? 1,
              );
              await provider.updateQuestion(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Save',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }



  void _showSubmissionsDialog(
      AdminProvider provider, AssessmentConfig assessment) async {
    await provider.loadSubmissions(assessment.id!);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Consumer<AdminProvider>(
        builder: (_, p, __) {
          final subs = p.currentSubmissions;
          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            title: Text('Submissions — ${assessment.title}',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 500,
              height: 400,
              child: subs.isEmpty
                  ? Center(
                      child: Text('No submissions yet',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF4B5E78))))
                  : ListView.builder(
                      itemCount: subs.length,
                      itemBuilder: (_, i) {
                        final s = subs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232D3F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        s.studentName ??
                                            'Unknown',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600)),
                                    Text(s.studentUsn ?? '',
                                        style: GoogleFonts.inter(
                                            color: const Color(
                                                0xFF4B5E78),
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (s.setLabel != null)
                                Container(
                                  margin: const EdgeInsets.only(
                                      right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _amber
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text('Set ${s.setLabel}',
                                      style: GoogleFonts.inter(
                                          color: _amber,
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w700)),
                                ),
                              Text(
                                  '${s.score.toStringAsFixed(0)}/${s.maxScore.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              Text(s.percentage,
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Icon(
                                s.isGraded
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_rounded,
                                color: s.isGraded
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF4B5E78),
                                size: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF4B5E78))),
              ),
            ],
          );
        },
      ),
    );
  }



  void _confirmDelete(
      AdminProvider provider, AssessmentConfig assessment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Assessment?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently delete "${assessment.title}" and all its questions, submissions, and answers.',
            style: GoogleFonts.inter(
                color: const Color(0xFF8B9AB2), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              await provider.deleteAssessment(assessment.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamRequestsButton(AdminProvider provider) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _selectedSubjectId != null
            ? () => _showExamRequestsDialog(provider)
            : null,
        hoverColor: const Color(0xFF10B981).withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _selectedSubjectId != null
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in_rounded,
                  color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 6),
              Text(
                'Exam Requests',
                style: GoogleFonts.inter(
                  color: _selectedSubjectId != null
                      ? const Color(0xFF10B981)
                      : const Color(0xFF4B5E78),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExamRequestsDialog(AdminProvider provider) {
    if (_selectedSubjectId == null) return;
    provider.loadExamRequests(_selectedSubjectId!);

    showDialog(
      context: context,
      builder: (ctx) => Consumer<AdminProvider>(
        builder: (ctx, prov, _) {
          final requests = prov.examRequests;

          return AlertDialog(
            backgroundColor: _surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded,
                    color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Submitted Exam Requests / Permits',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF8B9AB2), size: 18),
                  onPressed: () => prov.loadExamRequests(_selectedSubjectId!),
                ),
              ],
            ),
            content: SizedBox(
              width: 650,
              height: 480,
              child: requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_rounded,
                              color: Color(0xFF2E3D54), size: 48),
                          const SizedBox(height: 12),
                          Text('No exam requests submitted yet',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF8B9AB2),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              'Students can submit proctor details and signature/permit attachments.',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF4B5E78),
                                  fontSize: 11)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (_, idx) {
                        final req = requests[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131B2B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.studentName ?? 'Student',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          'USN: ${req.studentUsn ?? "—"} • Course: ${req.course} • Section: ${req.section}',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFF8B9AB2),
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      req.status.toUpperCase(),
                                      style: GoogleFonts.inter(
                                          color: const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 18),
                                    onPressed: () async {
                                      await prov.deleteExamRequest(
                                          req.id!, _selectedSubjectId!);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2235),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Subject: ${req.subjectName}',
                                              style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                          const SizedBox(height: 2),
                                          Text(
                                              'Proctor Name: ${req.proctorName}',
                                              style: GoogleFonts.inter(
                                                  color: const Color(0xFF60A5FA),
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    if (req.proctorSignatureUrl != null &&
                                        req.proctorSignatureUrl!.isNotEmpty)
                                      InkWell(
                                        onTap: () => _viewImageDialog(
                                            ctx,
                                            req.proctorSignatureUrl!,
                                            'Proctor Signature'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFF6366F1)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.draw_rounded,
                                                  color: Color(0xFF818CF8),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text('Signature',
                                                  style: GoogleFonts.inter(
                                                      color:
                                                          const Color(0xFF818CF8),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (req.documentImageUrl != null &&
                                        req.documentImageUrl!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _viewImageDialog(
                                            ctx,
                                            req.documentImageUrl!,
                                            'Exam Permit / Document'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFF10B981)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.image_rounded,
                                                  color: Color(0xFF34D399),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text('Document',
                                                  style: GoogleFonts.inter(
                                                      color:
                                                          const Color(0xFF34D399),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close',
                    style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewImageDialog(
      BuildContext parentContext, String imageUrl, String title) {
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text('Could not load image: $imageUrl',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
          ),
        ],
      ),
    );
  }

  void _confirmDuplicate(
      AdminProvider provider, AssessmentConfig assessment) {
    bool isDuplicating = false;
    bool isLoadingSubjects = true;
    List<Subject> candidateSubjects = [];
    final Set<String> selectedSubjectIds = {};
    bool showAllSubjects = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          if (isLoadingSubjects) {
            // Load candidates on first open
            Future.microtask(() async {
              try {
                final list =
                    await provider.getSubjectsWithSameCode(assessment.subjectId);
                if (ctx.mounted) {
                  setDlgState(() {
                    candidateSubjects = list;
                    for (final s in list) {
                      if (s.id != null) selectedSubjectIds.add(s.id!);
                    }
                    isLoadingSubjects = false;
                  });
                }
              } catch (_) {
                if (ctx.mounted) {
                  setDlgState(() => isLoadingSubjects = false);
                }
              }
            });
          }

          final displaySubjects = showAllSubjects
              ? provider.subjects
                  .where((s) => s.id != assessment.subjectId)
                  .toList()
              : candidateSubjects;

          return AlertDialog(
            backgroundColor: _surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                const Icon(Icons.copy_all_rounded,
                    color: Color(0xFF06B6D4), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Duplicate Assessment',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 440,
              child: isLoadingSubjects
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose target classes/sections to clone "${assessment.title}" and all its questions into:',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8B9AB2), fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${selectedSubjectIds.length} of ${displaySubjects.length} selected',
                              style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.select_all_rounded,
                                  size: 14, color: Color(0xFF06B6D4)),
                              label: Text(
                                selectedSubjectIds.length == displaySubjects.length
                                    ? 'Deselect All'
                                    : 'Select All',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF06B6D4),
                                    fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                setDlgState(() {
                                  if (selectedSubjectIds.length ==
                                      displaySubjects.length) {
                                    selectedSubjectIds.clear();
                                  } else {
                                    for (final s in displaySubjects) {
                                      if (s.id != null) {
                                        selectedSubjectIds.add(s.id!);
                                      }
                                    }
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setDlgState(() {
                                  showAllSubjects = !showAllSubjects;
                                  if (showAllSubjects) {
                                    for (final s in provider.subjects) {
                                      if (s.id != null &&
                                          s.id != assessment.subjectId) {
                                        selectedSubjectIds.add(s.id!);
                                      }
                                    }
                                  } else {
                                    selectedSubjectIds.clear();
                                    for (final s in candidateSubjects) {
                                      if (s.id != null) {
                                        selectedSubjectIds.add(s.id!);
                                      }
                                    }
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: showAllSubjects
                                      ? const Color(0xFF6366F1)
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: showAllSubjects
                                          ? const Color(0xFF6366F1)
                                          : _border),
                                ),
                                child: Text(
                                  showAllSubjects
                                      ? 'All Subjects'
                                      : 'Same Code Only',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: showAllSubjects
                                          ? const Color(0xFF818CF8)
                                          : Colors.grey[400]),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: displaySubjects.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.inbox_rounded,
                                          color: Color(0xFF2E3D54), size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No other subjects found with the same subject code.',
                                        style: GoogleFonts.inter(
                                            color: const Color(0xFF8B9AB2),
                                            fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: displaySubjects.length,
                                  itemBuilder: (_, idx) {
                                    final sub = displaySubjects[idx];
                                    final isSelected =
                                        selectedSubjectIds.contains(sub.id);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF06B6D4)
                                                .withValues(alpha: 0.08)
                                            : const Color(0xFF131B2B),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF06B6D4)
                                                  .withValues(alpha: 0.4)
                                              : _border,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        dense: true,
                                        activeColor: const Color(0xFF06B6D4),
                                        checkColor: Colors.white,
                                        value: isSelected,
                                        onChanged: (val) {
                                          setDlgState(() {
                                            if (val == true && sub.id != null) {
                                              selectedSubjectIds.add(sub.id!);
                                            } else {
                                              selectedSubjectIds
                                                  .remove(sub.id);
                                            }
                                          });
                                        },
                                        title: Text(
                                          '${sub.subjectCode} — ${sub.subjectTitle}',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          'Schedule: ${sub.formattedSchedule.isNotEmpty ? sub.formattedSchedule : "TBA"} • Room: ${sub.room.isNotEmpty ? sub.room : "TBA"}',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFF8B9AB2),
                                              fontSize: 11),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFF06B6D4), size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cloned assessments will be in Draft status in the selected subjects.',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF06B6D4),
                                      fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: isDuplicating ? null : () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF4B5E78))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: (isDuplicating || selectedSubjectIds.isEmpty)
                    ? null
                    : () async {
                        setDlgState(() => isDuplicating = true);
                        try {
                          final count = await provider
                              .duplicateAssessmentToSubjects(
                            assessment.id!,
                            selectedSubjectIds.toList(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully duplicated to $count subject${count != 1 ? "s" : ""}!',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Duplicate failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDlgState(() => isDuplicating = false);
                          }
                        }
                      },
                child: isDuplicating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Duplicate to (${selectedSubjectIds.length})',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
