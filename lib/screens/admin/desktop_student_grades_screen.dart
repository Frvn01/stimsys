import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/grading_config_model.dart';
import '../../models/student_grade_model.dart';

class DesktopStudentGradesScreen extends StatefulWidget {
  const DesktopStudentGradesScreen({super.key});
  @override
  State<DesktopStudentGradesScreen> createState() =>
      _DesktopStudentGradesScreenState();
}

class _DesktopStudentGradesScreenState
    extends State<DesktopStudentGradesScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ─────────────────────────────────────────────────
  static const _bg      = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _accent  = Color(0xFF6366F1);
  static const _green   = Color(0xFF10B981);
  static const _amber   = Color(0xFFF59E0B);

  Subject? _selectedSubject;
  TabController? _tabCtrl;
  bool _loading = false;

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadGrades(AdminProvider provider, Subject subject) async {
    setState(() { _loading = true; _selectedSubject = subject; });
    await provider.loadSubjectGrades(subject.id!);
    _rebuildTabs(provider);
    setState(() => _loading = false);
  }

  void _rebuildTabs(AdminProvider provider) {
    _tabCtrl?.dispose();
    final config = provider.configFor(_selectedSubject?.id ?? '');
    final termCount = config != null
        ? (config.termType == 'trimester' ? 3 : 4)
        : 4;
    _tabCtrl = TabController(length: termCount + 1, vsync: this);
    _tabCtrl!.addListener(() => setState(() {}));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, provider, _) {
      final subjects = provider.subjects;
      final config = _selectedSubject != null
          ? provider.configFor(_selectedSubject!.id!)
          : null;
      final terms = config?.terms ??
          ['prelim', 'midterm', 'semi_finals', 'finals'];

      return Container(
        color: _bg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Student Grades',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Encode and compute grades per term',
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)),
              ])),
              // Refresh
              if (_selectedSubject != null)
                _iconBtn(Icons.refresh_rounded,
                    () => _loadGrades(provider, _selectedSubject!)),
            ]),
          ),

          // ── Subject selector ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: Row(children: [
              Text('Subject:', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 10),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Subject>(
                    value: _selectedSubject,
                    hint: Text('Select a subject',
                        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                    dropdownColor: _surface,
                    iconEnabledColor: Colors.grey[500],
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    items: subjects.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.subjectCode} — ${s.subjectTitle}',
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (s) {
                      if (s != null) _loadGrades(provider, s);
                    },
                  ),
                ),
              ),
              // Config badge
              if (config != null) ...[
                const SizedBox(width: 12),
                _configBadge(config),
              ],
            ]),
          ),

          // ── No subject selected ────────────────────────────────────────
          if (_selectedSubject == null) ...[
            Expanded(child: _emptyState()),
          ] else if (_loading) ...[
            const Expanded(child: Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2))),
          ] else if (config == null) ...[
            Expanded(child: _noConfigState()),
          ] else ...[
            // ── Tab bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: false,
                  indicatorColor: _accent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withValues(alpha: 0.4)),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    ...terms.map((t) => Tab(text: GradingConfig.termLabel(t))),
                    const Tab(text: 'Final Summary'),
                  ],
                ),
              ),
            ),

            // ── Tab views ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  ...terms.map((term) => _TermGradeSheet(
                        provider: provider,
                        subject: _selectedSubject!,
                        config: config,
                        term: term,
                      )),
                  _FinalSummarySheet(
                      provider: provider,
                      subject: _selectedSubject!,
                      config: config,
                      terms: terms),
                ],
              ),
            ),
          ],
        ]),
      );
    });
  }

  Widget _configBadge(GradingConfig cfg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _green.withValues(alpha: 0.2)),
        ),
        child: Text(
          'Exam ${cfg.examPct.toStringAsFixed(0)}%  ·  Quiz ${cfg.quizPct.toStringAsFixed(0)}%  ·  Attend ${cfg.attendancePct.toStringAsFixed(0)}%  ·  ${cfg.termType == 'trimester' ? 'Trimester' : 'Semester'}',
          style: GoogleFonts.inter(color: _green, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.grade_outlined, color: Colors.grey[700], size: 52),
        const SizedBox(height: 14),
        Text('Select a subject to start encoding grades',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text('Use the dropdown above to choose a subject',
            style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12)),
      ]));

  Widget _noConfigState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.settings_outlined, color: _amber, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Grading not configured yet',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Go to Subjects → click the ⊞ Grading button on this subject',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
      ]));

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border)),
            child: Icon(icon, color: Colors.grey[500], size: 18),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Per-Term Grade Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _TermGradeSheet extends StatelessWidget {
  final AdminProvider provider;
  final Subject subject;
  final GradingConfig config;
  final String term;

  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _amber   = Color(0xFFF59E0B);
  static const _green   = Color(0xFF10B981);

  const _TermGradeSheet({
    required this.provider,
    required this.subject,
    required this.config,
    required this.term,
  });

  @override
  Widget build(BuildContext context) {
    final roster = provider.gradeRoster;

    if (roster.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded, color: Colors.grey[700], size: 48),
        const SizedBox(height: 12),
        Text('No enrolled students',
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
      ]));
    }

    return Column(children: [
      // Table header
      Container(
        margin: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          _th('#',           flex: 0, width: 36),
          _th('Student Name', flex: 3),
          _th('USN',         flex: 2),
          _th('Exam\n(score / max)',     flex: 2, color: const Color(0xFF818CF8)),
          _th('Quiz/Act\n(score / max)', flex: 2, color: _amber),
          _th('Attend\n(score / max)',   flex: 2, color: _green),
          _th('Grade',       flex: 1, align: TextAlign.center),
          _th('',            flex: 0, width: 48),
        ]),
      ),

      // Table body
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            child: ListView.separated(
              itemCount: roster.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: _border),
              itemBuilder: (ctx, i) {
                final enrollment = roster[i];
                final enrollmentId = enrollment['id'] as String;
                final student = enrollment['students'] as Map<String, dynamic>? ?? {};
                final grade = provider.gradeFor(enrollmentId, term);
                return _GradeRow(
                  index: i + 1,
                  enrollmentId: enrollmentId,
                  student: student,
                  grade: grade,
                  config: config,
                  term: term,
                  provider: provider,
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }

  static Widget _th(String label,
      {int flex = 1, double? width, TextAlign align = TextAlign.left, Color? color}) {
    final text = Text(label,
        textAlign: align,
        style: GoogleFonts.inter(
            color: color ?? Colors.grey[500],
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3));
    if (width != null) return SizedBox(width: width, child: text);
    return Expanded(flex: flex, child: text);
  }
}

