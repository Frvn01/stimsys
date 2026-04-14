import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';

class StudentProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  Student? _currentStudent;
  List<Enrollment> _enrollments = [];
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = false;

  Student? get currentStudent => _currentStudent;
  List<Enrollment> get enrollments => _enrollments;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentStudent != null;

  String get fullName => _currentStudent?.fullName ?? '-';
  String get usn => _currentStudent?.usn ?? '-';
  String get course => _currentStudent?.course ?? '-';
  String get yearLevel => _currentStudent?.yearLevel ?? '-';
  String get section => _currentStudent?.section ?? '-';
  String get yearSection => _currentStudent?.yearSection ?? '-';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Student?> login(String usn, String password) async {
    _setLoading(true);
    try {
      final student = await _service.loginStudent(usn, password);
      if (student != null) {
        _currentStudent = student;
        await loadEnrollments();
        await loadAttendance();
        notifyListeners();
      }
      return student;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Student?> register({
    required String usn,
    required String password,
    required String lastName,
    required String firstName,
    String? middleName,
    required String course,
    required String yearLevel,
    required String section,
  }) async {
    _setLoading(true);
    try {
      final student = await _service.registerStudent(
        usn: usn,
        password: password,
        lastName: lastName,
        firstName: firstName,
        middleName: middleName,
        course: course,
        yearLevel: yearLevel,
        section: section,
      );
      return student;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEnrollments() async {
    if (_currentStudent?.id == null) return;
    try {
      _enrollments = await _service.getStudentEnrollments(_currentStudent!.id!);
      notifyListeners();
    } catch (e) {
      debugPrint('Load enrollments error: $e');
    }
  }

  Future<void> loadAttendance() async {
    if (_currentStudent?.id == null) return;
    try {
      _attendanceRecords =
          await _service.getStudentAttendance(_currentStudent!.id!);
      notifyListeners();
    } catch (e) {
      debugPrint('Load attendance error: $e');
    }
  }

  /// Get attendance records for a specific subject
  List<AttendanceRecord> getAttendanceForSubject(String subjectCode) {
    return _attendanceRecords
        .where((a) => a.subjectCode == subjectCode)
        .toList();
  }

  void logout() {
    _currentStudent = null;
    _enrollments = [];
    _attendanceRecords = [];
    notifyListeners();
  }
}
