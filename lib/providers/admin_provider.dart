import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
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
import '../models/announcement_model.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Student> _students = [];
  List<Subject> _subjects = [];
  List<Instructor> _instructors = [];
  List<GradeCapture> _captures = [];
  List<LearningModule> _modules = [];
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  // ── Super Admin & Instructor Auth State ─────────────
  bool _isSuperAdmin = false;
  Instructor? _currentInstructor;

  bool get isSuperAdmin => _isSuperAdmin;
  Instructor? get currentInstructor => _currentInstructor;

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
  List<Announcement> get announcements => _announcements;
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
  // SUPER ADMIN AUTH
  // ═══════════════════════════════════════════════════

  /// Hardcoded Super Admin credentials (developer-only access)
  static const String _superAdminUsername = 'Raven_1DevStimsysSuperAdmin';
  static const String _superAdminPassword = 'RavenDev@St1msys';

  static const String _sessionKey = 'instructor_session_token';

  /// Authenticate as Super Admin using username + password.
  bool authenticateSuperAdmin(String username, String password) {
    _isSuperAdmin = (username.trim() == _superAdminUsername &&
        password == _superAdminPassword);
    if (_isSuperAdmin) _isAuthenticated = true;
    notifyListeners();
    return _isSuperAdmin;
  }

  // ═══════════════════════════════════════════════════
  // INSTRUCTOR QR AUTH
  // ═══════════════════════════════════════════════════

  /// Authenticate an instructor by scanning their QR token.
  /// Returns true on success; generates a new session token.
  Future<bool> authenticateInstructorQr(String token) async {
    try {
      final instructor = await _service.getInstructorByQrToken(token);
      if (instructor == null || instructor.id == null) return false;

      // Generate a new persistent session token
      final sessionToken = _service.generateSessionToken();
      final updated = await _service.markQrTokenUsed(instructor.id!, sessionToken);
      if (updated == null) return false;

      _currentInstructor = updated;
      _isAuthenticated = true;

      // Persist session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, sessionToken);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QR auth error: $e');
      return false;
    }
  }

  /// Try to restore a previous instructor session from local storage.
  /// Returns true if a valid session was found and restored.
  Future<bool> restoreInstructorSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sessionKey);
      if (token == null || token.isEmpty) return false;

      final instructor = await _service.validateSessionToken(token);
      if (instructor == null) {
        await prefs.remove(_sessionKey);
        return false;
      }

      _currentInstructor = instructor;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Restore session error: $e');
      return false;
    }
  }

  // ── Legacy PIN auth (kept for backwards compatibility) ──
  static const String _adminPin = '1337';

  bool authenticatePin(String pin) {
    _isAuthenticated = pin == _adminPin;
    notifyListeners();
    return _isAuthenticated;
  }

  Future<void> logout() async {
    // Clear instructor session from Supabase & local storage
    if (_currentInstructor?.id != null) {
      await _service.clearInstructorSession(_currentInstructor!.id!);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);

    _isAuthenticated = false;
    _isSuperAdmin = false;
    _currentInstructor = null;
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
  // SUPER ADMIN: INSTRUCTOR MANAGEMENT
  // ═══════════════════════════════════════════════════

  /// Register a new instructor — Super Admin only.
  Future<Instructor> registerInstructor({
    required String fullName,
    String? email,
    String? department,
    String? phone,
  }) async {
    final instructor = await _service.registerInstructor(
      fullName: fullName,
      email: email,
      department: department,
      phone: phone,
    );
    _instructors.insert(0, instructor);
    notifyListeners();
    return instructor;
  }

  /// Deactivate an instructor account.
  Future<void> deactivateInstructor(String id) async {
    await _service.deactivateInstructor(id);
    final idx = _instructors.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _instructors[idx] = _instructors[idx].copyWith(isActive: false);
      notifyListeners();
    }
  }

  /// Re-activate an instructor account.
  Future<void> reactivateInstructor(String id) async {
    await _service.reactivateInstructor(id);
    final idx = _instructors.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _instructors[idx] = _instructors[idx].copyWith(isActive: true);
      notifyListeners();
    }
  }

  /// Permanently delete an instructor.
  Future<void> deleteInstructor(String id) async {
    await _service.deleteInstructor(id);
    _instructors.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Re-generate a fresh QR token for an instructor (resets session too).
  Future<Instructor?> regenerateQrToken(String id) async {
    final updated = await _service.regenerateQrToken(id);
    if (updated != null) {
      final idx = _instructors.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _instructors[idx] = updated;
        notifyListeners();
      }
    }
    return updated;
  }

  /// Re-fetches a single instructor by ID — ensures qr_token is present.
  Future<Instructor?> getInstructorById(String id) =>
      _service.getInstructorById(id);

  // ═══════════════════════════════════════════════════
  // LOAD ALL DATA
  // ═══════════════════════════════════════════════════

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      await loadSubjects();
      await Future.wait([
        loadStudents(),
        loadInstructors(),
        loadModules(),
        loadAnnouncements(),
      ]);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStudents() async {
    try {
      // Always load all students so the registry shows everyone
      _students = await _service.getStudents();
      notifyListeners();
    } catch (e) {
      debugPrint('Load students error: $e');
    }
  }

  Future<void> loadSubjects() async {
    try {
      if (_currentInstructor != null && !_isSuperAdmin) {
        _subjects = await _service.getSubjects(instructorId: _currentInstructor!.id);
      } else {
        _subjects = await _service.getSubjects();
      }
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
    String? themeColor,
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
        themeColor: themeColor,
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

  Future<Subject?> updateSubject({
    required String subjectId,
    required String subjectCode,
    required String subjectTitle,
    required int units,
    required String scheduleStartTime,
    required String scheduleEndTime,
    required String scheduleDay,
    required String room,
    required String instructorId,
    int lateThresholdMinutes = 15,
    String? themeColor,
  }) async {
    try {
      final subject = await _service.updateSubject(
        subjectId,
        subjectCode: subjectCode,
        subjectTitle: subjectTitle,
        units: units,
        scheduleStartTime: scheduleStartTime,
        scheduleEndTime: scheduleEndTime,
        scheduleDay: scheduleDay,
        room: room,
        instructorId: instructorId,
        lateThresholdMinutes: lateThresholdMinutes,
        themeColor: themeColor,
      );
      if (subject != null) {
        final idx = _subjects.indexWhere((s) => s.id == subjectId);
        if (idx != -1) {
          _subjects[idx] = subject;
          notifyListeners();
        }
      }
      return subject;
    } catch (e) {
      debugPrint('Update subject error: $e');
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
      final record = await _service.markAttendance(
        enrollmentId: enrollmentId,
        subject: subject,
      );
      if (_gradesSubjectId == subject.id) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
      return record;
    } catch (e) {
      debugPrint('Mark attendance error: $e');
      rethrow;
    }
  }

  Future<int> markAbsentees(String subjectId) async {
    try {
      final count = await _service.markAbsentees(subjectId);
      if (_gradesSubjectId == subjectId) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
      return count;
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
      final instId = (!_isSuperAdmin && _currentInstructor != null) ? _currentInstructor!.id : null;
      return await _service.getTodayAttendanceCount(instructorId: instId);
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
      if (_gradesSubjectId != null) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
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
      final record = await _service.createManualAttendance(
        enrollmentId: enrollmentId,
        status: status,
        date: date,
        remarks: remarks,
      );
      if (_gradesSubjectId != null) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
      return record;
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
      final all = await _service.getModules();
      if (_currentInstructor != null && !_isSuperAdmin) {
        final allowedCodes =
            _subjects.map((s) => s.subjectCode.toLowerCase().trim()).toSet();
        final allowedTitles =
            _subjects.map((s) => s.subjectTitle.toLowerCase().trim()).toSet();
        _modules = all.where((m) {
          final subj = m.subject.toLowerCase().trim();
          if (allowedCodes.contains(subj) || allowedTitles.contains(subj)) {
            return true;
          }
          return allowedCodes
                  .any((code) => code.isNotEmpty && subj.contains(code)) ||
              allowedTitles
                  .any((title) => title.isNotEmpty && subj.contains(title));
        }).toList();
      } else {
        _modules = all;
      }
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

  Future<String> generateExamSessionCode(String assessmentId, {String? targetSet}) async {
    try {
      String code = await _service.generateSessionCode(assessmentId);
      
      if (targetSet != null) {
        // Since _service.generateSessionCode always generates a new random code, 
        // we append the set manually and forcefully update it
        code = '$code-$targetSet';
        await _service.client.from('assessments').update({'session_code': code}).eq('id', assessmentId);
      }
      
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

  /// Load grade items for ALL students in the current subject for a given term.
  /// This populates _gradeItems for every grade ID in that term.
  Future<void> loadAllGradeItemsForTerm(String term) async {
    try {
      final gradeIds = _subjectGrades
          .where((g) => g.term == term && g.id != null)
          .map((g) => g.id!)
          .toList();
      if (gradeIds.isEmpty) return;
      final batchMap = await _service.getGradeItemsBatch(gradeIds);
      _gradeItems.addAll(batchMap);
      // Also fill empty lists for grades that had no items
      for (final gid in gradeIds) {
        _gradeItems.putIfAbsent(gid, () => []);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load all grade items for term error: $e');
    }
  }

  /// Get unique item column labels for a term (ordered by category then label).
  List<({String category, String label})> uniqueItemColumnsForTerm(String term) {
    final seen = <String>{};
    final columns = <({String category, String label})>[];

    // Collect items from all students for this term
    for (final grade in _subjectGrades.where((g) => g.term == term)) {
      if (grade.id == null) continue;
      for (final item in (_gradeItems[grade.id!] ?? <StudentGradeItem>[])) {
        final key = '${item.category}::${item.label}';
        if (seen.add(key)) {
          columns.add((category: item.category, label: item.label));
        }
      }
    }

    // Sort: exams first, then quizzes, then activities
    const order = {'exam': 0, 'quiz': 1, 'activity': 2};
    columns.sort((a, b) {
      final catCmp = (order[a.category] ?? 3).compareTo(order[b.category] ?? 3);
      if (catCmp != 0) return catCmp;
      return a.label.compareTo(b.label);
    });
    return columns;
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

  Future<void> deleteGradeItemColumnForTerm({
    required String term,
    required String category,
    required String label,
  }) async {
    try {
      final gradeIds = _subjectGrades
          .where((g) => g.term == term && g.id != null)
          .map((g) => g.id!)
          .toList();
      if (gradeIds.isEmpty) return;

      await _service.deleteGradeItemsByLabelAndCategory(
        gradeIds: gradeIds,
        category: category,
        label: label,
      );

      for (final gid in gradeIds) {
        _gradeItems[gid]
            ?.removeWhere((i) => i.category == category && i.label == label);
      }

      if (_gradesSubjectId != null) {
        await loadSubjectGrades(_gradesSubjectId!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Delete grade item column error: $e');
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

  // ═══════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════

  Future<void> loadAnnouncements() async {
    try {
      final all = await _service.getAnnouncements();
      if (_currentInstructor != null && !_isSuperAdmin) {
        final subjectIds = _subjects.map((s) => s.id).toSet();
        _announcements = all.where((a) => a.subjectId == null || a.subjectId == 'All' || subjectIds.contains(a.subjectId)).toList();
      } else {
        _announcements = all;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load announcements error: $e');
    }
  }

  Future<Announcement?> addAnnouncement(Announcement announcement) async {
    try {
      final created = await _service.createAnnouncement(announcement);
      if (created != null) {
        _announcements.insert(0, created);
        notifyListeners();
      }
      return created;
    } catch (e) {
      debugPrint('Add announcement error: $e');
      rethrow;
    }
  }

  Future<Announcement?> editAnnouncement(Announcement announcement) async {
    try {
      final updated = await _service.updateAnnouncement(announcement);
      if (updated != null) {
        final idx = _announcements.indexWhere((a) => a.id == announcement.id);
        if (idx != -1) _announcements[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      debugPrint('Edit announcement error: $e');
      rethrow;
    }
  }

  Future<void> removeAnnouncement(String id) async {
    try {
      await _service.deleteAnnouncement(id);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Remove announcement error: $e');
      rethrow;
    }
  }

  Future<void> toggleAnnouncementActive(String id, bool isActive) async {
    try {
      await _service.toggleAnnouncementActive(id, isActive);
      final idx = _announcements.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _announcements[idx] = _announcements[idx].copyWith(isActive: isActive);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Toggle announcement error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // APPEAL SYSTEM
  // ═══════════════════════════════════════════════════

  List<AssessmentSubmission> _pendingAppeals = [];
  List<AssessmentSubmission> get pendingAppeals => _pendingAppeals;

  /// Load all pending appeals.
  Future<void> loadPendingAppeals() async {
    try {
      _pendingAppeals = await _service.getPendingAppeals();
      notifyListeners();
    } catch (e) {
      debugPrint('Load pending appeals error: $e');
    }
  }

  /// Approve an appeal (deletes submission so student can retake).
  Future<void> approveAppeal(String submissionId) async {
    try {
      await _service.approveAppeal(submissionId);
      _pendingAppeals.removeWhere((a) => a.id == submissionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Approve appeal error: $e');
      rethrow;
    }
  }

  /// Reject an appeal.
  Future<void> rejectAppeal(String submissionId) async {
    try {
      await _service.rejectAppeal(submissionId);
      _pendingAppeals.removeWhere((a) => a.id == submissionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Reject appeal error: $e');
      rethrow;
    }
  }
}