// ── Individual grade row ──────────────────────────────────────────────────────
class _GradeRow extends StatefulWidget {
  final int index;
  final String enrollmentId;
  final Map<String, dynamic> student;
  final StudentGrade? grade;
  final GradingConfig config;
  final String term;
  final AdminProvider provider;

  const _GradeRow({
    required this.index,
    required this.enrollmentId,
    required this.student,
    required this.grade,
    required this.config,
    required this.term,
    required this.provider,
  });

  @override
  State<_GradeRow> createState() => _GradeRowState();
}

class _GradeRowState extends State<_GradeRow> {
  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _accent  = Color(0xFF6366F1);
  static const _green   = Color(0xFF10B981);
  static const _red     = Color(0xFFEF4444);

  bool _hovered = false;
  bool _editing = false;
  bool _saving  = false;

  final _examRawCtrl   = TextEditingController();
  final _examMaxCtrl   = TextEditingController();
  final _quizRawCtrl   = TextEditingController();
  final _quizMaxCtrl   = TextEditingController();
  final _attendRawCtrl = TextEditingController();
  final _attendMaxCtrl = TextEditingController();

  double? _preview;

  @override
  void initState() {
    super.initState();
    _populateFromGrade(widget.grade);
  }

  @override
  void didUpdateWidget(_GradeRow old) {
    super.didUpdateWidget(old);
    if (!_editing) _populateFromGrade(widget.grade);
  }

