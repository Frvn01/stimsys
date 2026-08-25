import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/subject_model.dart';
import '../../models/grading_config_model.dart';
import '../../models/student_grade_model.dart';
import '../../models/student_grade_item_model.dart';

class DesktopStudentGradesScreen extends StatefulWidget {
  const DesktopStudentGradesScreen({super.key});
  @override
  State<DesktopStudentGradesScreen> createState() =>
      _DesktopStudentGradesScreenState();
}

class _DesktopStudentGradesScreenState extends State<DesktopStudentGradesScreen>
    with TickerProviderStateMixin {
  // ── Design tokens ─────────────────────────────────────────────────
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);

  Subject? _selectedSubject;
  TabController? _tabCtrl;
  bool _loading = false;

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadGrades(AdminProvider provider, Subject subject) async {
    setState(() {
      _loading = true;
      _selectedSubject = subject;
      _tabCtrl?.dispose();
      _tabCtrl = null;
    });
    try {
      await provider.loadSubjectGrades(subject.id!);
      _rebuildTabs(provider);
    } catch (e) {
      debugPrint('Error in _loadGrades: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final subjects = provider.subjects;
        final config = _selectedSubject != null
            ? provider.configFor(_selectedSubject!.id!)
            : null;
        final terms =
            config?.terms ?? ['prelim', 'midterm', 'semi_finals', 'finals'];

        return Container(
          color: _bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Grades',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Encode and compute grades per term',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Refresh
                    if (_selectedSubject != null)
                      _iconBtn(
                        Icons.refresh_rounded,
                        () => _loadGrades(provider, _selectedSubject!),
                      ),
                  ],
                ),
              ),

              // ── Subject selector ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Row(
                  children: [
                    Text(
                      'Subject:',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
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
                          value: _selectedSubject != null && subjects.contains(_selectedSubject)
                              ? _selectedSubject
                              : null,
                          hint: Text(
                            'Select a subject',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          dropdownColor: _surface,
                          iconEnabledColor: Colors.grey[500],
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          items: subjects
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '${s.subjectCode} — ${s.subjectTitle}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
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
                  ],
                ),
              ),

              // ── No subject selected ────────────────────────────────────────
              if (_selectedSubject == null) ...[
                Expanded(child: _emptyState()),
              ] else if (_loading) ...[
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ] else if (config == null) ...[
                Expanded(child: _noConfigState()),
              ] else if (_tabCtrl == null) ...[
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
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
                      controller: _tabCtrl!,
                      isScrollable: false,
                      indicatorColor: _accent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.4),
                        ),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        ...terms.map(
                          (t) => Tab(text: GradingConfig.termLabel(t)),
                        ),
                        const Tab(text: 'Final Summary'),
                      ],
                    ),
                  ),
                ),

                // ── Tab views ──────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl!,
                    children: [
                      ...terms.map(
                        (term) => _selectedSubject == null
                            ? const SizedBox()
                            : _TermGradeSheet(
                                provider: provider,
                                subject: _selectedSubject!,
                                config: config,
                                term: term,
                              ),
                      ),
                      if (_selectedSubject != null)
                        _FinalSummarySheet(
                          provider: provider,
                          subject: _selectedSubject!,
                          config: config,
                          terms: terms,
                        )
                      else
                        const SizedBox(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
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
      style: GoogleFonts.inter(
        color: _green,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.grade_outlined, color: Colors.grey[700], size: 52),
        const SizedBox(height: 14),
        Text(
          'Select a subject to start encoding grades',
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Use the dropdown above to choose a subject',
          style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
        ),
      ],
    ),
  );

  Widget _noConfigState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.settings_outlined, color: _amber, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          'Grading not configured yet',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Go to Subjects → click the ⊞ Grading button on this subject',
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: Colors.grey[500], size: 18),
      ),
    ),
  );
}

// Per-Term Grade Sheet — Excel-Style Spreadsheet
// ══════════════════════════════════════════════════════════════════════════════
class _TermGradeSheet extends StatefulWidget {
  final AdminProvider provider;
  final Subject subject;
  final GradingConfig config;
  final String term;

  const _TermGradeSheet({
    required this.provider,
    required this.subject,
    required this.config,
    required this.term,
  });

  @override
  State<_TermGradeSheet> createState() => _TermGradeSheetState();
}

