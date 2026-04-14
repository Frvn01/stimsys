import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';
import '../models/instructor_model.dart';
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Student> _students = [];
  List<Subject> _subjects = [];
  List<Instructor> _instructors = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;

  List<Student> get students => _students;
  List<Subject> get subjects => _subjects;
  List<Instructor> get instructors => _instructors;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  int get totalStudents => _students.length;
  int get confirmedStudents => _students.where((s) => s.isConfirmed).length;
  int get totalSubjects => _subjects.length;

  // Admin PIN
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
}