  void _populateFromGrade(StudentGrade? g) {
    if (g == null) return;
    _examRawCtrl.text   = g.examRaw?.toStringAsFixed(0) ?? '';
    _examMaxCtrl.text   = g.examMax?.toStringAsFixed(0) ?? '';
    _quizRawCtrl.text   = g.quizRaw?.toStringAsFixed(0) ?? '';
    _quizMaxCtrl.text   = g.quizMax?.toStringAsFixed(0) ?? '';
    _attendRawCtrl.text = g.attendanceRaw?.toStringAsFixed(0) ?? '';
    _attendMaxCtrl.text = g.attendanceMax?.toStringAsFixed(0) ?? '';
    _recalcPreview();
  }

  void _recalcPreview() {
    final er = double.tryParse(_examRawCtrl.text);
    final em = double.tryParse(_examMaxCtrl.text);
    final qr = double.tryParse(_quizRawCtrl.text);
    final qm = double.tryParse(_quizMaxCtrl.text);
    final ar = double.tryParse(_attendRawCtrl.text);
    final am = double.tryParse(_attendMaxCtrl.text);
    if (er != null && em != null && qr != null && qm != null &&
        ar != null && am != null && em > 0 && qm > 0 && am > 0) {
      _preview = widget.config.computeTermGrade(
          examRaw: er, examMax: em,
          quizRaw: qr, quizMax: qm,
          attendRaw: ar, attendMax: am);
    } else {
      _preview = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _examRawCtrl.dispose(); _examMaxCtrl.dispose();
    _quizRawCtrl.dispose(); _quizMaxCtrl.dispose();
    _attendRawCtrl.dispose(); _attendMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_preview == null) return;
    setState(() => _saving = true);
    try {
      final grade = StudentGrade(
        id: widget.grade?.id,
        enrollmentId: widget.enrollmentId,
        term: widget.term,
        examRaw:       double.tryParse(_examRawCtrl.text),
        examMax:       double.tryParse(_examMaxCtrl.text),
        quizRaw:       double.tryParse(_quizRawCtrl.text),
        quizMax:       double.tryParse(_quizMaxCtrl.text),
        attendanceRaw: double.tryParse(_attendRawCtrl.text),
        attendanceMax: double.tryParse(_attendMaxCtrl.text),
        computedGrade: _preview,
      );
      await widget.provider.saveStudentGrade(grade);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: _red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grade;
    final name = '${widget.student['last_name'] ?? ''}, ${widget.student['first_name'] ?? ''}';
    final usn  = widget.student['usn'] ?? '—';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered && !_editing ? const Color(0xFF273548) : _surface,
        child: _editing
            ? _editRow(name, usn)
            : _displayRow(g, name, usn),
      ),
    );
  }

  Widget _displayRow(StudentGrade? g, String name, String usn) {
    final grade = g?.computedGrade;
    final gradeColor = grade == null
        ? Colors.grey[600]!
        : grade >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 36,
            child: Text('${widget.index}',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11))),
        Expanded(flex: 3,
            child: Text(name,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2,
            child: Text(usn,
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11))),
        Expanded(flex: 2, child: _scoreDisplay(g?.examRaw, g?.examMax, const Color(0xFF818CF8))),
        Expanded(flex: 2, child: _scoreDisplay(g?.quizRaw, g?.quizMax, const Color(0xFFF59E0B))),
        Expanded(flex: 2, child: _scoreDisplay(g?.attendanceRaw, g?.attendanceMax, const Color(0xFF10B981))),
        Expanded(flex: 1, child: Center(
          child: grade == null
              ? Text('—', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(grade.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          color: gradeColor, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
        )),
        SizedBox(width: 48, child: Center(
          child: _rowBtn(Icons.edit_rounded, _accent, () => setState(() => _editing = true), 'Edit'),
        )),
      ]),
    );
  }

  Widget _editRow(String name, String usn) {
    return Container(
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.04),
        border: Border(
          left: BorderSide(color: _accent, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Student name header
        Row(children: [
          Icon(Icons.edit_rounded, color: _accent, size: 13),
          const SizedBox(width: 6),
          Text(name,
              style: GoogleFonts.inter(color: _accent, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(usn, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11)),
          const Spacer(),
          // Live grade preview
          if (_preview != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (_preview! >= 75 ? _green : _red).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (_preview! >= 75 ? _green : _red).withValues(alpha: 0.3)),
            ),
            child: Text('Preview: ${_preview!.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                    color: _preview! >= 75 ? _green : _red,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),

        // Score inputs
        Row(children: [
          _scoreGroup('Exam', _examRawCtrl, _examMaxCtrl, const Color(0xFF818CF8)),
          const SizedBox(width: 12),
          _scoreGroup('Quiz / Activity', _quizRawCtrl, _quizMaxCtrl, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _scoreGroup('Attendance', _attendRawCtrl, _attendMaxCtrl, const Color(0xFF10B981)),
          const SizedBox(width: 16),
          // Save / Cancel
          Column(children: [
            ElevatedButton(
              onPressed: (_preview != null && !_saving) ? _save : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey[800]),
              child: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                _populateFromGrade(widget.grade);
                setState(() => _editing = false);
              },
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
            ),
          ]),
        ]),

        // Formula hint
        if (_preview != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _buildFormulaHint(),
              style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 10),
            ),
          ),
      ]),
    );
  }

  String _buildFormulaHint() {
    final er = double.tryParse(_examRawCtrl.text);
    final em = double.tryParse(_examMaxCtrl.text);
    final qr = double.tryParse(_quizRawCtrl.text);
    final qm = double.tryParse(_quizMaxCtrl.text);
    final ar = double.tryParse(_attendRawCtrl.text);
    final am = double.tryParse(_attendMaxCtrl.text);
    if (er == null || em == null || em <= 0) return '';

    final ec = (er / em) * 100 * (widget.config.examPct / 100);
    final qc = (qr != null && qm != null && qm > 0)
        ? (qr / qm) * 100 * (widget.config.quizPct / 100)
        : 0.0;
    final ac = (ar != null && am != null && am > 0)
        ? (ar / am) * 100 * (widget.config.attendancePct / 100)
        : 0.0;

    return 'Exam: ${ec.toStringAsFixed(2)} + Quiz: ${qc.toStringAsFixed(2)} + Attend: ${ac.toStringAsFixed(2)} = ${_preview!.toStringAsFixed(2)}';
  }

  Widget _scoreGroup(String label, TextEditingController rawCtrl,
      TextEditingController maxCtrl, Color color) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(child: _miniInput(rawCtrl, 'Score', color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('/', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          Expanded(child: _miniInput(maxCtrl, 'Max', color)),
        ]),
      ]),
    );
  }

  Widget _miniInput(TextEditingController ctrl, String hint, Color color) =>
      TextFormField(
        controller: ctrl,
        onChanged: (_) => _recalcPreview(),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 11),
          filled: true, fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: color, width: 1.5)),
        ),
      );

  Widget _scoreDisplay(double? raw, double? max, Color color) {
    if (raw == null || max == null) {
      return Text('— / —', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12));
    }
    final pct = (raw / max) * 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${raw.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      Text('${pct.toStringAsFixed(1)}%',
          style: GoogleFonts.inter(color: color, fontSize: 10)),
    ]);
  }

  Widget _rowBtn(IconData icon, Color color, VoidCallback onTap, String tip) =>
      Tooltip(message: tip,
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(6),
          child: InkWell(borderRadius: BorderRadius.circular(6), onTap: onTap,
            child: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Icon(icon, color: color, size: 14)))));
}

