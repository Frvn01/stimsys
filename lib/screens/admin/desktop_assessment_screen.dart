import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/admin_provider.dart';
import '../../models/assessment_model.dart';
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
                  color: assessment.isPublished
                      ? _green.withValues(alpha: 0.12)
                      : const Color(0xFF374151).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assessment.isPublished ? 'Published' : 'Draft',
                  style: GoogleFonts.inter(
                    color: assessment.isPublished
                        ? _green
                        : const Color(0xFF6B7280),
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
              _infoChip(Icons.timer_rounded, '$minutes min'),
              const SizedBox(width: 10),
              if (isExam && assessment.setCount > 1)
                _infoChip(Icons.copy_rounded, 'Set A/B'),
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
                Icons.visibility_rounded,
                assessment.isPublished ? 'Unpublish' : 'Publish',
                assessment.isPublished ? const Color(0xFF6B7280) : _green,
                () => provider.publishAssessment(
                    assessment.id!, !assessment.isPublished),
              ),
              if (isExam) ...[
                if (assessment.setCount > 1) ...[
                  const SizedBox(width: 6),
                  _actionBtn(Icons.notifications_active_rounded, 'Notify Set A', _green, () {
                    provider.generateExamSessionCode(assessment.id!, targetSet: 'A');
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.notifications_active_rounded, 'Notify Set B', _green, () {
                    provider.generateExamSessionCode(assessment.id!, targetSet: 'B');
                  }),
                ] else ...[
                  const SizedBox(width: 6),
                  _actionBtn(Icons.notifications_active_rounded, 'Start Exam', _green, () {
                    provider.generateExamSessionCode(assessment.id!);
                  }),
                ],
              ],
              const SizedBox(width: 6),
              _actionBtn(Icons.people_rounded, 'Submissions', const Color(0xFF3B82F6), () {
                _showSubmissionsDialog(provider, assessment);
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
    String type = 'quiz';
    int timeLimit = 30;
    int setCount = 1;
    bool isCreating = false;

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
            width: 400,
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
                Text('Time Limit (minutes)',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF8B9AB2),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [15, 30, 45, 60, 90, 120].map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _typeChip(
                        '$m',
                        timeLimit == m,
                        const Color(0xFF3B82F6),
                        () => setDialogState(() => timeLimit = m),
                      ),
                    );
                  }).toList(),
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
              ],
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
                
                setDialogState(() => isCreating = true);
                try {
                  final config = AssessmentConfig(
                    subjectId: _selectedSubjectId!,
                    term: _selectedTerm,
                    type: type,
                    title: titleCtrl.text.trim(),
                    timeLimitSecs: timeLimit * 60,
                    setCount: setCount,
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
}
