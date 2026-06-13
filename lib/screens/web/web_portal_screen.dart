import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/subject_model.dart';
import '../../models/assessment_model.dart';
import 'web_question_viewer.dart';

class WebPortalScreen extends StatefulWidget {
  const WebPortalScreen({super.key});

  @override
  State<WebPortalScreen> createState() => _WebPortalScreenState();
}

class _WebPortalScreenState extends State<WebPortalScreen> {
  Subject? _selectedSubject;
  bool _loading = false;
  final SupabaseService _service = SupabaseService();
  List<Subject> _allSubjects = [];
  List<AssessmentConfig> _assessments = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loading = true);
    try {
      _allSubjects = await _service.getSubjects();
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectSubject(Subject subject) async {
    setState(() {
      _selectedSubject = subject;
      _loading = true;
    });
    try {
      _assessments = await _service.getPublishedAssessments(subject.id!);
    } catch (e) {
      debugPrint('Error loading assessments: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF2D3B52))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: Color(0xFF6366F1), size: 32),
                  const SizedBox(width: 16),
                  Text('STIMSYS', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(width: 8),
                  Text('Web Projector', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_selectedSubject != null)
                    TextButton.icon(
                      onPressed: () => setState(() { _selectedSubject = null; _assessments = []; }),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      label: Text('Back to Subjects', style: GoogleFonts.inter(color: Colors.white)),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : _selectedSubject == null
                      ? _buildSubjectList()
                      : _buildTermsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_allSubjects.isEmpty) {
      return Center(child: Text('No subjects found.', style: GoogleFonts.inter(color: Colors.white)));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(40),
          itemCount: _allSubjects.length,
          itemBuilder: (context, index) {
            final s = _allSubjects[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _selectSubject(s),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.class_rounded, color: Color(0xFF6366F1), size: 28),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.subjectTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('${s.subjectCode} • ${s.scheduleDay} ${s.scheduleStartTime}-${s.scheduleEndTime}',
                                  style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTermsList() {
    final terms = ['prelim', 'midterm', 'semi_finals', 'finals'];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(40),
          children: [
            Text('Select a Term', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Terms with no uploaded assessments are locked.', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
            const SizedBox(height: 32),
            ...terms.map((t) => _buildTermCard(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildTermCard(String term) {
    final termAssessments = _assessments.where((a) => a.term == term).toList();
    final isLocked = termAssessments.isEmpty;
    final termTitle = AssessmentConfig.termLabel(term);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLocked ? const Color(0xFF1E293B) : const Color(0xFF6366F1).withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, color: isLocked ? Colors.grey[600] : const Color(0xFF10B981)),
                const SizedBox(width: 12),
                Text(termTitle, style: GoogleFonts.inter(color: isLocked ? Colors.grey[500] : Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            if (!isLocked) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: termAssessments.map((a) {
                  return Material(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => WebQuestionViewer(assessment: a)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(a.isExam ? Icons.assignment_rounded : Icons.quiz_rounded, color: const Color(0xFF818CF8)),
                            const SizedBox(width: 12),
                            Text(a.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(6)),
                              child: Text('Start Display', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text('No assessments uploaded yet.', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }
}
