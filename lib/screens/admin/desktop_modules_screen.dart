import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/admin_provider.dart';
import '../../models/module_model.dart';

class DesktopModulesScreen extends StatefulWidget {
  const DesktopModulesScreen({super.key});

  @override
  State<DesktopModulesScreen> createState() => _DesktopModulesScreenState();
}

class _DesktopModulesScreenState extends State<DesktopModulesScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ─────────────────────────────────────────────────
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A2235);
  static const _border = Color(0xFF232D3F);
  static const _accent = Color(0xFF6366F1);
  static const _red = Color(0xFFEF4444);

  late TabController _tabCtrl;
  String _searchQuery = '';

  static const _terms = ['all', 'prelim', 'midterm', 'prefinal', 'final'];
  static const _termLabels = ['All', 'Prelim', 'Midterm', 'Pre-Final', 'Final'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _terms.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AdminProvider>();
      p.loadModules();
      if (p.subjects.isEmpty) {
        p.loadSubjects();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<LearningModule> _filter(List<LearningModule> all) {
    var list = all;
    final term = _terms[_tabCtrl.index];
    if (term != 'all') {
      list = list.where((m) => m.term == term).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((m) =>
              m.title.toLowerCase().contains(q) ||
              m.subject.toLowerCase().contains(q) ||
              (m.description ?? '').toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final modules = _filter(provider.modules);
        return Container(
          color: _bg,
          child: Column(children: [
            _buildHeader(provider),
            _buildTabs(),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _accent))
                  : modules.isEmpty
                      ? _buildEmpty()
                      : _buildGrid(modules, provider),
            ),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeader(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_copy_rounded,
                color: _accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learning Modules',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                      '${provider.modules.length} module${provider.modules.length == 1 ? '' : 's'} • Google Drive',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF4B5E78),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
          ),

          // Search
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search modules…',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF4B5E78), size: 18),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _accent)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Add button
          _ActionButton(
            icon: Icons.add_rounded,
            label: 'Add Module',
            color: _accent,
            onTap: () => _showModuleDialog(provider),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            color: const Color(0xFF4B5E78),
            onTap: () => provider.loadModules(),
          ),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: _accent,
        indicatorWeight: 2.5,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF4B5E78),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: _border,
        tabs: _termLabels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.folder_off_rounded,
              color: _accent, size: 40),
        ),
        const SizedBox(height: 16),
        Text('No modules found',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Add your first learning module to get started.',
            style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78), fontSize: 13)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MODULE GRID
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGrid(List<LearningModule> modules, AdminProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 380,
          mainAxisExtent: 200,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
        ),
        itemCount: modules.length,
        itemBuilder: (context, i) =>
            _ModuleCard(module: modules[i], provider: provider, parent: this),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADD / EDIT DIALOG
  // ═══════════════════════════════════════════════════════════════════

  void _showModuleDialog(AdminProvider provider, {LearningModule? existing}) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final urlCtrl = TextEditingController(text: existing?.fileUrl ?? '');
    String selectedTerm = existing?.term ?? 'prelim';
    String? urlError;
    String? titleError;
    String? subjectError;

    final driveRegex = RegExp(
        r'^https:\/\/(drive|docs)\.google\.com\/(file\/d\/|presentation\/d\/|open\?id=)[a-zA-Z0-9_-]+');

    // Get unique subjects from the provider
    final subjectSuggestions = provider.subjects
        .map((s) => '${s.subjectCode} — ${s.subjectTitle}')
        .toSet()
        .toList();

    String? selectedSubject;
    if (isEdit && subjectSuggestions.contains(existing.subject)) {
      selectedSubject = existing.subject;
    } else if (subjectSuggestions.isNotEmpty) {
      selectedSubject = subjectSuggestions.first;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF151D2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                              isEdit
                                  ? Icons.edit_note_rounded
                                  : Icons.add_rounded,
                              color: _accent,
                              size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(isEdit ? 'Edit Module' : 'Add Module',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded,
                              color: Color(0xFF4B5E78), size: 20),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Title
                      _label('Title'),
                      _field(titleCtrl, 'e.g. Introduction to Computing',
                          error: titleError),
                      const SizedBox(height: 16),

                      // Description
                      _label('Description (optional)'),
                      _field(descCtrl, 'Brief description…', maxLines: 2),
                      const SizedBox(height: 16),

                      // Subject — dropdown
                      _label('Subject'),
                      if (subjectSuggestions.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _red),
                          ),
                          child: Text(
                            'No subjects found in the database. Add subjects first!',
                            style: GoogleFonts.inter(color: _red, fontSize: 13),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: subjectError != null ? _red : _border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSubject,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1A2235),
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 13),
                              icon: const Icon(Icons.expand_more_rounded,
                                  color: Color(0xFF4B5E78), size: 18),
                              hint: Text('Select Subject',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF4B5E78), fontSize: 13)),
                              items: subjectSuggestions.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedSubject = v),
                            ),
                          ),
                        ),
                      ],
                      if (subjectError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(subjectError!,
                              style: GoogleFonts.inter(color: _red, fontSize: 11)),
                        ),
                      const SizedBox(height: 16),

                      // Term
                      _label('Term'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTerm,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A2235),
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 13),
                            icon: const Icon(Icons.expand_more_rounded,
                                color: Color(0xFF4B5E78), size: 18),
                            items: const [
                              DropdownMenuItem(
                                  value: 'prelim', child: Text('Prelim')),
                              DropdownMenuItem(
                                  value: 'midterm', child: Text('Midterm')),
                              DropdownMenuItem(
                                  value: 'prefinal',
                                  child: Text('Pre-Final')),
                              DropdownMenuItem(
                                  value: 'final', child: Text('Final')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => selectedTerm = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google Drive URL
                      _label('Google Drive URL'),
                      _field(urlCtrl,
                          'https://drive.google.com/file/d/…',
                          error: urlError),
                      const SizedBox(height: 4),
                      Text(
                        'Only Google Drive file or presentation links are allowed.',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF4B5E78), fontSize: 11),
                      ),

                      const SizedBox(height: 28),

                      // Actions
                      Row(children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Cancel',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF4B5E78),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () async {
                                // Validate
                                bool valid = true;

                                if (titleCtrl.text.trim().isEmpty) {
                                  titleError = 'Title is required';
                                  valid = false;
                                } else {
                                  titleError = null;
                                }

                                if (selectedSubject == null || selectedSubject!.isEmpty) {
                                  subjectError = 'Subject is required';
                                  valid = false;
                                } else {
                                  subjectError = null;
                                }

                                if (!driveRegex
                                    .hasMatch(urlCtrl.text.trim())) {
                                  urlError =
                                      'Invalid Google Drive link';
                                  valid = false;
                                } else {
                                  urlError = null;
                                }

                                if (!valid) {
                                  setDialogState(() {});
                                  return;
                                }

                                final module = LearningModule(
                                  id: existing?.id,
                                  title: titleCtrl.text.trim(),
                                  description:
                                      descCtrl.text.trim().isEmpty
                                          ? null
                                          : descCtrl.text.trim(),
                                  subject: selectedSubject!,
                                  term: selectedTerm,
                                  fileUrl: urlCtrl.text.trim(),
                                );

                                try {
                                  if (isEdit) {
                                    await provider.editModule(module);
                                  } else {
                                    await provider.addModule(module);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: _red,
                                    ));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: Text(isEdit ? 'Update' : 'Create',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                      ]),
                    ]),
              ),
            ),
          );
        });
      },
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.inter(
                color: const Color(0xFF8B9AB2),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, String? error}) {
    return _fieldWidget(ctrl, hint, maxLines: maxLines, error: error);
  }

  Widget _fieldWidget(TextEditingController ctrl, String hint,
      {int maxLines = 1, FocusNode? focusNode, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          focusNode: focusNode,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFF3A4A62), fontSize: 13),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: error != null ? _red : _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: error != null ? _red : _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: error != null ? _red : _accent)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error,
                style: GoogleFonts.inter(color: _red, fontSize: 11)),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// MODULE CARD