// ══════════════════════════════════════════════════════════════════════════════
// Final Grade Summary Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _FinalSummarySheet extends StatelessWidget {
  final AdminProvider provider;
  final Subject subject;
  final GradingConfig config;
  final List<String> terms;

  static const _surface = Color(0xFF1E293B);
  static const _border  = Color(0xFF2D3B52);
  static const _accent  = Color(0xFF6366F1);
  static const _green   = Color(0xFF10B981);
  static const _red     = Color(0xFFEF4444);

  const _FinalSummarySheet({
    required this.provider,
    required this.subject,
    required this.config,
    required this.terms,
  });

  @override
  Widget build(BuildContext context) {
    final summaries = provider.buildFinalSummaries(terms);

    if (summaries.isEmpty) {
      return Center(child: Text('No students enrolled',
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)));
    }

    return Column(children: [
      // Header
      Container(
        margin: const EdgeInsets.fromLTRB(28, 14, 28, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          _th('#',        width: 36),
          _th('Student', flex: 3),
          _th('USN',     flex: 2),
          ...terms.map((t) {
            final w = config.termWeights[t];
            final pct = w != null ? '×${(w * 100).toStringAsFixed(0)}%' : '';
            return _th('${GradingConfig.termLabel(t)}\n$pct', flex: 2, align: TextAlign.center);
          }),
          _th('Weighted\nFinal', flex: 2, align: TextAlign.center, color: _accent),
          _th('Equiv',     flex: 1, align: TextAlign.center),
          _th('Remarks',   flex: 2, align: TextAlign.center),
        ]),
      ),

      // Rows
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            child: ListView.separated(
              itemCount: summaries.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: _border),
              itemBuilder: (_, i) {
                final s = summaries[i];
                final avg = config.computeFinalGrade(s.termGrades);
                final passed = GradeRemarks.isPassed(avg);
                final avgColor = avg == null
                    ? Colors.grey[600]!
                    : passed ? _green : _red;

                return Container(
                  color: _surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    SizedBox(width: 36,
                        child: Text('${i + 1}',
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11))),
                    Expanded(flex: 3,
                        child: Text(s.fullName,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2,
                        child: Text(s.usn,
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11))),
                    ...terms.map((t) {
                      final g = s.termGrades[t];
                      return Expanded(flex: 2, child: Center(
                        child: g == null
                            ? Text('—', style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12))
                            : Text(g.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                    color: g >= 75 ? _green : _red,
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                      ));
                    }),
                    Expanded(flex: 2, child: Center(
                      child: avg == null
                          ? Text('Incomplete',
                              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11))
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: avgColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: avgColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(avg.toStringAsFixed(2),
                                  style: GoogleFonts.inter(
                                      color: avgColor, fontSize: 13, fontWeight: FontWeight.w800)),
                            ),
                    )),
                    Expanded(flex: 1, child: Center(
                      child: Text(GradeRemarks.equivalent(avg),
                          style: GoogleFonts.inter(
                              color: avgColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    )),
                    Expanded(flex: 2, child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: avg == null
                              ? Colors.grey.withValues(alpha: 0.1)
                              : (passed ? _green : _red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          avg == null ? '—' : GradeRemarks.remarks(avg),
                          style: GoogleFonts.inter(
                              color: avg == null
                                  ? Colors.grey[600]
                                  : passed ? _green : _red,
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }

  static Widget _th(String label,
      {int flex = 1, double? width, TextAlign align = TextAlign.left, Color? color}) {
    final text = Text(label,
        textAlign: align,
        style: GoogleFonts.inter(
            color: color ?? Colors.grey[500],
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3));
    if (width != null) return SizedBox(width: width, child: text);
    return Expanded(flex: flex, child: text);
  }
}