class _TermGradeSheetState extends State<_TermGradeSheet> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _purple = Color(0xFF818CF8);

  bool _itemsLoaded = false;
  bool _loadingItems = false;

  late final ScrollController _headerHorizontalCtrl;
  late final ScrollController _bodyHorizontalCtrl;
  late final ScrollController _verticalScrollCtrl;

  @override
  void initState() {
    super.initState();
    _headerHorizontalCtrl = ScrollController();
    _bodyHorizontalCtrl = ScrollController();
    _verticalScrollCtrl = ScrollController();

    _bodyHorizontalCtrl.addListener(() {
      if (_headerHorizontalCtrl.hasClients &&
          _headerHorizontalCtrl.offset != _bodyHorizontalCtrl.offset) {
        _headerHorizontalCtrl.jumpTo(_bodyHorizontalCtrl.offset);
      }
    });

    _loadItems();
  }

  @override
  void dispose() {
    _headerHorizontalCtrl.dispose();
    _bodyHorizontalCtrl.dispose();
    _verticalScrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TermGradeSheet old) {
    super.didUpdateWidget(old);
    if (old.term != widget.term || old.subject.id != widget.subject.id) {
      _itemsLoaded = false;
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (_itemsLoaded || _loadingItems) return;
    _loadingItems = true;
    await widget.provider.loadAllGradeItemsForTerm(widget.term);
    if (mounted) {
      setState(() {
        _itemsLoaded = true;
        _loadingItems = false;
      });
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'exam':
        return _purple;
      case 'quiz':
        return _accent;
      case 'activity':
        return _amber;
      default:
        return Colors.grey;
    }
  }

  String _categoryShort(String cat) {
    switch (cat) {
      case 'exam':
        return 'EXM';
      case 'quiz':
        return 'QZ';
      case 'activity':
        return 'ACT';
      default:
        return cat.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final roster = provider.gradeRoster;

    if (roster.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: Colors.grey[700],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No enrolled students',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_loadingItems) {
      return const Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
      );
    }

    final columns = provider.uniqueItemColumnsForTerm(widget.term);

    // Fixed columns width
    const numW = 36.0;
    const nameW = 180.0;
    const usnW = 130.0;
    const fixedW = numW + nameW + usnW;

    // Scrollable columns width
    const itemColW = 90.0;
    const subtotalW = 90.0;
    const attendW = 90.0;
    const gradeW = 70.0;
    const actionsW = 60.0;

    // Count category subtotals needed
    final hasCatItems = <String>{};
    for (final c in columns) {
      hasCatItems.add(c.category);
    }
    final subtotalCount = hasCatItems.length;

    final scrollableW =
        (columns.length * itemColW) +
        (subtotalCount * subtotalW) +
        attendW +
        gradeW +
        actionsW +
        20;

    return Column(
      children: [
        // ── Toolbar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
          child: Row(
            children: [
              Icon(Icons.table_chart_rounded, color: _accent, size: 16),
              const SizedBox(width: 6),
              Text(
                '${columns.length} items',
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              // Category legend
              ...hasCatItems.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _categoryColor(cat),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cat.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: _categoryColor(cat),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Add item button
              _toolbarBtn(
                Icons.add_rounded,
                'Add Item',
                _accent,
                () => _showAddItemDialog(provider, roster),
              ),
              const SizedBox(width: 8),
              _toolbarBtn(
                Icons.auto_awesome_rounded,
                'Auto Attendance',
                _green,
                () => _autoComputeAll(provider, roster),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Spreadsheet ──
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  // ── Pinned Top Header Row ──
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _bg,
                      border: Border(bottom: BorderSide(color: _border)),
                    ),
                    child: Row(
                      children: [
                        // Pinned Left Columns Header (#, Student Name, USN)
                        SizedBox(
                          width: fixedW,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: _border, width: 2),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: numW,
                                  child: Center(
                                    child: Text('#', style: _headerStyle()),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      'Student Name',
                                      style: _headerStyle(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: usnW,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text('USN', style: _headerStyle()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Horizontally Scrollable Column Headers
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _headerHorizontalCtrl,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: scrollableW,
                              child: Row(
                                children: [
                                  ..._buildColumnHeaders(
                                    provider,
                                    columns,
                                    hasCatItems,
                                    itemColW,
                                    subtotalW,
                                  ),
                                  // Attendance
                                  _colHeader(
                                    'Attend\n(score/max)',
                                    attendW,
                                    _green,
                                  ),
                                  // Grade
                                  _colHeader('Grade', gradeW, _accent),
                                  // Actions
                                  SizedBox(
                                    width: actionsW,
                                    child: Center(
                                      child: Icon(
                                        Icons.more_horiz_rounded,
                                        color: Colors.grey[700],
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Unified Vertical Scroll Body (Names & Grades Locked Together!) ──
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _verticalScrollCtrl,
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed Columns (#, Student Name, USN)
                          SizedBox(
                            width: fixedW,
                            child: Column(
                              children: [
                                for (int i = 0; i < roster.length; i++)
                                  _buildFixedNameRow(roster[i], i, numW, usnW),
                              ],
                            ),
                          ),

                          // Horizontally Scrollable Grade Matrix
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _bodyHorizontalCtrl,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                width: scrollableW,
                                child: Column(
                                  children: [
                                    for (int i = 0; i < roster.length; i++)
                                      _buildDataRow(
                                        roster[i],
                                        i,
                                        provider,
                                        columns,
                                        hasCatItems,
                                        itemColW,
                                        subtotalW,
                                        attendW,
                                        gradeW,
                                        actionsW,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedNameRow(
    Map<String, dynamic> enrollment,
    int i,
    double numW,
    double usnW,
  ) {
    final student =
        enrollment['students'] as Map<String, dynamic>? ?? {};
    final name =
        '${student['last_name'] ?? ''}, ${student['first_name'] ?? ''}';
    final usn = student['usn'] ?? '—';

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: i.isEven ? _surface : const Color(0xFF1A2435),
        border: Border(
          bottom: BorderSide(color: _border),
          right: BorderSide(color: _border, width: 2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: numW,
            child: Center(
              child: Text(
                '${i + 1}',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: usnW,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                usn,
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    Map<String, dynamic> enrollment,
    int i,
    AdminProvider provider,
    List<({String category, String label})> columns,
    Set<String> hasCatItems,
    double itemColW,
    double subtotalW,
    double attendW,
    double gradeW,
    double actionsW,
  ) {
    final enrollmentId = enrollment['id'] as String;
    final grade = provider.gradeFor(enrollmentId, widget.term);
    final items = grade?.id != null
        ? provider.gradeItemsFor(grade!.id!)
        : <StudentGradeItem>[];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: i.isEven ? _surface : const Color(0xFF1A2435),
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          ..._buildDataCells(
            columns,
            hasCatItems,
            items,
            grade,
            enrollment,
            provider,
            itemColW,
            subtotalW,
          ),
          // Attendance cell (interactive click to edit or sync)
          Tooltip(
            message: 'Click to edit or sync attendance',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showStudentGradeEditorDialog(
                  provider,
                  enrollment,
                  grade,
                ),
                child: _dataCell(
                  grade?.attendanceRaw,
                  grade?.attendanceMax,
                  attendW,
                  _green,
                ),
              ),
            ),
          ),
          // Grade cell
          _gradeCell(
            grade?.computedGrade,
            gradeW,
          ),
          // Actions
          SizedBox(
            width: actionsW,
            child: Center(
              child: _miniBtn(
                Icons.tune_rounded,
                _accent,
                () {
                  _showStudentGradeEditorDialog(
                    provider,
                    enrollment,
                    grade,
                  );
                },
                'Edit All Scores',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Column header builders ──

  List<Widget> _buildColumnHeaders(
    AdminProvider provider,
    List<({String category, String label})> columns,
    Set<String> categories,
    double itemW,
    double subtotalW,
  ) {
    final widgets = <Widget>[];
    String? lastCat;

    for (final col in columns) {
      // If category changed, insert subtotal for previous
      if (lastCat != null && lastCat != col.category) {
        widgets.add(
          _colHeader(
            '${_categoryShort(lastCat)}\nTotal',
            subtotalW,
            _categoryColor(lastCat),
            isBold: true,
          ),
        );
      }
      lastCat = col.category;

      final color = _categoryColor(col.category);
      widgets.add(
        Tooltip(
          message: 'Click column header to manage or delete "${col.label}"',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showColumnDeleteDialog(
                provider,
                col.category,
                col.label,
              ),
              child: Container(
                width: itemW,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _border.withValues(alpha: 0.5)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _categoryShort(col.category),
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      col.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Final subtotal for last category
    if (lastCat != null) {
      widgets.add(
        _colHeader(
          '${_categoryShort(lastCat)}\nTotal',
          subtotalW,
          _categoryColor(lastCat),
          isBold: true,
        ),
      );
    }

    return widgets;
  }

  Widget _colHeader(
    String label,
    double width,
    Color color, {
    bool isBold = false,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isBold ? color.withValues(alpha: 0.06) : null,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showColumnDeleteDialog(
    AdminProvider provider,
    String category,
    String label,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete "$label"?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will delete the column "$label" (${category.toUpperCase()}) and remove all recorded scores for this item across all students in ${GradingConfig.termLabel(widget.term)}.',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteGradeItemColumnForTerm(
                  term: widget.term,
                  category: category,
                  label: label,
                );
                await _loadItemsRefresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Column "$label" deleted for all students.'),
                      backgroundColor: _green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting column: $e'),
                      backgroundColor: _red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete for All', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Data cell builders ──

  List<Widget> _buildDataCells(
    List<({String category, String label})> columns,
    Set<String> categories,
    List<StudentGradeItem> items,
    StudentGrade? grade,
    Map<String, dynamic> enrollment,
    AdminProvider provider,
    double itemW,
    double subtotalW,
  ) {
    final widgets = <Widget>[];
    String? lastCat;

    // Build a lookup: category::label → item
    final lookup = <String, StudentGradeItem>{};
    for (final item in items) {
      lookup['${item.category}::${item.label}'] = item;
    }

    // Per-category subtotals computed directly from this student's items
    // (avoids the quiz+activity merged total in grade.quizRaw)
    double itemSumRaw(String cat) => items
        .where((i) => i.category == cat)
        .fold(0.0, (s, i) => s + i.score);
    double itemSumMax(String cat) => items
        .where((i) => i.category == cat)
        .fold(0.0, (s, i) => s + i.maxScore);

    for (final col in columns) {
      if (lastCat != null && lastCat != col.category) {
        // Insert subtotal column for previous category
        // exam uses the persisted grade total; quiz/activity use per-category sums
        final double? raw = lastCat == 'exam'
            ? grade?.examRaw
            : itemSumRaw(lastCat);
        final double? max = lastCat == 'exam'
            ? grade?.examMax
            : itemSumMax(lastCat);
        widgets.add(
          _dataCell(
            raw == 0 && max == 0 ? null : raw,
            max == 0 ? null : max,
            subtotalW,
            _categoryColor(lastCat),
            isSubtotal: true,
          ),
        );
      }
      lastCat = col.category;

      final item = lookup['${col.category}::${col.label}'];

      Widget cellBody;
      if (item != null) {
        final pct = item.maxScore > 0
            ? (item.score / item.maxScore) * 100
            : 0.0;
        final pctColor = pct >= 75 ? _green : (pct >= 50 ? _amber : _red);

        cellBody = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${item.score == item.score.roundToDouble() ? item.score.toInt() : item.score} / ${item.maxScore == item.maxScore.roundToDouble() ? item.maxScore.toInt() : item.maxScore}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                color: pctColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      } else {
        cellBody = Center(
          child: Text(
            '—',
            style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
          ),
        );
      }

      widgets.add(
        Tooltip(
          message: 'Click to edit ${col.label}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showQuickEditItemScore(
                provider,
                enrollment,
                grade,
                col.category,
                col.label,
                item,
              ),
              child: Container(
                width: itemW,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _border.withValues(alpha: 0.5)),
                  ),
                ),
                child: cellBody,
              ),
            ),
          ),
        ),
      );
    }

    // Final subtotal for last category
    if (lastCat != null) {
      final double? raw = lastCat == 'exam'
          ? grade?.examRaw
          : itemSumRaw(lastCat);
      final double? max = lastCat == 'exam'
          ? grade?.examMax
          : itemSumMax(lastCat);
      widgets.add(
        _dataCell(
          raw,
          max,
          subtotalW,
          _categoryColor(lastCat),
          isSubtotal: true,
        ),
      );
    }

    return widgets;
  }

  Widget _dataCell(
    double? raw,
    double? max,
    double width,
    Color color, {
    bool isSubtotal = false,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isSubtotal ? color.withValues(alpha: 0.04) : null,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: (raw == null || max == null)
          ? Center(
              child: Text(
                '— / —',
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 11),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${raw.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: isSubtotal ? 12 : 11,
                    fontWeight: isSubtotal ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (max > 0)
                  Text(
                    '${((raw / max) * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _gradeCell(double? grade, double width) {
    final color = grade == null
        ? Colors.grey[700]!
        : grade >= 75
        ? _green
        : _red;

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Center(
        child: grade == null
            ? Text(
                '—',
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  grade.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  // ── Helpers ──

  TextStyle _headerStyle() => GoogleFonts.inter(
    color: Colors.grey[500],
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  Widget _miniBtn(
    IconData icon,
    Color color,
    VoidCallback onTap, [
    String? tip,
  ]) {
    return Tooltip(
      message: tip ?? (icon == Icons.list_alt_rounded ? 'Grade Items' : 'Manual Edit'),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 13),
          ),
        ),
      ),
    );
  }

  Widget _toolbarBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Auto-compute attendance for all students ──

  Future<void> _autoComputeAll(
    AdminProvider provider,
    List<Map<String, dynamic>> roster,
  ) async {
    int count = 0;
    for (final enrollment in roster) {
      final enrollmentId = enrollment['id'] as String;
      final grade = provider.gradeFor(enrollmentId, widget.term);
      if (grade?.id == null) continue;
      try {
        await provider.autoComputeAttendance(
          enrollmentId,
          grade!.id!,
          widget.config.attendancePct,
        );
        count++;
      } catch (_) {}
    }
    if (mounted) {
      await _loadItemsRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance computed for $count student${count != 1 ? 's' : ''}',
          ),
          backgroundColor: _green,
        ),
      );
    }
  }

  Future<void> _loadItemsRefresh() async {
    _itemsLoaded = false;
    await _loadItems();
  }

  // ── Add item dialog (add to all students) ──

  void _showAddItemDialog(
    AdminProvider provider,
    List<Map<String, dynamic>> roster,
  ) {
    final labelCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    String category = 'activity';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Add Grade Item — ${GradingConfig.termLabel(widget.term)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This adds a new column for all students. Enter scores individually after.',
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                // Category selector
                Row(
                  children: [
                    Text(
                      'Category:',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...['quiz', 'activity', 'exam'].map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(c.toUpperCase()),
                          selected: category == c,
                          onSelected: (s) => setDlgState(() => category = c),
                          selectedColor: _categoryColor(c),
                          labelStyle: GoogleFonts.inter(
                            color: category == c
                                ? Colors.white
                                : Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: _bg,
                          side: BorderSide(
                            color: _categoryColor(c).withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: labelCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Label (e.g. Quiz 1, Activity 3)',
                    labelStyle: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _accent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: maxScoreCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Max Score',
                    labelStyle: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final label = labelCtrl.text.trim();
                final maxScore = double.tryParse(maxScoreCtrl.text) ?? 0;
                if (label.isEmpty || maxScore <= 0) return;
                Navigator.pop(ctx);
                await _addItemToAllStudents(
                  provider,
                  roster,
                  category,
                  label,
                  maxScore,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Column',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItemToAllStudents(
    AdminProvider provider,
    List<Map<String, dynamic>> roster,
    String category,
    String label,
    double maxScore,
  ) async {
    for (final enrollment in roster) {
      final enrollmentId = enrollment['id'] as String;
      var grade = provider.gradeFor(enrollmentId, widget.term);

      // Auto-create grade record if needed
      if (grade == null || grade.id == null) {
        final newGrade = StudentGrade(
          enrollmentId: enrollmentId,
          term: widget.term,
        );
        await provider.saveStudentGrade(newGrade);
        grade = provider.gradeFor(enrollmentId, widget.term);
        if (grade?.id == null) continue;
      }

      final item = StudentGradeItem(
        gradeId: grade!.id!,
        category: category,
        label: label,
        score: 0,
        maxScore: maxScore,
        source: 'manual',
      );
      await provider.saveGradeItem(item);
    }
    await _loadItemsRefresh();
  }

  // ── Quick item score edit popover ──

  void _showQuickEditItemScore(
    AdminProvider provider,
    Map<String, dynamic> enrollment,
    StudentGrade? grade,
    String category,
    String label,
    StudentGradeItem? existingItem,
  ) {
    final student = enrollment['students'] as Map<String, dynamic>? ?? {};
    final studentName =
        '${student['last_name'] ?? ''}, ${student['first_name'] ?? ''}';
    final scoreCtrl = TextEditingController(
      text: existingItem != null
          ? (existingItem.score == existingItem.score.roundToDouble()
              ? existingItem.score.toInt().toString()
              : existingItem.score.toString())
          : '0',
    );
    final maxCtrl = TextEditingController(
      text: existingItem != null
          ? (existingItem.maxScore == existingItem.maxScore.roundToDouble()
              ? existingItem.maxScore.toInt().toString()
              : existingItem.maxScore.toString())
          : '100',
    );

    final color = _categoryColor(category);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final score = double.tryParse(scoreCtrl.text) ?? 0;
          final max = double.tryParse(maxCtrl.text) ?? 100;
          final pct = max > 0 ? (score / max) * 100 : 0.0;
          final pctColor = pct >= 75 ? _green : (pct >= 50 ? _amber : _red);

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 390,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & category badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF64748B), size: 18),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentName,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Inputs Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCORE',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: scoreCtrl,
                                autofocus: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setDlgState(() {}),
                                onSubmitted: (_) async {
                                  await _saveQuickItem(
                                    ctx,
                                    provider,
                                    enrollment,
                                    grade,
                                    category,
                                    label,
                                    scoreCtrl.text,
                                    maxCtrl.text,
                                    existingItem,
                                  );
                                },
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: _border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: _border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: color, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Text(
                              '/',
                              style: GoogleFonts.inter(
                                color: Colors.grey[600],
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MAX SCORE',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: maxCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setDlgState(() {}),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: _border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: _border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: color, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Percentage Preview Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pctColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: pctColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            color: pctColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pct >= 75 ? 'Passing Score' : 'Below Passing',
                        style: GoogleFonts.inter(
                          color: pctColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Press Enter ↵ to save',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await _saveQuickItem(
                            ctx,
                            provider,
                            enrollment,
                            grade,
                            category,
                            label,
                            scoreCtrl.text,
                            maxCtrl.text,
                            existingItem,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Score',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveQuickItem(
    BuildContext ctx,
    AdminProvider provider,
    Map<String, dynamic> enrollment,
    StudentGrade? grade,
    String category,
    String label,
    String scoreText,
    String maxText,
    StudentGradeItem? existingItem,
  ) async {
    final enrollmentId = enrollment['id'] as String;
    var currentGrade = provider.gradeFor(enrollmentId, widget.term);

    // Create grade record if it doesn't exist
    if (currentGrade == null || currentGrade.id == null) {
      final newGrade = StudentGrade(
        enrollmentId: enrollmentId,
        term: widget.term,
      );
      await provider.saveStudentGrade(newGrade);
      currentGrade = provider.gradeFor(enrollmentId, widget.term);
      if (currentGrade?.id == null) return;
    }

    final score = double.tryParse(scoreText) ?? 0;
    final max = double.tryParse(maxText) ?? 100;

    final item = StudentGradeItem(
      id: existingItem?.id,
      gradeId: currentGrade!.id!,
      category: category,
      label: label,
      score: score,
      maxScore: max,
      source: existingItem?.source ?? 'manual',
      assessmentId: existingItem?.assessmentId,
    );

    await provider.saveGradeItem(item);
    await _loadItemsRefresh();

    if (ctx.mounted) {
      Navigator.pop(ctx);
    }
  }

  // ── Unified Student Grade Breakdown & Editor Modal ──

  void _showStudentGradeEditorDialog(
    AdminProvider provider,
    Map<String, dynamic> enrollment,
    StudentGrade? grade,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StudentGradeEditorDialog(
        provider: provider,
        enrollment: enrollment,
        initialGrade: grade,
        config: widget.config,
        term: widget.term,
        onSaved: _loadItemsRefresh,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Redesigned Student Grade Editor Dialog (Item-by-Item Editing)
// ══════════════════════════════════════════════════════════════════════════════

class _EditableItem {
  String? id;
  String category; // 'quiz', 'activity', 'exam'
  final TextEditingController labelCtrl;
  final TextEditingController scoreCtrl;
  final TextEditingController maxScoreCtrl;
  String source;
  bool isNew;
  bool isDeleted;

  _EditableItem({
    this.id,
    required this.category,
    required String label,
    required double score,
    required double maxScore,
    this.source = 'manual',
    this.isNew = false,
  })  : isDeleted = false,
        labelCtrl = TextEditingController(text: label),
        scoreCtrl = TextEditingController(
            text: score == score.roundToDouble()
                ? score.toInt().toString()
                : score.toString()),
        maxScoreCtrl = TextEditingController(
            text: maxScore == maxScore.roundToDouble()
                ? maxScore.toInt().toString()
                : maxScore.toString());

  String get label => labelCtrl.text.trim();
  double get score => double.tryParse(scoreCtrl.text) ?? 0;
  double get maxScore => double.tryParse(maxScoreCtrl.text) ?? 0;
  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
}

class _StudentGradeEditorDialog extends StatefulWidget {
  final AdminProvider provider;
  final Map<String, dynamic> enrollment;
  final StudentGrade? initialGrade;
  final GradingConfig config;
  final String term;
  final VoidCallback onSaved;

  const _StudentGradeEditorDialog({
    required this.provider,
    required this.enrollment,
    required this.initialGrade,
    required this.config,
    required this.term,
    required this.onSaved,
  });

  @override
  State<_StudentGradeEditorDialog> createState() =>
      _StudentGradeEditorDialogState();
}

class _StudentGradeEditorDialogState extends State<_StudentGradeEditorDialog> {
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _cardBg = Color(0xFF141D2E);
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _purple = Color(0xFF818CF8);

  bool _loading = true;
  bool _saving = false;
  bool _syncingAttendance = false;
  final List<_EditableItem> _items = [];

  final _attendRawCtrl = TextEditingController();
  final _attendMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final grade = widget.initialGrade;
    _attendRawCtrl.text = grade?.attendanceRaw != null
        ? (grade!.attendanceRaw == grade.attendanceRaw!.roundToDouble()
            ? grade.attendanceRaw!.toInt().toString()
            : grade.attendanceRaw!.toString())
        : '0';
    _attendMaxCtrl.text = grade?.attendanceMax != null
        ? (grade!.attendanceMax == grade.attendanceMax!.roundToDouble()
            ? grade.attendanceMax!.toInt().toString()
            : grade.attendanceMax!.toString())
        : '100';

    _attendRawCtrl.addListener(() => setState(() {}));
    _attendMaxCtrl.addListener(() => setState(() {}));

    if (grade?.id != null) {
      await widget.provider.loadGradeItems(grade!.id!);
      final existing = widget.provider.gradeItemsFor(grade.id!);
      for (final e in existing) {
        final item = _EditableItem(
          id: e.id,
          category: e.category,
          label: e.label,
          score: e.score,
          maxScore: e.maxScore,
          source: e.source,
        );
        item.labelCtrl.addListener(() => setState(() {}));
        item.scoreCtrl.addListener(() => setState(() {}));
        item.maxScoreCtrl.addListener(() => setState(() {}));
        _items.add(item);
      }
    }

    // Pre-populate standard subject columns ONLY if this student has NO grade items at all yet.
    // Once a student has been saved, we trust the DB exclusively — never auto-add columns they
    // may have had removed. This prevents deleted items from reappearing.
    if (_items.isEmpty) {
      final termColumns = widget.provider.uniqueItemColumnsForTerm(widget.term);
      for (final col in termColumns) {
        final newItem = _EditableItem(
          category: col.category,
          label: col.label,
          score: 0,
          maxScore: col.category == 'exam'
              ? 100
              : (col.category == 'quiz' ? 20 : 100),
          isNew: true,
        );
        newItem.labelCtrl.addListener(() => setState(() {}));
        newItem.scoreCtrl.addListener(() => setState(() {}));
        newItem.maxScoreCtrl.addListener(() => setState(() {}));
        _items.add(newItem);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _addNewItem(String category, [String? defaultLabel]) {
    final count =
        _items.where((i) => !i.isDeleted && i.category == category).length + 1;
    final catName = category == 'quiz'
        ? 'Quiz'
        : (category == 'activity' ? 'Activity' : 'Exam');
    final label = defaultLabel ?? '$catName $count';
    final newItem = _EditableItem(
      category: category,
      label: label,
      score: 0,
      maxScore: category == 'exam' ? 100 : (category == 'quiz' ? 20 : 100),
      isNew: true,
    );
    newItem.labelCtrl.addListener(() => setState(() {}));
    newItem.scoreCtrl.addListener(() => setState(() {}));
    newItem.maxScoreCtrl.addListener(() => setState(() {}));
    setState(() => _items.add(newItem));
  }

  double get totalQuizScore => _items
      .where((i) =>
          !i.isDeleted && (i.category == 'quiz' || i.category == 'activity'))
      .fold(0.0, (s, i) => s + i.score);

  double get totalQuizMax => _items
      .where((i) =>
          !i.isDeleted && (i.category == 'quiz' || i.category == 'activity'))
      .fold(0.0, (s, i) => s + i.maxScore);

  double get totalExamScore => _items
      .where((i) => !i.isDeleted && i.category == 'exam')
      .fold(0.0, (s, i) => s + i.score);

  double get totalExamMax => _items
      .where((i) => !i.isDeleted && i.category == 'exam')
      .fold(0.0, (s, i) => s + i.maxScore);

  double get attendRaw => double.tryParse(_attendRawCtrl.text) ?? 0;
  double get attendMax => double.tryParse(_attendMaxCtrl.text) ?? 100;

  double? get computedGrade {
    final er = totalExamScore;
    final em = totalExamMax > 0 ? totalExamMax : 100.0;
    final qr = totalQuizScore;
    final qm = totalQuizMax > 0 ? totalQuizMax : 100.0;
    final ar = attendRaw;
    final am = attendMax > 0 ? attendMax : 100.0;

    return widget.config.computeTermGrade(
      examRaw: er,
      examMax: em,
      quizRaw: qr,
      quizMax: qm,
      attendRaw: ar,
      attendMax: am,
    );
  }

  Future<void> _autoSyncAttendance() async {
    setState(() => _syncingAttendance = true);
    try {
      final enrollmentId = widget.enrollment['id'] as String;
      var grade = widget.provider.gradeFor(enrollmentId, widget.term);
      if (grade?.id == null) {
        final newGrade = StudentGrade(
          enrollmentId: enrollmentId,
          term: widget.term,
        );
        await widget.provider.saveStudentGrade(newGrade);
        grade = widget.provider.gradeFor(enrollmentId, widget.term);
      }
      if (grade?.id != null) {
        await widget.provider.autoComputeAttendance(
          enrollmentId,
          grade!.id!,
          widget.config.attendancePct,
        );
        final reloadedGrade =
            widget.provider.gradeFor(enrollmentId, widget.term);
        if (reloadedGrade != null) {
          _attendRawCtrl.text =
              (reloadedGrade.attendanceRaw ?? 0).toStringAsFixed(0);
          _attendMaxCtrl.text =
              (reloadedGrade.attendanceMax ?? 100).toStringAsFixed(0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Attendance auto-sync error: $e'),
              backgroundColor: _red),
        );
      }
    } finally {
      if (mounted) setState(() => _syncingAttendance = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final enrollmentId = widget.enrollment['id'] as String;
      var grade = widget.provider.gradeFor(enrollmentId, widget.term);

      // Ensure grade record exists
      if (grade == null || grade.id == null) {
        final newGrade = StudentGrade(
          enrollmentId: enrollmentId,
          term: widget.term,
          attendanceRaw: attendRaw,
          attendanceMax: attendMax,
        );
        await widget.provider.saveStudentGrade(newGrade);
        grade = widget.provider.gradeFor(enrollmentId, widget.term);
        if (grade == null || grade.id == null) {
          throw Exception('Failed to create grade record');
        }
      } else {
        // Update attendance on grade record
        final updatedGrade = StudentGrade(
          id: grade.id,
          enrollmentId: enrollmentId,
          term: widget.term,
          attendanceRaw: attendRaw,
          attendanceMax: attendMax,
          examRaw: totalExamScore,
          examMax: totalExamMax > 0 ? totalExamMax : 100,
          quizRaw: totalQuizScore,
          quizMax: totalQuizMax > 0 ? totalQuizMax : 100,
          computedGrade: computedGrade,
        );
        await widget.provider.saveStudentGrade(updatedGrade);
      }

      final gradeId = grade.id!;

      // Collect which term-level columns are being fully deleted
      // (item was pre-populated from uniqueItemColumnsForTerm, has no DB id yet, and is now deleted)
      // OR item has a DB id and is deleted — in both cases we remove from DB
      // Also: if this is a column that exists across the whole class, we delete it for ALL students.
      final columnsToDeleteFromClass = <({String category, String label})>{};

      // Save / update / delete items
      for (final item in _items) {
        if (item.isDeleted) {
          if (item.id != null) {
            // Has a real DB row — delete just this student's record
            await widget.provider.removeGradeItem(item.id!, gradeId);
          }
          // Track the column label to remove from the class-wide column list
          // (so it stops appearing as a column for this student when re-opened)
          columnsToDeleteFromClass.add(
              (category: item.category, label: item.labelCtrl.text.trim()));
        } else {
          final labelText = item.labelCtrl.text.trim().isEmpty
              ? '${item.category.toUpperCase()} Item'
              : item.labelCtrl.text.trim();
          // Only save items that have a non-zero score or are explicitly new (user added)
          // Skip auto-populated empty items that were never touched (score=0, max=default, isNew=true)
          final wasAutoPopulated = item.isNew && item.score == 0;
          if (!wasAutoPopulated || item.maxScore != (item.category == 'quiz' ? 20 : 100)) {
            final gradeItem = StudentGradeItem(
              id: item.isNew ? null : item.id,
              gradeId: gradeId,
              category: item.category,
              label: labelText,
              score: item.score,
              maxScore: item.maxScore > 0 ? item.maxScore : 100,
              source: item.source,
            );
            await widget.provider.saveGradeItem(gradeItem);
          }
        }
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                    'Scores updated for ${widget.enrollment['students']?['last_name'] ?? 'Student'}'),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving scores: $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student =
        widget.enrollment['students'] as Map<String, dynamic>? ?? {};
    final lastName = student['last_name'] ?? '';
    final firstName = student['first_name'] ?? '';
    final usn = student['usn'] ?? '—';
    final section = student['section'] ?? '';
    final course = student['course'] ?? '';

    final grade = computedGrade;
    final isPassed = grade != null && grade >= 75;
    final gradeColor = grade == null ? Colors.grey[500]! : (isPassed ? _green : _red);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: _loading
            ? const SizedBox(
                height: 300,
                child: Center(
                  child:
                      CircularProgressIndicator(color: _accent, strokeWidth: 2),
                ),
              )
            : Column(
                children: [
                  // ── Header Banner ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(17)),
                      border: Border(bottom: BorderSide(color: _border)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              (lastName.isNotEmpty ? lastName[0] : 'S')
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$lastName, $firstName',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    usn,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (course.isNotEmpty || section.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$course $section'.trim(),
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[300],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color:
                                              _accent.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      GradingConfig.termLabel(widget.term)
                                          .toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF818CF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Live Projected Grade Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: gradeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: gradeColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PROJECTED GRADE',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                grade == null
                                    ? '—'
                                    : '${grade.toStringAsFixed(2)}%',
                                style: GoogleFonts.inter(
                                  color: gradeColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (grade != null)
                                Text(
                                  GradeRemarks.remarks(grade),
                                  style: GoogleFonts.inter(
                                    color: gradeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF64748B), size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // ── Subtotal Overview Pills ──
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162032),
                      border: Border(bottom: BorderSide(color: _border)),
                    ),
                    child: Row(
                      children: [
                        _metricPill(
                          'Quizzes (${widget.config.quizPct.toInt()}%)',
                          totalQuizScore,
                          totalQuizMax,
                          _accent,
                        ),
                        const SizedBox(width: 10),
                        _metricPill(
                          'Exams (${widget.config.examPct.toInt()}%)',
                          totalExamScore,
                          totalExamMax,
                          _purple,
                        ),
                        const SizedBox(width: 10),
                        _metricPill(
                          'Attendance (${widget.config.attendancePct.toInt()}%)',
                          attendRaw,
                          attendMax,
                          _green,
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Body ──
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                      children: [
                        // Quizzes Section
                        _buildCategorySection(
                          category: 'quiz',
                          title: 'Quizzes',
                          icon: Icons.quiz_outlined,
                          color: _accent,
                        ),
                        const SizedBox(height: 18),

                        // Activities Section
                        _buildCategorySection(
                          category: 'activity',
                          title: 'Activities / Performance Tasks',
                          icon: Icons.assignment_outlined,
                          color: _amber,
                        ),
                        const SizedBox(height: 18),

                        // Exams Section
                        _buildCategorySection(
                          category: 'exam',
                          title: 'Major Exams',
                          icon: Icons.school_outlined,
                          color: _purple,
                        ),
                        const SizedBox(height: 18),

                        // Attendance Section
                        _buildAttendanceSection(),
                      ],
                    ),
                  ),

                  // ── Footer ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(17)),
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Changes will automatically recalculate total percentages',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _saving ? null : _saveAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Save All Changes',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700),
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
    );
  }

  Widget _metricPill(
      String label, double raw, double max, Color color) {
    final pct = max > 0 ? (raw / max) * 100 : 0.0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${raw.toStringAsFixed(0)} / ${max.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCategorySection({
    required String category,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final catItems =
        _items.where((i) => !i.isDeleted && i.category == category).toList();
    final catScore = catItems.fold(0.0, (s, i) => s + i.score);
    final catMax = catItems.fold(0.0, (s, i) => s + i.maxScore);
    final catPct = catMax > 0 ? (catScore / catMax) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${catItems.length} items',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Subtotal: ${catScore.toStringAsFixed(0)} / ${catMax.toStringAsFixed(0)}  (${catPct.toStringAsFixed(1)}%)',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // Item Rows
          if (catItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No ${title.toLowerCase()} added yet.',
                  style: GoogleFonts.inter(
                      color: Colors.grey[600], fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: catItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildItemRow(catItems[i], color),
            ),

          // Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _addNewItem(category),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Add $title item',
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(_EditableItem item, Color color) {
    final pct = item.percentage;
    final pctColor = pct >= 75 ? _green : (pct >= 50 ? _amber : _red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Label input
          Expanded(
            flex: 3,
            child: TextField(
              controller: item.labelCtrl,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Item label (e.g. Quiz 1)',
                hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Score Input
          SizedBox(
            width: 70,
            child: TextField(
              controller: item.scoreCtrl,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Score',
                hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '/',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Max Score Input
          SizedBox(
            width: 70,
            child: TextField(
              controller: item.maxScoreCtrl,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Max',
                hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Percentage Tag
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: pctColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: pctColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: pctColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          Tooltip(
            message: 'Remove item',
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.red[400], size: 16),
              onPressed: () {
                setState(() => item.isDeleted = true);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    final raw = attendRaw;
    final max = attendMax;
    final pct = max > 0 ? (raw / max) * 100 : 0.0;
    final pctColor = pct >= 75 ? _green : (pct >= 50 ? _amber : _red);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: _green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Attendance Score',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _syncingAttendance ? null : _autoSyncAttendance,
                icon: _syncingAttendance
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 13),
                label: Text(
                  _syncingAttendance ? 'Syncing...' : 'Auto-Sync from Tracker',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recorded attendance rating from student scans',
                    style: GoogleFonts.inter(
                        color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _attendRawCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: _green, width: 1.5),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '/',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _attendMaxCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: _green, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: pctColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: pctColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: pctColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);

  bool _hovered = false;
  bool _editing = false;
  bool _saving = false;

  final _examRawCtrl = TextEditingController();
  final _examMaxCtrl = TextEditingController();
  final _quizRawCtrl = TextEditingController();
  final _quizMaxCtrl = TextEditingController();
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
    _examRawCtrl.text = g.examRaw?.toStringAsFixed(0) ?? '';
    _examMaxCtrl.text = g.examMax?.toStringAsFixed(0) ?? '';
    _quizRawCtrl.text = g.quizRaw?.toStringAsFixed(0) ?? '';
    _quizMaxCtrl.text = g.quizMax?.toStringAsFixed(0) ?? '';
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
    if (er != null &&
        em != null &&
        qr != null &&
        qm != null &&
        ar != null &&
        am != null &&
        em > 0 &&
        qm > 0 &&
        am > 0) {
      _preview = widget.config.computeTermGrade(
        examRaw: er,
        examMax: em,
        quizRaw: qr,
        quizMax: qm,
        attendRaw: ar,
        attendMax: am,
      );
    } else {
      _preview = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _examRawCtrl.dispose();
    _examMaxCtrl.dispose();
    _quizRawCtrl.dispose();
    _quizMaxCtrl.dispose();
    _attendRawCtrl.dispose();
    _attendMaxCtrl.dispose();
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
        examRaw: double.tryParse(_examRawCtrl.text),
        examMax: double.tryParse(_examMaxCtrl.text),
        quizRaw: double.tryParse(_quizRawCtrl.text),
        quizMax: double.tryParse(_quizMaxCtrl.text),
        attendanceRaw: double.tryParse(_attendRawCtrl.text),
        attendanceMax: double.tryParse(_attendMaxCtrl.text),
        computedGrade: _preview,
      );
      await widget.provider.saveStudentGrade(grade);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grade;
    final name =
        '${widget.student['last_name'] ?? ''}, ${widget.student['first_name'] ?? ''}';
    final usn = widget.student['usn'] ?? '—';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered && !_editing ? const Color(0xFF273548) : _surface,
        child: _editing ? _editRow(name, usn) : _displayRow(g, name, usn),
      ),
    );
  }

  Widget _displayRow(StudentGrade? g, String name, String usn) {
    final grade = g?.computedGrade;
    final gradeColor = grade == null
        ? Colors.grey[600]!
        : grade >= 75
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${widget.index}',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              usn,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: _scoreDisplay(
              g?.examRaw,
              g?.examMax,
              const Color(0xFF818CF8),
            ),
          ),
          Expanded(
            flex: 2,
            child: _scoreDisplay(
              g?.quizRaw,
              g?.quizMax,
              const Color(0xFFF59E0B),
            ),
          ),
          Expanded(
            flex: 2,
            child: _scoreDisplay(
              g?.attendanceRaw,
              g?.attendanceMax,
              const Color(0xFF10B981),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: grade == null
                  ? Text(
                      '—',
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: gradeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        grade.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: gradeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _rowBtn(
                  Icons.list_alt_rounded,
                  _amber,
                  () => _showGradeItemsDialog(),
                  'Grade Items',
                ),
                const SizedBox(width: 4),
                _rowBtn(
                  Icons.edit_rounded,
                  _accent,
                  () => setState(() => _editing = true),
                  'Manual Edit',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editRow(String name, String usn) {
    return Container(
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.04),
        border: Border(left: BorderSide(color: _accent, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student name header
          Row(
            children: [
              Icon(Icons.edit_rounded, color: _accent, size: 13),
              const SizedBox(width: 6),
              Text(
                name,
                style: GoogleFonts.inter(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                usn,
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
              ),
              const Spacer(),
              // Live grade preview
              if (_preview != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (_preview! >= 75 ? _green : _red).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (_preview! >= 75 ? _green : _red).withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Text(
                    'Preview: ${_preview!.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: _preview! >= 75 ? _green : _red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Score inputs
          Row(
            children: [
              _scoreGroup(
                'Exam',
                _examRawCtrl,
                _examMaxCtrl,
                const Color(0xFF818CF8),
              ),
              const SizedBox(width: 12),
              _scoreGroup(
                'Quiz / Activity',
                _quizRawCtrl,
                _quizMaxCtrl,
                const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              _scoreGroup(
                'Attendance',
                _attendRawCtrl,
                _attendMaxCtrl,
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 16),
              // Save / Cancel
              Column(
                children: [
                  ElevatedButton(
                    onPressed: (_preview != null && !_saving) ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      _populateFromGrade(widget.grade);
                      setState(() => _editing = false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Formula hint
          if (_preview != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _buildFormulaHint(),
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 10),
              ),
            ),
        ],
      ),
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

  Widget _scoreGroup(
    String label,
    TextEditingController rawCtrl,
    TextEditingController maxCtrl,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: _miniInput(rawCtrl, 'Score', color)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: _miniInput(maxCtrl, 'Max', color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInput(TextEditingController ctrl, String hint, Color color) =>
      TextFormField(
        controller: ctrl,
        onChanged: (_) => _recalcPreview(),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 11),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
        ),
      );

  Widget _scoreDisplay(double? raw, double? max, Color color) {
    if (raw == null || max == null) {
      return Text(
        '— / —',
        style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
      );
    }
    final pct = (raw / max) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${raw.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: GoogleFonts.inter(color: color, fontSize: 10),
        ),
      ],
    );
  }

  Widget _rowBtn(IconData icon, Color color, VoidCallback onTap, String tip) =>
      Tooltip(
        message: tip,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
          ),
        ),
      );

  void _showGradeItemsDialog() async {
    final grade = widget.grade;
    if (grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please manually save a 0/0 grade first before adding items.',
          ),
          backgroundColor: _amber,
        ),
      );
      return;
    }

    // Load items
    await widget.provider.loadGradeItems(grade.id!);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Consumer<AdminProvider>(
        builder: (_, p, __) {
          final items = p.gradeItemsFor(grade.id!);
          return AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade Items — ${widget.student['last_name']}, ${widget.student['first_name']}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.term.toUpperCase()} TERM',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await p.autoComputeAttendance(
                        widget.enrollmentId,
                        grade.id!,
                        widget.config.attendancePct,
                      );
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Attendance computed successfully!'),
                            backgroundColor: _green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: _red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: Text(
                    'Auto-Compute Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: _green),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No assessments or activities found for this term.',
                        style: GoogleFonts.inter(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final isExam = item.category == 'exam';
                        final color = isExam ? _accent : _amber;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Source: ${item.source}',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.score.toStringAsFixed(0)} / ${item.maxScore.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_rounded,
                                  color: Colors.red[400],
                                  size: 16,
                                ),
                                onPressed: () =>
                                    p.removeGradeItem(item.id!, grade.id!),
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
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(color: Colors.grey[400]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
  static const _border = Color(0xFF2D3B52);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

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
      return Center(
        child: Text(
          'No students enrolled',
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(28, 14, 28, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _th('#', width: 36),
              _th('Student', flex: 3),
              _th('USN', flex: 2),
              ...terms.map((t) {
                final w = config.termWeights[t];
                final pct = w != null
                    ? '×${(w * 100).toStringAsFixed(0)}%'
                    : '';
                return _th(
                  '${GradingConfig.termLabel(t)}\n$pct',
                  flex: 2,
                  align: TextAlign.center,
                );
              }),
              _th(
                'Weighted\nFinal',
                flex: 2,
                align: TextAlign.center,
                color: _accent,
              ),
              _th('Equiv', flex: 1, align: TextAlign.center),
              _th('Remarks', flex: 2, align: TextAlign.center),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              child: ListView.separated(
                itemCount: summaries.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: _border),
                itemBuilder: (_, i) {
                  final s = summaries[i];
                  final avg = config.computeFinalGrade(s.termGrades);
                  final passed = GradeRemarks.isPassed(avg);
                  final avgColor = avg == null
                      ? Colors.grey[600]!
                      : passed
                      ? _green
                      : _red;

                  return Container(
                    color: _surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            s.fullName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s.usn,
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ),
                        ...terms.map((t) {
                          final g = s.termGrades[t];
                          return Expanded(
                            flex: 2,
                            child: Center(
                              child: g == null
                                  ? Text(
                                      '—',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    )
                                  : Text(
                                      g.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        color: g >= 75 ? _green : _red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          );
                        }),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: avg == null
                                ? Text(
                                    'Incomplete',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: avgColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: avgColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      avg.toStringAsFixed(2),
                                      style: GoogleFonts.inter(
                                        color: avgColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              GradeRemarks.equivalent(avg),
                              style: GoogleFonts.inter(
                                color: avgColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: avg == null
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : (passed ? _green : _red).withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                avg == null ? '—' : GradeRemarks.remarks(avg),
                                style: GoogleFonts.inter(
                                  color: avg == null
                                      ? Colors.grey[600]
                                      : passed
                                      ? _green
                                      : _red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _th(
    String label, {
    int flex = 1,
    double? width,
    TextAlign align = TextAlign.left,
    Color? color,
  }) {
    final text = Text(
      label,
      textAlign: align,
      style: GoogleFonts.inter(
        color: color ?? Colors.grey[500],
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
    if (width != null) return SizedBox(width: width, child: text);
    return Expanded(flex: flex, child: text);
  }
}
