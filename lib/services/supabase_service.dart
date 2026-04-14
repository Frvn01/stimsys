import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../core/supabase_config.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';
import '../models/instructor_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = SupabaseConfig.client;

  // ═══════════════════════════════════════════════════
  // PASSWORD HASHING
  // ═══════════════════════════════════════════════════

  String hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  // ═══════════════════════════════════════════════════
  // STUDENT AUTH
  // ═══════════════════════════════════════════════════

  Future<Student?> registerStudent({
    required String usn,
    required String password,
    required String lastName,
    required String firstName,
    String? middleName,
    required String course,
    required String yearLevel,
    required String section,
    String? phone,
  }) async {
    try {
      final data = {
        'usn': usn.trim(),
        'password_hash': hashPassword(password),
        'last_name': lastName.trim(),
        'first_name': firstName.trim(),
        'middle_name': middleName?.trim(),
        'course': course.trim(),
        'year_level': yearLevel.trim(),
        'section': section.trim(),
        'phone': phone?.trim(),
        'is_confirmed': false,
      };

      final response = await _client
          .from('students')
          .insert(data)
          .select()
          .single();

      return Student.fromSupabase(response);
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<Student?> loginStudent(String usn, String password) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('usn', usn.trim())
          .maybeSingle();

      if (response == null) return null;

      final storedHash = response['password_hash'];
      final inputHash = hashPassword(password);

      if (storedHash != inputHash) return null;

      return Student.fromSupabase(response);
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENTS CRUD
  // ═══════════════════════════════════════════════════

  Future<List<Student>> getStudents() async {
    try {
      final response = await _client
          .from('students')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => Student.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get students error: $e');
      return [];
    }
  }

  Future<Student?> getStudentByUsn(String usn) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('usn', usn.trim())
          .maybeSingle();

      if (response == null) return null;
      return Student.fromSupabase(response);
    } catch (e) {
      debugPrint('Get student error: $e');
      return null;
    }
  }

  Future<void> confirmStudent(String id) async {
    try {
      await _client
          .from('students')
          .update({'is_confirmed': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Confirm student error: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _client.from('students').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete student error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // INSTRUCTORS
  // ═══════════════════════════════════════════════════

  Future<List<Instructor>> getInstructors() async {
    try {
      final response = await _client
          .from('instructors')
          .select()
          .order('full_name');

      return (response as List)
          .map((e) => Instructor.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get instructors error: $e');
      return [];
    }
  }

  Future<Instructor?> getDefaultInstructor() async {
    final instructors = await getInstructors();
    if (instructors.isNotEmpty) return instructors.first;
    return null;
  }

  // ═══════════════════════════════════════════════════
  // SUBJECTS CRUD
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
      final data = {
        'subject_code': subjectCode.trim().toUpperCase(),
        'subject_title': subjectTitle.trim(),
        'units': units,
        'schedule_start_time': scheduleStartTime,
        'schedule_end_time': scheduleEndTime,
        'schedule_day': scheduleDay.trim().toUpperCase(),
        'room': room.trim(),
        'instructor_id': instructorId,
        'late_threshold_minutes': lateThresholdMinutes,
      };

      final response = await _client
          .from('subjects')
          .insert(data)
          .select('*, instructors(full_name)')
          .single();

      return Subject.fromSupabase(response);
    } catch (e) {
      debugPrint('Create subject error: $e');
      rethrow;
    }
  }

  Future<List<Subject>> getSubjects() async {
    try {
      final response = await _client
          .from('subjects')
          .select('*, instructors(full_name)')
          .order('subject_code');

      return (response as List)
          .map((e) => Subject.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get subjects error: $e');
      return [];
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      await _client.from('subjects').delete().eq('id', id);
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
      final response = await _client
          .from('enrollments')
          .insert({
            'student_id': studentId,
            'subject_id': subjectId,
          })
          .select('*, subjects(*, instructors(full_name))')
          .single();

      return Enrollment.fromSupabase(response);
    } catch (e) {
      debugPrint('Enroll student error: $e');
      rethrow;
    }
  }

  Future<List<Enrollment>> getStudentEnrollments(String studentId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('*, subjects(*, instructors(full_name))')
          .eq('student_id', studentId)
          .order('enrolled_at', ascending: false);

      return (response as List)
          .map((e) => Enrollment.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get enrollments error: $e');
      return [];
    }
  }

  Future<List<Enrollment>> getSubjectEnrollments(String subjectId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('*, students(*)')
          .eq('subject_id', subjectId);

      return (response as List)
          .map((e) => Enrollment.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get subject enrollments error: $e');
      return [];
    }
  }

  Future<void> unenrollStudent(String enrollmentId) async {
    try {
      await _client.from('enrollments').delete().eq('id', enrollmentId);
    } catch (e) {
      debugPrint('Unenroll error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // ATTENDANCE — SMART MARKING
  // ═══════════════════════════════════════════════════

  /// Mark attendance for a student with smart late detection.
  /// Compares scan time to subject's schedule_start_time.
  Future<AttendanceRecord?> markAttendance({
    required String enrollmentId,
    required Subject subject,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check for duplicate
      final existing = await _client
          .from('attendance')
          .select()
          .eq('enrollment_id', enrollmentId)
          .eq('date', today.toIso8601String().split('T').first)
          .maybeSingle();

      if (existing != null) {
        return AttendanceRecord.fromSupabase(existing);
      }

      // Calculate late status
      final startTime = subject.startTimeToday;
      final lateThreshold = startTime.add(
          Duration(minutes: subject.lateThresholdMinutes));

      String status;
      int minutesLate = 0;
      String? remarks;

      if (now.isBefore(lateThreshold) || now.isAtSameMomentAs(lateThreshold)) {
        status = 'present';
        remarks = 'On time';
      } else {
        status = 'late';
        minutesLate = now.difference(startTime).inMinutes;
        remarks = '$minutesLate minutes late';
      }

      final data = {
        'enrollment_id': enrollmentId,
        'date': today.toIso8601String().split('T').first,
        'status': status,
        'scanned_at': now.toIso8601String(),
        'minutes_late': minutesLate,
        'remarks': remarks,
      };

      final response = await _client
          .from('attendance')
          .insert(data)
          .select()
          .single();

      return AttendanceRecord.fromSupabase(response);
    } catch (e) {
      debugPrint('Mark attendance error: $e');
      rethrow;
    }
  }

  /// Mark all enrolled students who haven't scanned as absent.
  Future<int> markAbsentees(String subjectId) async {
    try {
      final today = DateTime.now();
      final dateStr = DateTime(today.year, today.month, today.day)
          .toIso8601String()
          .split('T')
          .first;

      // Get all enrollments for this subject
      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('subject_id', subjectId);

      int absentCount = 0;

      for (final enrollment in enrollments) {
        final enrollmentId = enrollment['id'] as String;

        // Check if already has attendance for today
        final existing = await _client
            .from('attendance')
            .select('id')
            .eq('enrollment_id', enrollmentId)
            .eq('date', dateStr)
            .maybeSingle();

        if (existing == null) {
          // Mark as absent
          await _client.from('attendance').insert({
            'enrollment_id': enrollmentId,
            'date': dateStr,
            'status': 'absent',
            'scanned_at': null,
            'minutes_late': 0,
            'remarks': 'Auto-absent (did not scan)',
          });
          absentCount++;
        }
      }

      return absentCount;
    } catch (e) {
      debugPrint('Mark absentees error: $e');
      rethrow;
    }
  }

  /// Get attendance records for a subject on a given date.
  Future<List<AttendanceRecord>> getAttendanceBySubject(
      String subjectId, {DateTime? date}) async {
    try {
      final dateStr = (date ?? DateTime.now())
          .toIso8601String()
          .split('T')
          .first;

      // Get enrollment IDs for this subject
      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('subject_id', subjectId);

      final enrollmentIds =
          (enrollments as List).map((e) => e['id'] as String).toList();

      if (enrollmentIds.isEmpty) return [];

      final response = await _client
          .from('attendance')
          .select('*, enrollments(*, students(*), subjects(*))')
          .inFilter('enrollment_id', enrollmentIds)
          .eq('date', dateStr)
          .order('marked_at', ascending: false);

      return (response as List)
          .map((e) => AttendanceRecord.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get attendance error: $e');
      return [];
    }
  }

  /// Get attendance for a specific student across all subjects.
  Future<List<AttendanceRecord>> getStudentAttendance(String studentId) async {
    try {
      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('student_id', studentId);

      final enrollmentIds =
          (enrollments as List).map((e) => e['id'] as String).toList();

      if (enrollmentIds.isEmpty) return [];

      final response = await _client
          .from('attendance')
          .select('*, enrollments(*, students(*), subjects(*))')
          .inFilter('enrollment_id', enrollmentIds)
          .order('date', ascending: false);

      return (response as List)
          .map((e) => AttendanceRecord.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get student attendance error: $e');
      return [];
    }
  }

  /// Get today's total attendance count.
  Future<int> getTodayAttendanceCount() async {
    try {
      final today = DateTime.now();
      final dateStr = DateTime(today.year, today.month, today.day)
          .toIso8601String()
          .split('T')
          .first;

      final response = await _client
          .from('attendance')
          .select('id')
          .eq('date', dateStr)
          .neq('status', 'absent');

      return (response as List).length;
    } catch (e) {
      debugPrint('Get today attendance error: $e');
      return 0;
    }
  }

  /// Find enrollment by student USN and subject ID.
  Future<Enrollment?> findEnrollment(String studentUsn, String subjectId) async {
    try {
      final student = await getStudentByUsn(studentUsn);
      if (student == null || student.id == null) return null;

      final response = await _client
          .from('enrollments')
          .select('*, subjects(*, instructors(full_name))')
          .eq('student_id', student.id!)
          .eq('subject_id', subjectId)
          .maybeSingle();

      if (response == null) return null;
      return Enrollment.fromSupabase(response);
    } catch (e) {
      debugPrint('Find enrollment error: $e');
      return null;
    }
  }
}
