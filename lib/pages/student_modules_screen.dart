import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'module_viewer_screen.dart';
import '../../providers/student_provider.dart';
import '../../models/module_model.dart';

/// Student-facing screen displaying all learning modules for a specific subject.
/// Materials are organised by term (Prelim → Final) and open via Google Drive.
class StudentModulesScreen extends StatefulWidget {
  final String subjectCode;
  final String subjectTitle;
  /// The subject identifier stored in the modules table (e.g. "IT101 — Fundamentals")
  final String subjectIdentifier;
  final String? initialTerm;

  const StudentModulesScreen({
    super.key,
    required this.subjectCode,
    required this.subjectTitle,
    required this.subjectIdentifier,
    this.initialTerm,
  });

  @override
  State<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends State<StudentModulesScreen> {
  bool _loading = true;
  String _selectedTerm = 'all';

  static const _termOrder = ['prelim', 'midterm', 'prefinal', 'final'];
  static const _termLabels = {
    'prelim': 'Prelim',
    'midterm': 'Midterm',
    'prefinal': 'Pre-Final',
    'final': 'Final',
  };

  static const _termColors = {
    'all': Color(0xFF6366F1),
    'prelim': Color(0xFF6366F1),
    'midterm': Color(0xFFF59E0B),
    'prefinal': Color(0xFF8B5CF6),
    'final': Color(0xFF10B981),
  };

  @override
  void initState() {
    super.initState();
    _selectedTerm = widget.initialTerm ?? 'all';
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<StudentProvider>();
    await provider.loadModules();
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildTermFilterChips(bool isDark) {
    final terms = ['all', 'prelim', 'midterm', 'prefinal', 'final'];
    final labels = ['All', 'Prelim', 'Midterm', 'Pre-Final', 'Final'];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: terms.length,
        itemBuilder: (context, index) {
          final term = terms[index];
          final label = labels[index];
          final isSelected = _selectedTerm == term;
          final color = _termColors[term] ?? const Color(0xFF6366F1);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTerm = term);
                }
              },
              selectedColor: color.withValues(alpha: 0.15),
              checkmarkColor: color,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? color : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectTitle,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text('Learning Modules',
                style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTermFilterChips(isDark),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : Consumer<StudentProvider>(
                    builder: (context, provider, _) {
                      var allModules = provider.modules
                          .where((m) => m.subject == widget.subjectIdentifier)
                          .toList();

                      if (_selectedTerm != 'all') {
                        allModules = allModules.where((m) => m.term == _selectedTerm).toList();
                      }

                      if (allModules.isEmpty) return _buildEmpty(isDark);
                      return _buildModulesList(isDark, allModules);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_off_rounded,
                color: Color(0xFF6366F1), size: 40),
          ),
          const SizedBox(height: 16),
          Text('No Modules Yet',
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
              'Your instructor hasn\'t uploaded any learning materials for this subject yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildModulesList(bool isDark, List<LearningModule> allModules) {
    // Group by term in order
    final grouped = <String, List<LearningModule>>{};
    for (final term in _termOrder) {
      final items = allModules.where((m) => m.term == term).toList();
      if (items.isNotEmpty) grouped[term] = items;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: grouped.entries.expand((entry) {
          final term = entry.key;
          final modules = entry.value;
          final termColor = _termColors[term] ?? const Color(0xFF6366F1);

          return [
            // Term header
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: termColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _termLabels[term] ?? term,
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: termColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${modules.length}',
                      style: GoogleFonts.inter(
                          color: termColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

            // Module cards
            ...modules.map((m) => _moduleCard(isDark, m, termColor)),
          ];
        }).toList(),
      ),
    );
  }

  Widget _moduleCard(bool isDark, LearningModule m, Color termColor) {
    final isSlides = m.fileUrl.toLowerCase().contains('presentation');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openModule(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? termColor.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: termColor.withValues(alpha: isDark ? 0.18 : 0.12)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: termColor.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: termColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSlides
                    ? Icons.slideshow_rounded
                    : Icons.picture_as_pdf_rounded,
                color: termColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Title + description
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: GoogleFonts.inter(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (m.description != null && m.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(m.description!,
                          style: GoogleFonts.inter(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(
                        isSlides
                            ? Icons.slideshow_rounded
                            : Icons.picture_as_pdf_rounded,
                        size: 12,
                        color: isDark
                            ? Colors.grey[600]
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(isSlides ? 'Google Slides' : 'PDF Document',
                          style: GoogleFonts.inter(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ]),
            ),

            // Open arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: termColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.open_in_new_rounded,
                  color: termColor, size: 16),
            ),
          ]),
        ),
      ),
    );
  }

  void _openModule(LearningModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleViewerScreen(
          title: module.title,
          fileUrl: module.fileUrl,
        ),
      ),
    );
  }
}
