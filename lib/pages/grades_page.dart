import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';
import '../models/grading_config_model.dart';
import '../models/student_grade_model.dart';
import '../models/student_grade_item_model.dart';
import '../utils/attendance_utils.dart';
import '../providers/appearance_provider.dart';
import '../widgets/common/glass_card.dart';

class GradesPage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const GradesPage({super.key, required this.themeProvider});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  int? _selectedSubjectIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<StudentProvider>();
      if (provider.attendanceRecords.isEmpty) {
        provider.loadAttendance();
      }
      // Term ranges + cancelled days → needed to compute attendance from
      // the expected class days rather than only the recorded ones, then
      // bring the stored attendance scores in line with that calculation.
      await provider.loadAttendanceContext();
      if (!mounted) return;
      await provider.refreshAttendanceGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final enrollments = provider.enrollments;
        final allAttendance = provider.attendanceRecords;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + subject selector ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 16),
                  _buildAttendanceBanner(isDark, allAttendance, enrollments, provider),
                  const SizedBox(height: 18),
                  _buildSubjectSelector(isDark, enrollments, provider),
                ],
              ),
            ),

            // ── Spreadsheet body ──
            Expanded(
              child: _selectedSubjectIndex != null &&
                      _selectedSubjectIndex! < enrollments.length
                  ? _ClassRecordSheet(
                      isDark: isDark,
                      enrollment: enrollments[_selectedSubjectIndex!],
                      provider: provider,
                    )
                  : _buildSelectSubjectPrompt(isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Icon(Icons.table_chart_rounded,
            color: const Color(0xFF6366F1), size: 26),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Class Record',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3)),
          Text('Grading sheet & performance breakdown',
              style: TextStyle(
                  fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
        ]),
      ],
    );
  }

  /// Tally attendance across every enrolled subject using each subject's
  /// *expected* class days (schedule ∩ term dates), so a class day the student
  /// was never recorded for counts as an absence instead of vanishing from
  /// the calculation.
  ({
    int present,
    int late,
    int absent,
    int excused,
    int total,
  }) _attendanceTally(
    List<AttendanceRecord> records,
    List<Enrollment> enrollments,
    StudentProvider provider,
  ) {
    final byEnrollment = <String, List<AttendanceRecord>>{};
    for (final r in records) {
      byEnrollment.putIfAbsent(r.enrollmentId, () => []).add(r);
    }

    var present = 0, late = 0, absent = 0, excused = 0, total = 0;

    void add(AttendanceSummary s) {
      if (s.total == 0) return;
      present += s.present;
      late += s.late;
      // Unrecorded days are absences as far as the student is concerned.
      absent += s.absent + s.missing;
      excused += s.excused;
      total += s.total;
    }

    final covered = <String>{};
    for (final e in enrollments) {
      final id = e.id;
      if (id == null) continue;
      covered.add(id);
      final recs = byEnrollment[id];
      if (recs == null || recs.isEmpty) continue; // nothing recorded yet

      final config = provider.gradingConfigFor(e.subjectId);
      add(summarizeAttendance(
        records: recs,
        scheduleDay: e.scheduleDay ?? recs.first.scheduleDay,
        rangeStart:
            config?.prelimStart ?? e.enrolledAt ?? recs.first.enrolledAt,
        rangeEnd: config?.finalsEnd,
        cancelledDates: provider.cancelledDatesFor(e.subjectId),
      ));
    }

    // Records for enrollments no longer in the list (dropped/withdrawn).
    byEnrollment.forEach((id, recs) {
      if (covered.contains(id) || recs.isEmpty) return;
      add(summarizeAttendance(
        records: recs,
        scheduleDay: recs.first.scheduleDay,
        rangeStart: recs.first.enrolledAt,
      ));
    });

    return (
      present: present,
      late: late,
      absent: absent,
      excused: excused,
      total: total,
    );
  }

  Widget _buildAttendanceBanner(bool isDark, List<AttendanceRecord> all,
      List<Enrollment> enrollments, StudentProvider provider) {
    final tally = _attendanceTally(all, enrollments, provider);
    final present = tally.present;
    final late = tally.late;
    final absent = tally.absent;
    final rate =
        tally.total == 0 ? 0.0 : (present + late + tally.excused) / tally.total;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF6366F1).withValues(alpha: 0.55),
                const Color(0xFF8B5CF6).withValues(alpha: 0.40)
              ]
            : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.how_to_reg_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Overall Attendance',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8))),
              Text('${(rate * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1)),
            ])),
        _bannerChip('P', present, const Color(0xFF10B981)),
        const SizedBox(width: 6),
        _bannerChip('L', late, const Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        _bannerChip('A', absent, const Color(0xFFEF4444)),
      ]),
    );
  }

  Widget _bannerChip(String label, int count, Color color) {
    return Container(
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildSubjectSelector(
      bool isDark, List<Enrollment> enrollments, StudentProvider provider) {
    if (enrollments.isEmpty) {
      return const SizedBox.shrink();
    }

    final appearance = context.watch<AppearanceProvider>();
    final chipColor = appearance.glassTint;
    final chipOpacity = appearance.glassOpacity;
    final chipDuration =
        appearance.animateDuration(const Duration(milliseconds: 220));

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: enrollments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final e = enrollments[i];
          final isSelected = _selectedSubjectIndex == i;
          final color = _subjectColor(e.subjectCode, i);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedSubjectIndex = i);
              provider.loadGradesForSubject(e);
            },
            child: AnimatedContainer(
              duration: chipDuration,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : chipColor.withValues(alpha: chipOpacity),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? color
                      : chipColor.withValues(
                          alpha: (chipOpacity + 0.2).clamp(0.0, 1.0)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  e.subjectCode ?? 'Subject',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectSubjectPrompt(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.table_chart_outlined,
            color: Colors.grey[600], size: 48),
        const SizedBox(height: 12),
        Text('Select a subject above',
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('to view your class record',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }

  static const _colors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
  ];

  Color _subjectColor(String? code, int index) {
    if (index >= 0) {
      return _colors[index % _colors.length];
    }
    final hash = (code?.hashCode ?? 0).abs();
    return _colors[hash % _colors.length];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Class Record Spreadsheet
// ═══════════════════════════════════════════════════════════════════════════════

class _ClassRecordSheet extends StatefulWidget {
  final bool isDark;
  final Enrollment enrollment;
  final StudentProvider provider;

  const _ClassRecordSheet({
    required this.isDark,
    required this.enrollment,
    required this.provider,
  });

  @override
  State<_ClassRecordSheet> createState() => _ClassRecordSheetState();
}

class _ClassRecordSheetState extends State<_ClassRecordSheet> {
  int _selectedTermIndex = 0;

  // Spreadsheet colors
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _surfaceLight = Color(0xFFF8FAFC);
  static const _border = Color(0xFF2D3B52);
  static const _borderLight = Color(0xFFE2E8F0);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _purple = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = widget.provider;
    final enrollment = widget.enrollment;

    if (provider.gradesLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: _accent, strokeWidth: 2));
    }

    final config =
        provider.gradingConfigFor(enrollment.subjectId ?? '');

    if (config == null) {
      return _buildNoConfig(isDark);
    }

    final terms = config.terms;
    final enrollmentId = enrollment.id ?? '';

    return Column(children: [
      // ── Subject title bar ──
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? _surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border.all(color: isDark ? _border : _borderLight),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(enrollment.subjectTitle ?? 'Subject',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(enrollment.subjectCode ?? '',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _accent)),
                ),
                const SizedBox(width: 8),
                Text(
                    enrollment.scheduleDay ?? '',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[500])),
              ]),
            ]),
          ),
          // Weights badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _green.withValues(alpha: 0.2)),
            ),
            child: Text(
              'E${config.examPct.toStringAsFixed(0)} · Q${config.quizPct.toStringAsFixed(0)} · A${config.attendancePct.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _green),
            ),
          ),
        ]),
      ),

      // ── Term tabs ──
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? _bg : Colors.grey.shade200,
          border: Border.symmetric(
              horizontal:
                  BorderSide(color: isDark ? _border : _borderLight)),
        ),
        child: Row(
          children: [
            ...terms.asMap().entries.map((entry) {
              final i = entry.key;
              final term = entry.value;
              return _termTab(
                  GradingConfig.termLabel(term), i, isDark);
            }),
            _termTab('Final', terms.length, isDark,
                isFinal: true),
          ],
        ),
      ),

      // ── Spreadsheet content ──
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? _surface : Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(10)),
            border: Border.all(color: isDark ? _border : _borderLight),
          ),
          child: _selectedTermIndex < terms.length
              ? _buildTermSpreadsheet(
                  isDark, provider, enrollmentId,
                  terms[_selectedTermIndex], config)
              : _buildFinalSpreadsheet(
                  isDark, provider, enrollmentId, config, terms),
        ),
      ),
    ]);
  }

  Widget _termTab(String label, int index, bool isDark,
      {bool isFinal = false}) {
    final isSelected = _selectedTermIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTermIndex = index),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? (isFinal ? _accent : _accent)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[500] : Colors.grey[600]),
                )),
          ),
        ),
      ),
    );
  }

  // ── Per-term spreadsheet ──────────────────────────────────────────

  Widget _buildTermSpreadsheet(
    bool isDark,
    StudentProvider provider,
    String enrollmentId,
    String term,
    GradingConfig config,
  ) {
    final grade = provider.gradeFor(enrollmentId, term);
    final items = grade?.id != null
        ? provider.gradeItemsFor(grade!.id!)
        : <StudentGradeItem>[];
    final liveAttendance = provider.liveAttendanceFor(enrollmentId);

    final quizItems = items.where((i) => i.isQuiz).toList();
    final activityItems = items.where((i) => i.isActivity).toList();
    final examItems = items.where((i) => i.isExam).toList();

    final bdr = isDark ? _border : _borderLight;
    final headerBg = isDark ? _bg : Colors.grey.shade100;
    final cellBg = isDark ? _surface : Colors.white;
    final altBg = isDark
        ? const Color(0xFF1A2435)
        : const Color(0xFFF1F5F9);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
      child: Column(children: [
        // ═══ EXAM SECTION ═══
        _sectionHeader('EXAM', Icons.school_rounded, _purple,
            '${config.examPct.toStringAsFixed(0)}%', isDark, bdr),
        if (examItems.isEmpty)
          _emptyRow('No exam items', isDark, bdr)
        else
          ...examItems.asMap().entries.map((e) =>
              _itemRow(e.value, e.key.isEven ? cellBg : altBg, isDark, bdr)),
        if (grade?.examRaw != null)
          _subtotalRow('Exam Subtotal', grade!.examRaw!, grade.examMax ?? 0,
              _purple, isDark, bdr),

        // ═══ QUIZ SECTION ═══
        _sectionHeader('QUIZ', Icons.quiz_rounded, _accent,
            null, isDark, bdr),
        if (quizItems.isEmpty)
          _emptyRow('No quiz items', isDark, bdr)
        else
          ...quizItems.asMap().entries.map((e) =>
              _itemRow(e.value, e.key.isEven ? cellBg : altBg, isDark, bdr)),

        // ═══ ACTIVITY SECTION ═══
        _sectionHeader('ACTIVITY', Icons.assignment_turned_in_rounded, _amber,
            null, isDark, bdr),
        if (activityItems.isEmpty)
          _emptyRow('No activity items (online or offline)', isDark, bdr)
        else
          ...activityItems.asMap().entries.map((e) =>
              _itemRow(e.value, e.key.isEven ? cellBg : altBg, isDark, bdr)),
        if (grade?.quizRaw != null)
          _subtotalRow('Quiz + Activity', grade!.quizRaw!, grade.quizMax ?? 0,
              _amber, isDark, bdr,
              weight: '${config.quizPct.toStringAsFixed(0)}%'),

        // ═══ ATTENDANCE SECTION ═══
        _sectionHeader('ATTENDANCE', Icons.how_to_reg_rounded, _green,
            '${config.attendancePct.toStringAsFixed(0)}%', isDark, bdr),
        _attendanceRows(isDark, liveAttendance, grade, bdr, cellBg, altBg),

        // ═══ COMPUTED GRADE ═══
        _gradeRow(grade?.computedGrade, isDark, bdr),
      ]),
    );
  }

  // ── Section header row ──

  Widget _sectionHeader(String label, IconData icon, Color color,
      String? weight, bool isDark, Color bdr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        border: Border(bottom: BorderSide(color: bdr)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.8)),
        const Spacer(),
        if (weight != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Weight: $weight',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
      ]),
    );
  }

  // ── Item row (spreadsheet cell) ──

  Widget _itemRow(
      StudentGradeItem item, Color bg, bool isDark, Color bdr) {
    final pct = item.maxScore > 0
        ? (item.score / item.maxScore) * 100
        : 0.0;
    final pctColor =
        pct >= 75 ? _green : (pct >= 50 ? _amber : _red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: bdr)),
      ),
      child: Row(children: [
        // Source icon
        _sourceBadge(item.source),
        const SizedBox(width: 10),
        // Label
        Expanded(
            flex: 4,
            child: Text(item.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
                overflow: TextOverflow.ellipsis)),
        // Score cell
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              '${item.score.toStringAsFixed(0)} / ${item.maxScore.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        // Percentage cell
        SizedBox(
          width: 56,
          child: Text('${pct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: pctColor)),
        ),
      ]),
    );
  }

  // ── Empty row ──

  Widget _emptyRow(String text, bool isDark, Color bdr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: bdr)),
      ),
      child: Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic)),
      ),
    );
  }

  // ── Subtotal row ──

  Widget _subtotalRow(String label, double raw, double max, Color color,
      bool isDark, Color bdr, {String? weight}) {
    final pct = max > 0 ? (raw / max) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.04),
        border: Border(bottom: BorderSide(color: bdr, width: 1.5)),
      ),
      child: Row(children: [
        Icon(Icons.functions_rounded, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
            if (weight != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(weight,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ]),
        ),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${raw.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text('${pct.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
      ]),
    );
  }

  // ── Attendance rows ──

  Widget _attendanceRows(
    bool isDark,
    ({int present, int late, int absent, int excused, int total})? live,
    StudentGrade? grade,
    Color bdr,
    Color cellBg,
    Color altBg,
  ) {
    final hasGraded = grade?.attendanceRaw != null &&
        grade?.attendanceMax != null &&
        (grade?.attendanceMax ?? 0) > 0;

    return Column(children: [
      // Live stats row
      if (live != null && live.total > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cellBg,
            border: Border(bottom: BorderSide(color: bdr)),
          ),
          child: Row(children: [
            Icon(Icons.qr_code_rounded,
                size: 13, color: _green.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Row(children: [
                Text('QR Scans  ',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
                _miniStatBadge('P', live.present, _green),
                const SizedBox(width: 4),
                _miniStatBadge('L', live.late, _amber),
                const SizedBox(width: 4),
                _miniStatBadge('A', live.absent, _red),
                const SizedBox(width: 4),
                _miniStatBadge('E', live.excused, _purple),
              ]),
            ),
            SizedBox(
              width: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: _green)),
                  ),
                ],
              ),
            ),
          ]),
        ),

      // Graded score row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: isDark ? 0.06 : 0.04),
          border: Border(bottom: BorderSide(color: bdr, width: 1.5)),
        ),
        child: Row(children: [
          Icon(Icons.grading_rounded, size: 14, color: _green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasGraded ? 'Graded Score' : 'Awaiting instructor grading',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasGraded ? _green : Colors.grey[500]),
            ),
          ),
          if (hasGraded) ...[
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${grade!.attendanceRaw!.toStringAsFixed(1)} / ${grade.attendanceMax!.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${((grade!.attendanceRaw! / grade.attendanceMax!) * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _green),
              ),
            ),
          ] else
            Icon(Icons.hourglass_empty_rounded,
                size: 14, color: Colors.grey[500]),
        ]),
      ),
    ]);
  }

  // ── Computed grade footer ──

  Widget _gradeRow(double? grade, bool isDark, Color bdr) {
    final color = grade == null
        ? Colors.grey[500]!
        : grade >= 75
            ? _green
            : _red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grade != null
              ? [
                  color.withValues(alpha: isDark ? 0.15 : 0.1),
                  color.withValues(alpha: isDark ? 0.05 : 0.03)
                ]
              : [
                  Colors.grey.withValues(alpha: 0.06),
                  Colors.grey.withValues(alpha: 0.02)
                ],
        ),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TERM GRADE',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                  letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(
            grade != null
                ? grade.toStringAsFixed(2)
                : 'Not yet computed',
            style: TextStyle(
                fontSize: grade != null ? 26 : 14,
                fontWeight: FontWeight.w900,
                color: color),
          ),
        ]),
        const Spacer(),
        if (grade != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text(GradeRemarks.equivalent(grade),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(GradeRemarks.remarks(grade),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Final summary spreadsheet ─────────────────────────────────────

  Widget _buildFinalSpreadsheet(
    bool isDark,
    StudentProvider provider,
    String enrollmentId,
    GradingConfig config,
    List<String> terms,
  ) {
    final grades = provider.gradesForEnrollment(enrollmentId);
    final finalGrade =
        provider.computeFinalGrade(enrollmentId, config);
    final bdr = isDark ? _border : _borderLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
      child: Column(children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? _bg : Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: bdr)),
          ),
          child: Row(children: [
            Expanded(
                flex: 3,
                child: Text('Term',
                    style: _headerStyle())),
            Expanded(
                flex: 2,
                child: Text('Exam',
                    textAlign: TextAlign.center,
                    style: _headerStyle(color: _purple))),
            Expanded(
                flex: 2,
                child: Text('Quiz/Act',
                    textAlign: TextAlign.center,
                    style: _headerStyle(color: _amber))),
            Expanded(
                flex: 2,
                child: Text('Attend',
                    textAlign: TextAlign.center,
                    style: _headerStyle(color: _green))),
            Expanded(
                flex: 2,
                child: Text('Grade',
                    textAlign: TextAlign.center,
                    style: _headerStyle(color: _accent))),
            Expanded(
                flex: 2,
                child: Text('Weight',
                    textAlign: TextAlign.center,
                    style: _headerStyle())),
            Expanded(
                flex: 2,
                child: Text('Contrib.',
                    textAlign: TextAlign.right,
                    style: _headerStyle())),
          ]),
        ),

        // Term rows
        ...terms.asMap().entries.map((entry) {
          final i = entry.key;
          final term = entry.value;
          final g =
              grades.where((g) => g.term == term).firstOrNull;
          final weight = config.termWeights[term] ?? 0;
          final termGrade = g?.computedGrade;
          final contribution =
              termGrade != null ? termGrade * weight : null;
          final gradeColor = termGrade == null
              ? Colors.grey[600]!
              : termGrade >= 75
                  ? _green
                  : _red;
          final bg = i.isEven
              ? (isDark ? _surface : Colors.white)
              : (isDark
                  ? const Color(0xFF1A2435)
                  : const Color(0xFFF1F5F9));

          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border(bottom: BorderSide(color: bdr)),
            ),
            child: Row(children: [
              Expanded(
                  flex: 3,
                  child: Text(GradingConfig.termLabel(term),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : Colors.black87))),
              Expanded(
                  flex: 2,
                  child: _cellScore(g?.examRaw, g?.examMax, isDark)),
              Expanded(
                  flex: 2,
                  child: _cellScore(g?.quizRaw, g?.quizMax, isDark)),
              Expanded(
                  flex: 2,
                  child: _cellScore(
                      g?.attendanceRaw, g?.attendanceMax, isDark)),
              Expanded(
                  flex: 2,
                  child: Center(
                    child: termGrade == null
                        ? Text('—',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12))
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  gradeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: gradeColor
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                                termGrade.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: gradeColor)),
                          ),
                  )),
              Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                        '×${(weight * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500])),
                  )),
              Expanded(
                  flex: 2,
                  child: Text(
                    contribution != null
                        ? contribution.toStringAsFixed(2)
                        : '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey[300]
                            : Colors.grey[700]),
                  )),
            ]),
          );
        }),

        // Final grade row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: finalGrade != null && finalGrade >= 75
                  ? [
                      _green.withValues(alpha: 0.12),
                      _green.withValues(alpha: 0.04)
                    ]
                  : finalGrade != null
                      ? [
                          _red.withValues(alpha: 0.12),
                          _red.withValues(alpha: 0.04)
                        ]
                      : [
                          Colors.grey.withValues(alpha: 0.06),
                          Colors.grey.withValues(alpha: 0.02)
                        ],
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('WEIGHTED FINAL GRADE',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                  finalGrade != null
                      ? finalGrade.toStringAsFixed(2)
                      : 'Incomplete',
                  style: TextStyle(
                      fontSize: finalGrade != null ? 28 : 16,
                      fontWeight: FontWeight.w900,
                      color: finalGrade != null && finalGrade >= 75
                          ? _green
                          : finalGrade != null
                              ? _red
                              : Colors.grey[500]),
                ),
              ]),
            ),
            if (finalGrade != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (finalGrade >= 75 ? _green : _red)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(GradeRemarks.equivalent(finalGrade),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: finalGrade >= 75
                              ? _green
                              : _red)),
                  Text(GradeRemarks.remarks(finalGrade),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: finalGrade >= 75
                              ? _green
                              : _red)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  // ── Helpers ──

  Widget _cellScore(double? raw, double? max, bool isDark) {
    if (raw == null || max == null) {
      return Center(
          child: Text('— / —',
              style: TextStyle(color: Colors.grey[600], fontSize: 11)));
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${raw.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
        if (max > 0)
          Text('${((raw / max) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 9,
                  color: (raw / max) >= 0.75
                      ? _green
                      : (raw / max) >= 0.5
                          ? _amber
                          : _red)),
      ]),
    );
  }

  TextStyle _headerStyle({Color? color}) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: color ?? Colors.grey[500],
      letterSpacing: 0.3,
    );
  }

  Widget _sourceBadge(String source) {
    IconData icon;
    Color color;

    switch (source) {
      case 'assessment_qr':
        icon = Icons.qr_code_rounded;
        color = _accent;
        break;
      case 'auto':
        icon = Icons.auto_awesome_rounded;
        color = _green;
        break;
      default:
        icon = Icons.edit_rounded;
        color = _amber;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 11, color: color),
    );
  }

  Widget _miniStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label:$count',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  Widget _buildNoConfig(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.settings_outlined,
              color: _amber, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Grading not configured',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 6),
        Text('Your instructor hasn\'t set up the grading weights yet.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    );
  }
}