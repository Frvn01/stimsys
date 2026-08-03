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
                          value: _selectedSubject,
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

  @override
  void initState() {
    super.initState();
    _loadItems();
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
              child: Row(
                children: [
                  // ── Fixed columns (# / Name / USN) ──
                  SizedBox(
                    width: fixedW,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _bg,
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

                        // Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: roster.length,
                            itemBuilder: (_, i) {
                              final enrollment = roster[i];
                              final student =
                                  enrollment['students']
                                      as Map<String, dynamic>? ??
                                  {};
                              final name =
                                  '${student['last_name'] ?? ''}, ${student['first_name'] ?? ''}';
                              final usn = student['usn'] ?? '—';

                              return Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: i.isEven
                                      ? _surface
                                      : const Color(0xFF1A2435),
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
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
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
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
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
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable columns (items + subtotals + attendance + grade) ──
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: scrollableW,
                        child: Column(
                          children: [
                            // Header
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: _bg,
                                border: Border(
                                  bottom: BorderSide(color: _border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ..._buildColumnHeaders(
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

                            // Body
                            Expanded(
                              child: ListView.builder(
                                itemCount: roster.length,
                                itemBuilder: (_, i) {
                                  final enrollment = roster[i];
                                  final enrollmentId =
                                      enrollment['id'] as String;
                                  final grade = provider.gradeFor(
                                    enrollmentId,
                                    widget.term,
                                  );
                                  final items = grade?.id != null
                                      ? provider.gradeItemsFor(grade!.id!)
                                      : <StudentGradeItem>[];

                                  return Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: i.isEven
                                          ? _surface
                                          : const Color(0xFF1A2435),
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
                                          itemColW,
                                          subtotalW,
                                        ),
                                        // Attendance cell
                                        _dataCell(
                                          grade?.attendanceRaw,
                                          grade?.attendanceMax,
                                          attendW,
                                          _green,
                                        ),
                                        // Grade cell
                                        _gradeCell(
                                          grade?.computedGrade,
                                          gradeW,
                                        ),
                                        // Actions
                                        SizedBox(
                                          width: actionsW,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _miniBtn(
                                                Icons.list_alt_rounded,
                                                _amber,
                                                () {
                                                  if (grade != null) {
                                                    _showGradeItemsDialog(
                                                      provider,
                                                      grade,
                                                      enrollment['students'] ??
                                                          {},
                                                    );
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              _miniBtn(
                                                Icons.edit_rounded,
                                                _accent,
                                                () {
                                                  _showEditDialog(
                                                    provider,
                                                    enrollment,
                                                    grade,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
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

  // ── Column header builders ──

  List<Widget> _buildColumnHeaders(
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
            '${_categoryShort(lastCat!)}\nTotal',
            subtotalW,
            _categoryColor(lastCat!),
            isBold: true,
          ),
        );
      }
      lastCat = col.category;

      final color = _categoryColor(col.category);
      widgets.add(
        Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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

  // ── Data cell builders ──

  List<Widget> _buildDataCells(
    List<({String category, String label})> columns,
    Set<String> categories,
    List<StudentGradeItem> items,
    StudentGrade? grade,
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

    for (final col in columns) {
      if (lastCat != null && lastCat != col.category) {
        // Subtotal for previous category
        final raw = lastCat == 'exam' ? grade?.examRaw : grade?.quizRaw;
        final max = lastCat == 'exam' ? grade?.examMax : grade?.quizMax;
        widgets.add(
          _dataCell(
            raw,
            max,
            subtotalW,
            _categoryColor(lastCat!),
            isSubtotal: true,
          ),
        );
      }
      lastCat = col.category;

      final item = lookup['${col.category}::${col.label}'];
      if (item != null) {
        final pct = item.maxScore > 0
            ? (item.score / item.maxScore) * 100
            : 0.0;
        final pctColor = pct >= 75 ? _green : (pct >= 50 ? _amber : _red);

        widgets.add(
          Container(
            width: itemW,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: _border.withValues(alpha: 0.5)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.score.toStringAsFixed(0)} / ${item.maxScore.toStringAsFixed(0)}',
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
            ),
          ),
        );
      } else {
        widgets.add(
          Container(
            width: itemW,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: _border.withValues(alpha: 0.5)),
              ),
            ),
            child: Center(
              child: Text(
                '—',
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          ),
        );
      }
    }

    // Final subtotal
    if (lastCat != null) {
      final raw = lastCat == 'exam' ? grade?.examRaw : grade?.quizRaw;
      final max = lastCat == 'exam' ? grade?.examMax : grade?.quizMax;
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

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return Tooltip(
      message: icon == Icons.list_alt_rounded ? 'Grade Items' : 'Manual Edit',
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

  // ── Existing grade items dialog (view/edit items per student) ──

  void _showGradeItemsDialog(
    AdminProvider provider,
    StudentGrade grade,
    Map<String, dynamic> student,
  ) async {
    await provider.loadGradeItems(grade.id!);
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
                        'Grade Items — ${student['last_name']}, ${student['first_name']}',
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
                        grade.enrollmentId,
                        grade.id!,
                        widget.config.attendancePct,
                      );
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Attendance computed!'),
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
                    'Auto Attendance',
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
                        'No items for this term.',
                        style: GoogleFonts.inter(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final color = _categoryColor(item.category);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bg,
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
                                onPressed: () async {
                                  await p.removeGradeItem(item.id!, grade.id!);
                                  await _loadItemsRefresh();
                                },
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

  // ── Manual edit dialog ──

  void _showEditDialog(
    AdminProvider provider,
    Map<String, dynamic> enrollment,
    StudentGrade? grade,
  ) {
    final enrollmentId = enrollment['id'] as String;
    final student = enrollment['students'] as Map<String, dynamic>? ?? {};
    final name =
        '${student['last_name'] ?? ''}, ${student['first_name'] ?? ''}';

    final examRawCtrl = TextEditingController(
      text: grade?.examRaw?.toStringAsFixed(0) ?? '',
    );
    final examMaxCtrl = TextEditingController(
      text: grade?.examMax?.toStringAsFixed(0) ?? '',
    );
    final quizRawCtrl = TextEditingController(
      text: grade?.quizRaw?.toStringAsFixed(0) ?? '',
    );
    final quizMaxCtrl = TextEditingController(
      text: grade?.quizMax?.toStringAsFixed(0) ?? '',
    );
    final attendRawCtrl = TextEditingController(
      text: grade?.attendanceRaw?.toStringAsFixed(0) ?? '',
    );
    final attendMaxCtrl = TextEditingController(
      text: grade?.attendanceMax?.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Edit Scores — $name',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Row(
            children: [
              _scoreGroup('Exam', examRawCtrl, examMaxCtrl, _purple),
              const SizedBox(width: 12),
              _scoreGroup('Quiz/Activity', quizRawCtrl, quizMaxCtrl, _amber),
              const SizedBox(width: 12),
              _scoreGroup('Attendance', attendRawCtrl, attendMaxCtrl, _green),
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
              final er = double.tryParse(examRawCtrl.text);
              final em = double.tryParse(examMaxCtrl.text);
              final qr = double.tryParse(quizRawCtrl.text);
              final qm = double.tryParse(quizMaxCtrl.text);
              final ar = double.tryParse(attendRawCtrl.text);
              final am = double.tryParse(attendMaxCtrl.text);

              double? computed;
              if (er != null &&
                  em != null &&
                  qr != null &&
                  qm != null &&
                  ar != null &&
                  am != null &&
                  em > 0 &&
                  qm > 0 &&
                  am > 0) {
                computed = widget.config.computeTermGrade(
                  examRaw: er,
                  examMax: em,
                  quizRaw: qr,
                  quizMax: qm,
                  attendRaw: ar,
                  attendMax: am,
                );
              }

              final g = StudentGrade(
                id: grade?.id,
                enrollmentId: enrollmentId,
                term: widget.term,
                examRaw: er,
                examMax: em,
                quizRaw: qr,
                quizMax: qm,
                attendanceRaw: ar,
                attendanceMax: am,
                computedGrade: computed,
              );
              await provider.saveStudentGrade(g);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
              Expanded(
                child: TextFormField(
                  controller: rawCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Score',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: _bg,
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
                ),
              ),
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
              Expanded(
                child: TextFormField(
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Max',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: _bg,
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
                ),
              ),
            ],
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
