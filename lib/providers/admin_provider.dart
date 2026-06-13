import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';
import '../models/instructor_model.dart';
import '../models/grade_capture_model.dart';
import '../models/module_model.dart';
import '../models/grading_config_model.dart';
import '../models/student_grade_model.dart';
import '../models/assessment_model.dart';
import '../models/student_grade_item_model.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Student> _students = [];
  List<Subject> _subjects = [];
  List<Instructor> _instructors = [];
  List<GradeCapture> _captures = [];
  List<LearningModule> _modules = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  // ── Grading state ──────────────────────────────────
  /// Cache of grading configs keyed by subjectId
  final Map<String, GradingConfig> _gradingConfigs = {};
  /// All grade records for the currently viewed subject
  List<StudentGrade> _subjectGrades = [];
  /// Enrollment roster (enrollmentId → student info) for grade table
  List<Map<String, dynamic>> _gradeRoster = [];
  String? _gradesSubjectId;

  List<Student> get students => _students;
  List<Subject> get subjects => _subjects;
  List<Instructor> get instructors => _instructors;
  List<GradeCapture> get captures => _captures;
  List<LearningModule> get modules => _modules;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Map<String, GradingConfig> get gradingConfigs => _gradingConfigs;
  List<StudentGrade> get subjectGrades => _subjectGrades;
  List<Map<String, dynamic>> get gradeRoster => _gradeRoster;
  String? get gradesSubjectId => _gradesSubjectId;

  GradingConfig? configFor(String subjectId) => _gradingConfigs[subjectId];

  int get totalStudents => _students.length;
  int get confirmedStudents => _students.where((s) => s.isConfirmed).length;
  int get totalSubjects => _subjects.length;

  // ═══════════════════════════════════════════════════
  // ADMIN AUTH
  // ═══════════════════════════════════════════════════

  static const String _adminPin = '1337';

  bool authenticatePin(String pin) {
    _isAuthenticated = pin == _adminPin;
    notifyListeners();
    return _isAuthenticated;
  }

  void logout() {
    _isAuthenticated = false;
    _students = [];
    _subjects = [];
    _captures = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // LOAD ALL DATA
  // ═══════════════════════════════════════════════════

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadStudents(),
        loadSubjects(),
        loadInstructors(),
        loadModules(),
      ]);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStudents() async {
    try {
      _students = await _service.getStudents();
      notifyListeners();
    } catch (e) {
      debugPrint('Load students error: $e');
    }
  }

  Future<void> loadSubjects() async {
    try {
      _subjects = await _service.getSubjects();
      notifyListeners();
    } catch (e) {
      debugPrint('Load subjects error: $e');
    }
  }

  Future<void> loadInstructors() async {
    try {
      _instructors = await _service.getInstructors();
      notifyListeners();
    } catch (e) {
      debugPrint('Load instructors error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT MANAGEMENT
  // ═══════════════════════════════════════════════════

  Future<void> confirmStudent(String id) async {
    try {
      await _service.confirmStudent(id);
      final idx = _students.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _students[idx] = _students[idx].copyWith(isConfirmed: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Confirm student error: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _service.deleteStudent(id);
      _students.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete student error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // SUBJECT MANAGEMENT
  // ═══════════════════════════════════════════════════

  Future<Subject?> createSubject({
    required String subjectCode,
    required String subjectTitle,
    required int units,
    required String scheduleStartTime,
    required String scheduleEndTime,
    required String scheduleDay,
    required String room,
    required String instructorId,
    int lateThresholdMinutes = 15,
  }) async {
    try {
      final subject = await _service.createSubject(
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
        units: units,
        scheduleStartTime: scheduleStartTime,
        scheduleEndTime: scheduleEndTime,
        scheduleDay: scheduleDay,
        room: room,
        instructorId: instructorId,
        lateThresholdMinutes: lateThresholdMinutes,
      );
      if (subject != null) {
        _subjects.insert(0, subject);
        notifyListeners();
      }
      return subject;
    } catch (e) {
      debugPrint('Create subject error: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      await _service.deleteSubject(id);
      _subjects.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete subject error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // ENROLLMENTS
  // ═══════════════════════════════════════════════════

  Future<Enrollment?> enrollStudent(String studentId, String subjectId) async {
    try {
      return await _service.enrollStudent(studentId, subjectId);
    } catch (e) {
      debugPrint('Enroll error: $e');
      rethrow;
    }
  }

  Future<List<Enrollment>> getSubjectEnrollments(String subjectId) async {
    try {
      return await _service.getSubjectEnrollments(subjectId);
    } catch (e) {
      debugPrint('Get enrollments error: $e');
      return [];
    }
  }

  Future<void> unenrollStudent(String enrollmentId) async {
    try {
      await _service.unenrollStudent(enrollmentId);
    } catch (e) {
      debugPrint('Unenroll error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════

  Future<AttendanceRecord?> markAttendance({
    required String enrollmentId,
    required Subject subject,
  }) async {
    try {
      return await _service.markAttendance(
        enrollmentId: enrollmentId,
        subject: subject,
      );
    } catch (e) {
      debugPrint('Mark attendance error: $e');
      rethrow;
    }
  }

  Future<int> markAbsentees(String subjectId) async {
    try {
      return await _service.markAbsentees(subjectId);
    } catch (e) {
      debugPrint('Mark absentees error: $e');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getSubjectAttendance(
      String subjectId, {DateTime? date}) async {
    try {
      return await _service.getAttendanceBySubject(subjectId, date: date);
    } catch (e) {
      debugPrint('Get attendance error: $e');
      return [];
    }
  }

  Future<int> getTodayAttendanceCount() async {
    try {
      return await _service.getTodayAttendanceCount();
    } catch (e) {
      return 0;
    }
  }

  Future<Enrollment?> findEnrollment(String studentUsn, String subjectId) async {
    try {
      return await _service.findEnrollment(studentUsn, subjectId);
    } catch (e) {
      debugPrint('Find enrollment error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════
  // ADMIN ATTENDANCE EDITING
  // ═══════════════════════════════════════════════════

  Future<void> updateAttendanceStatus(
      String attendanceId, String newStatus, {String? remarks}) async {
    try {
      await _service.updateAttendanceStatus(
          attendanceId, newStatus, remarks: remarks);
    } catch (e) {
      debugPrint('Update attendance status error: $e');
      rethrow;
    }
  }

  Future<AttendanceRecord?> createManualAttendance({
    required String enrollmentId,
    required String status,
    required DateTime date,
    String? remarks,
  }) async {
    try {
      return await _service.createManualAttendance(
        enrollmentId: enrollmentId,
        status: status,
        date: date,
        remarks: remarks,
      );
    } catch (e) {
      debugPrint('Create manual attendance error: $e');
      rethrow;
    }
  }

  Future<List<RosterEntry>> getSubjectRoster(
      String subjectId, {DateTime? date}) async {
    try {
      return await _service.getSubjectRoster(subjectId, date: date);
    } catch (e) {
      debugPrint('Get subject roster error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // CLASS CANCELLATIONS
  // ═══════════════════════════════════════════════════

  Future<ClassCancellation?> markClassCancelled({
    required String subjectId,
    required DateTime date,
    required String reason,
    String? remarks,
  }) async {
    try {
      return await _service.markClassCancelled(
        subjectId: subjectId,
        date: date,
        reason: reason,
        remarks: remarks,
      );
    } catch (e) {
      debugPrint('Mark class cancelled error: $e');
      rethrow;
    }
  }

  Future<void> restoreClassDay({
    required String subjectId,
    required DateTime date,
  }) async {
    try {
      await _service.restoreClassDay(subjectId: subjectId, date: date);
    } catch (e) {
      debugPrint('Restore class day error: $e');
      rethrow;
    }
  }

  Future<List<ClassCancellation>> getCancellationsForSubject(
      String subjectId) async {
    try {
      return await _service.getCancellationsForSubject(subjectId);
    } catch (e) {
      debugPrint('Get cancellations error: $e');
      return [];
    }
  }

  Future<ClassCancellation?> getCancellationForDate(
      String subjectId, DateTime date) async {
    try {
      return await _service.getCancellationForDate(subjectId, date);
    } catch (e) {
      debugPrint('Get cancellation for date error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════
  // LEARNING MODULES
  // ═══════════════════════════════════════════════════

  Future<void> loadModules() async {
    try {
      _modules = await _service.getModules();
      notifyListeners();
    } catch (e) {
      debugPrint('Load modules error: $e');
    }
  }

  Future<LearningModule?> addModule(LearningModule module) async {
    try {
      final created = await _service.createModule(module);
      if (created != null) {
        _modules.insert(0, created);
        notifyListeners();
      }
      return created;
    } catch (e) {
      debugPrint('Add module error: $e');
      rethrow;
    }
  }

  Future<LearningModule?> editModule(LearningModule module) async {
    try {
      final updated = await _service.updateModule(module);
      if (updated != null) {
        final idx = _modules.indexWhere((m) => m.id == module.id);
        if (idx != -1) _modules[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('Edit module error: $e');
      rethrow;
    }
  }

  Future<void> deleteModule(String id) async {
    try {
      await _service.deleteModule(id);
      _modules.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete module error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // GRADE CAPTURES
  // ═══════════════════════════════════════════════════

  Future<void> loadCaptures({String? subjectId}) async {
    try {
      await _service.cleanupExpiredCaptures();
      _captures = await _service.getGradeCaptures(subjectId: subjectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load captures error: $e');
    }
  }

  Future<GradeCapture?> captureAndUpload({
    required File file,
    required String fileType,
    String? studentNote,
    String? subjectId,
    String? studentName,
    String? section,
  }) async {
    try {
      final ext = p.extension(file.path).isNotEmpty
          ? p.extension(file.path)
          : '.jpg';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_captures.length}$ext';

      final url = await _service.uploadGradeCaptureFile(file, fileName);

      final capture = await _service.createGradeCapture(
        fileUrl: url,
        fileType: fileType,
        studentNote: studentNote,
        subjectId: subjectId,
        studentName: studentName,
        section: section,
      );

      if (capture != null) {
        _captures.insert(0, capture);
        notifyListeners();
      }
      return capture;
    } catch (e) {
      debugPrint('Capture upload error: $e');
      rethrow;
    }
  }

  Future<void> deleteCapture(String id, String fileUrl) async {
    try {
      await _service.deleteGradeCapture(id, fileUrl);
      _captures.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete capture error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // GRADING CONFIG
  // ═══════════════════════════════════════════════════

  Future<GradingConfig?> loadGradingConfig(String subjectId) async {
    try {
      final config = await _service.getGradingConfig(subjectId);
      if (config != null) {
        _gradingConfigs[subjectId] = config;
        notifyListeners();
      }
      return config;
    } catch (e) {
      debugPrint('Load grading config error: $e');
      return null;
    }
  }

  Future<GradingConfig?> saveGradingConfig(GradingConfig config) async {
    try {
      final saved = await _service.saveGradingConfig(config);
      if (saved != null) {
        _gradingConfigs[config.subjectId] = saved;
        notifyListeners();
      }
      return saved;
    } catch (e) {
      debugPrint('Save grading config error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT GRADES
  // ═══════════════════════════════════════════════════

  /// Load all grades + roster for a subject into state.
  Future<void> loadSubjectGrades(String subjectId) async {
    try {
      _gradesSubjectId = subjectId;
      final results = await Future.wait([
        _service.getSubjectGrades(subjectId),
        _service.getSubjectEnrollmentRoster(subjectId),
        _service.getGradingConfig(subjectId),
      ]);
      _subjectGrades = results[0] as List<StudentGrade>;
      _gradeRoster   = results[1] as List<Map<String, dynamic>>;
      final cfg = results[2] as GradingConfig?;
      if (cfg != null) _gradingConfigs[subjectId] = cfg;
      notifyListeners();
    } catch (e) {
      debugPrint('Load subject grades error: $e');
    }
  }

  /// Save a grade entry and refresh local state.
  Future<StudentGrade?> saveStudentGrade(StudentGrade grade) async {
    try {
      final saved = await _service.upsertStudentGrade(grade);
      if (saved != null) {
        final idx = _subjectGrades
            .indexWhere((g) =>
                g.enrollmentId == grade.enrollmentId && g.term == grade.term);
        if (idx >= 0) {
          _subjectGrades[idx] = saved;
        } else {
          _subjectGrades.add(saved);
        }
        notifyListeners();
      }
      return saved;
    } catch (e) {
      debugPrint('Save student grade error: $e');
      rethrow;
    }
  }

  /// Returns the saved StudentGrade for a specific enrollment + term, or null.
  StudentGrade? gradeFor(String enrollmentId, String term) {
    try {
      return _subjectGrades.firstWhere(
          (g) => g.enrollmentId == enrollmentId && g.term == term);
    } catch (_) {
      return null;
    }
  }

  /// Build final summary list from current _subjectGrades + _gradeRoster.
  List<StudentFinalSummary> buildFinalSummaries(List<String> terms) {
    return _gradeRoster.map((enrollment) {
      final enrollmentId = enrollment['id'] as String;
      final student =
          enrollment['students'] as Map<String, dynamic>? ?? {};
      final termGrades = <String, double?>{};
      for (final t in terms) {
        final g = gradeFor(enrollmentId, t);
        termGrades[t] = g?.computedGrade;
      }
      return StudentFinalSummary(
        enrollmentId: enrollmentId,
        studentId: student['id'] ?? '',
        lastName: student['last_name'] ?? '',
        firstName: student['first_name'] ?? '',
        usn: student['usn'] ?? '',
        termGrades: termGrades,
      );
    }).toList()
      ..sort((a, b) {
        final last = a.lastName.compareTo(b.lastName);
        return last != 0 ? last : a.firstName.compareTo(b.firstName);
      });
  }

  // ═══════════════════════════════════════════════════
  // ASSESSMENTS (Quizzes & Exams)
  // ═══════════════════════════════════════════════════

  List<AssessmentConfig> _assessments = [];
  List<AssessmentQuestion> _currentQuestions = [];
  List<AssessmentSubmission> _currentSubmissions = [];
  final Map<String, List<StudentGradeItem>> _gradeItems = {};

  List<AssessmentConfig> get assessments => _assessments;
  List<AssessmentQuestion> get currentQuestions => _currentQuestions;
  List<AssessmentSubmission> get currentSubmissions => _currentSubmissions;

  List<AssessmentConfig> assessmentsForTerm(String term) =>
      _assessments.where((a) => a.term == term).toList();

  List<StudentGradeItem> gradeItemsFor(String gradeId) =>
      _gradeItems[gradeId] ?? [];

  Future<void> loadAssessments(String subjectId) async {
    try {
      _assessments = await _service.getAssessmentsForSubject(subjectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load assessments error: $e');
    }
  }

  Future<AssessmentConfig?> createAssessment(AssessmentConfig config) async {
    try {
      final created = await _service.createAssessment(config);
      if (created != null) {
        _assessments.add(created);
        notifyListeners();
      }
      return created;
    } catch (e) {
      debugPrint('Create assessment error: $e');
      rethrow;
    }
  }

  Future<AssessmentConfig?> updateAssessment(AssessmentConfig config) async {
    try {
      final updated = await _service.updateAssessment(config);
      if (updated != null) {
        final idx = _assessments.indexWhere((a) => a.id == config.id);
        if (idx >= 0) _assessments[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('Update assessment error: $e');
      rethrow;
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _service.deleteAssessment(id);
      _assessments.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete assessment error: $e');
      rethrow;
    }
  }

  Future<void> publishAssessment(String id, bool publish) async {
    try {
      await _service.publishAssessment(id, publish);
      final idx = _assessments.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        _assessments[idx] = _assessments[idx].copyWith(isPublished: publish);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Publish assessment error: $e');
      rethrow;
    }
  }

  Future<String> generateExamSessionCode(String assessmentId) async {
    try {
      final code = await _service.generateSessionCode(assessmentId);
      final idx = _assessments.indexWhere((a) => a.id == assessmentId);
      if (idx >= 0) {
        _assessments[idx] = _assessments[idx].copyWith(sessionCode: code);
        notifyListeners();
      }
      return code;
    } catch (e) {
      debugPrint('Generate session code error: $e');
      rethrow;
    }
  }

  // ── Questions ──────────────────────────────────────

  Future<void> loadQuestions(String assessmentId) async {
    try {
      _currentQuestions = await _service.getQuestions(assessmentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load questions error: $e');
    }
  }

  Future<AssessmentQuestion?> addQuestion(AssessmentQuestion q) async {
    try {
      final created = await _service.addQuestion(q);
      if (created != null) {
        _currentQuestions.add(created);
        notifyListeners();
      }
      return created;
    } catch (e) {
      debugPrint('Add question error: $e');
      rethrow;
    }
  }

  Future<AssessmentQuestion?> updateQuestion(AssessmentQuestion q) async {
    try {
      final updated = await _service.updateQuestion(q);
      if (updated != null) {
        final idx = _currentQuestions.indexWhere((x) => x.id == q.id);
        if (idx >= 0) _currentQuestions[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('Update question error: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(String id) async {
    try {
      await _service.deleteQuestion(id);
      _currentQuestions.removeWhere((q) => q.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete question error: $e');
      rethrow;
    }
  }

  // ── Submissions ────────────────────────────────────

  Future<void> loadSubmissions(String assessmentId) async {
    try {
      _currentSubmissions =
          await _service.getSubmissionsForAssessment(assessmentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load submissions error: $e');
    }
  }

  // ── QR Grade Processing ────────────────────────────

  Future<(bool, String)> processScannedGradeQR(String qrData) async {
    try {
      final result = await _service.processGradeQR(qrData);
      // Refresh grades if a subject is currently loaded
      if (_gradesSubjectId != null) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
      return result;
    } catch (e) {
      debugPrint('Process QR error: $e');
      return (false, 'Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT GRADE ITEMS
  // ═══════════════════════════════════════════════════

  Future<void> loadGradeItems(String gradeId) async {
    try {
      _gradeItems[gradeId] = await _service.getGradeItems(gradeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load grade items error: $e');
    }
  }

  Future<StudentGradeItem?> saveGradeItem(StudentGradeItem item) async {
    try {
      final saved = await _service.upsertGradeItem(item);
      if (saved != null) {
        final list = _gradeItems.putIfAbsent(item.gradeId, () => []);
        final idx = list.indexWhere((i) => i.id == saved.id);
        if (idx >= 0) {
          list[idx] = saved;
        } else {
          list.add(saved);
        }
        // Recalculate totals
        await _service.recalculateGradeTotals(item.gradeId);
        // Refresh subject grades
        if (_gradesSubjectId != null) {
          await loadSubjectGrades(_gradesSubjectId!);
        }
      }
      return saved;
    } catch (e) {
      debugPrint('Save grade item error: $e');
      rethrow;
    }
  }

  Future<void> removeGradeItem(String id, String gradeId) async {
    try {
      await _service.deleteGradeItem(id);
      _gradeItems[gradeId]?.removeWhere((i) => i.id == id);
      await _service.recalculateGradeTotals(gradeId);
      if (_gradesSubjectId != null) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Remove grade item error: $e');
      rethrow;
    }
  }

  // ── Attendance Auto-Compute ────────────────────────

  Future<void> autoComputeAttendance(
      String enrollmentId, String gradeId, double maxScore) async {
    try {
      final result = await _service.computeAttendanceScore(
        enrollmentId: enrollmentId,
        maxScore: maxScore,
      );
      // Update the grade record directly
      await _service.client
          .from('student_grades')
          .update({
            'attendance_raw': result.raw,
            'attendance_max': result.max,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gradeId);
      // Recalculate
      await _service.recalculateGradeTotals(gradeId);
      if (_gradesSubjectId != null) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
    } catch (e) {
      debugPrint('Auto compute attendance error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // GRADE SCANNING
  // ═══════════════════════════════════════════════════

  Future<(bool, String)> processGradeQR(String qrData) async {
    return await _service.processGradeQR(qrData);
  }
}
