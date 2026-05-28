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

  List<Student> get students => _students;
  List<Subject> get subjects => _subjects;
  List<Instructor> get instructors => _instructors;
  List<GradeCapture> get captures => _captures;
  List<LearningModule> get modules => _modules;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

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
}