// ═══════════════════════════════════════════════════════════════════

class _ModuleCard extends StatefulWidget {
  final LearningModule module;
  final AdminProvider provider;
  final _DesktopModulesScreenState parent;
  const _ModuleCard(
      {required this.module, required this.provider, required this.parent});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hovered = false;

  static const _surface = Color(0xFF1A2235);
  static const _border = Color(0xFF232D3F);
  static const _accent = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);

  Color get _termColor {
    switch (widget.module.term) {
      case 'prelim':
        return _accent;
      case 'midterm':
        return _amber;
      case 'prefinal':
        return const Color(0xFF8B5CF6);
      case 'final':
        return _green;
      default:
        return _accent;
    }
  }

  IconData get _fileIcon {
    final url = widget.module.fileUrl.toLowerCase();
    if (url.contains('presentation')) return Icons.slideshow_rounded;
    return Icons.picture_as_pdf_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF1E2D42) : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _hovered
                  ? _termColor.withValues(alpha: 0.35)
                  : _border),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: _termColor.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row: term badge + actions
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _termColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(m.termLabel,
                  style: GoogleFonts.inter(
                      color: _termColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            _tinyBtn(Icons.edit_rounded, () {
              widget.parent._showModuleDialog(widget.provider, existing: m);
            }),
            const SizedBox(width: 4),
            _tinyBtn(Icons.delete_outline_rounded, () {
              _confirmDelete(m);
            }, color: _red),
          ]),

          const SizedBox(height: 12),

          // File type icon + title
          Row(children: [
            Icon(_fileIcon, color: _termColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(m.title,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),

          const SizedBox(height: 6),

          // Subject
          Text(m.subject,
              style: GoogleFonts.inter(
                  color: const Color(0xFF4B5E78),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),

          if (m.description != null && m.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(m.description!,
                style: GoogleFonts.inter(
                    color: const Color(0xFF3A4A62), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],

          const Spacer(),

          // Bottom: date + open
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 12, color: const Color(0xFF3A4A62)),
            const SizedBox(width: 4),
            Text(
                m.createdAt != null
                    ? DateFormat('MMM d, yyyy').format(m.createdAt!)
                    : '—',
                style: GoogleFonts.inter(
                    color: const Color(0xFF3A4A62), fontSize: 11)),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _openUrl(m.fileUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.open_in_new_rounded,
                      color: _green, size: 13),
                  const SizedBox(width: 4),
                  Text('Open',
                      style: GoogleFonts.inter(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _tinyBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF4B5E78)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color ?? const Color(0xFF4B5E78)),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(LearningModule m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151D2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Module?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
            'Are you sure you want to delete "${m.title}"? This action cannot be undone.',
            style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78),
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.provider.deleteModule(m.id!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTION BUTTON (header)
// ═══════════════════════════════════════════════════════════════════

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.color
                    .withValues(alpha: _hovered ? 0.3 : 0.15)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: widget.color, size: 16),
            const SizedBox(width: 6),
            Text(widget.label,
                style: GoogleFonts.inter(
                    color: widget.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
