import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
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

/// Thrown when a QR scan happens outside the subject's valid schedule window.
class ScheduleValidationException implements Exception {
  final String message;
  const ScheduleValidationException(this.message);
  @override
  String toString() => message;
}

/// Maps a scheduleDay code to the list of Dart weekday integers (1=Mon … 7=Sun).
List<int> _scheduleDayToWeekdays(String scheduleDay) {
  final parts = scheduleDay.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
  final weekdays = <int>{};
  for (final part in parts) {
    switch (part.toUpperCase().trim()) {
      case 'MON': weekdays.add(DateTime.monday); break;
      case 'TUE': weekdays.add(DateTime.tuesday); break;
      case 'WED': weekdays.add(DateTime.wednesday); break;
      case 'THU': weekdays.add(DateTime.thursday); break;
      case 'FRI': weekdays.add(DateTime.friday); break;
      case 'SAT': weekdays.add(DateTime.saturday); break;
      case 'SUN': weekdays.add(DateTime.sunday); break;
      case 'MWF': weekdays.addAll([DateTime.monday, DateTime.wednesday, DateTime.friday]); break;
      case 'TTH': weekdays.addAll([DateTime.tuesday, DateTime.thursday]); break;
      case 'MTWTHF': weekdays.addAll([DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday]); break;
      default: break;
    }
  }
  return weekdays.toList();
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = SupabaseConfig.client;

  /// Expose client for advanced queries.
  SupabaseClient get client => _client;

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

  Future<bool> resetStudentPassword(String usn, String lastName, String newPassword) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('usn', usn.trim())
          .maybeSingle();

      if (response == null) return false;

      final storedLastName = (response['last_name'] as String).toLowerCase();
      if (storedLastName != lastName.trim().toLowerCase()) return false;

      await _client
          .from('students')
          .update({'password_hash': hashPassword(newPassword)})
          .eq('usn', usn.trim());

      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  Future<void> updateStudentPassword(String usn, String newPassword) async {
    try {
      await _client
          .from('students')
          .update({'password_hash': hashPassword(newPassword)})
          .eq('usn', usn.trim());
    } catch (e) {
      debugPrint('Update password error: $e');
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

      return (response as List).map((e) => Student.fromSupabase(e)).toList();
    } catch (e) {
      debugPrint('Get students error: $e');
      return [];
    }
  }

  /// Get students enrolled in an instructor's subjects.
  Future<List<Student>> getStudentsForInstructor(String instructorId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('students!inner(*), subjects!inner(instructor_id)')
          .eq('subjects.instructor_id', instructorId);

      final studentMaps = <String, Map<String, dynamic>>{};
      for (final item in (response as List)) {
        final sMap = item['students'] as Map<String, dynamic>?;
        if (sMap != null && sMap['id'] != null) {
          studentMaps[sMap['id'].toString()] = sMap;
        }
      }
      return studentMaps.values.map((e) => Student.fromSupabase(e)).toList();
    } catch (e) {
      debugPrint('Get students for instructor error: $e');
      return [];
    }
  }

  /// Get students enrolled in a specific subject.
  Future<List<Student>> getStudentsForSubject(String subjectId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('students!inner(*)')
          .eq('subject_id', subjectId);

      final studentMaps = <String, Map<String, dynamic>>{};
      for (final item in (response as List)) {
        final sMap = item['students'] as Map<String, dynamic>?;
        if (sMap != null && sMap['id'] != null) {
          studentMaps[sMap['id'].toString()] = sMap;
        }
      }
      final students = studentMaps.values.map((e) => Student.fromSupabase(e)).toList();
      students.sort((a, b) => a.lastName.compareTo(b.lastName));
      return students;
    } catch (e) {
      debugPrint('Get students for subject error: $e');
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

  // ── Token generation helper (public for provider use) ──
  String generateSessionToken() => _generateToken();

  // ═══════════════════════════════════════════════════
  // INSTRUCTORS
  // ═══════════════════════════════════════════════════

  Future<List<Instructor>> getInstructors() async {
    try {
      final response = await _client
          .from('instructors')
          .select()
          .order('full_name');

      return (response as List).map((e) => Instructor.fromSupabase(e)).toList();
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

  /// Fetches a single instructor by ID — always returns all columns including qr_token.
  Future<Instructor?> getInstructorById(String id) async {
    try {
      final response = await _client
          .from('instructors')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Get instructor by id error: $e');
      return null;
    }
  }

  // ── Super Admin: Register a new instructor ──────────────
  /// Creates an instructor record with a fresh one-time QR token.
  /// Returns the saved [Instructor] (including the generated token).
  Future<Instructor> registerInstructor({
    required String fullName,
    String? email,
    String? department,
    String? phone,
  }) async {
    // Generate a cryptographically-secure one-time QR token
    final token = _generateToken();

    // Only include columns that exist in the instructors table.
    // email / department / phone are stored locally in the model but are NOT
    // columns in the current Supabase schema — adding them causes PGRST204.
    final data = {
      'full_name': fullName.trim(),
      'qr_token': token,
      'qr_used': false,
      'is_active': true,
    };

    try {
      final response = await _client
          .from('instructors')
          .insert(data)
          .select()
          .single();
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Register instructor error: $e');
      rethrow;
    }
  }

  /// Looks up an instructor by their QR token.
  /// Returns null if not found or inactive.
  Future<Instructor?> getInstructorByQrToken(String token) async {
    try {
      final response = await _client
          .from('instructors')
          .select()
          .eq('qr_token', token.trim())
          .eq('is_active', true)
          .maybeSingle();
      if (response == null) {
        debugPrint('QR lookup: no match for token (may be inactive or RLS blocked)');
        return null;
      }
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Get instructor by QR error: $e');
      rethrow; // Surface to caller so auth failure shows real reason
    }
  }

  /// Stores a persistent session token upon QR login.
  Future<Instructor?> markQrTokenUsed(String instructorId, String sessionToken) async {
    try {
      final response = await _client
          .from('instructors')
          .update({
            'session_token': sessionToken,
          })
          .eq('id', instructorId)
          .select()
          .single();
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Mark QR used error: $e');
      rethrow;
    }
  }

  /// Validates a stored session token — returns the instructor if active.
  Future<Instructor?> validateSessionToken(String sessionToken) async {
    try {
      final response = await _client
          .from('instructors')
          .select()
          .eq('session_token', sessionToken.trim())
          .eq('is_active', true)
          .maybeSingle();
      if (response == null) return null;
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Validate session token error: $e');
      return null;
    }
  }

  /// Clears the session token on logout.
  Future<void> clearInstructorSession(String instructorId) async {
    try {
      await _client
          .from('instructors')
          .update({'session_token': null})
          .eq('id', instructorId);
    } catch (e) {
      debugPrint('Clear session error: $e');
    }
  }

  /// Deactivates an instructor (soft delete).
  Future<void> deactivateInstructor(String id) async {
    try {
      await _client
          .from('instructors')
          .update({'is_active': false, 'session_token': null})
          .eq('id', id);
    } catch (e) {
      debugPrint('Deactivate instructor error: $e');
      rethrow;
    }
  }

  /// Re-activates a previously deactivated instructor.
  Future<void> reactivateInstructor(String id) async {
    try {
      await _client
          .from('instructors')
          .update({'is_active': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Reactivate instructor error: $e');
      rethrow;
    }
  }

  /// Permanently deletes an instructor record.
  Future<void> deleteInstructor(String id) async {
    try {
      await _client
          .from('instructors')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Delete instructor error: $e');
      rethrow;
    }
  }

  /// Resets the QR token so the instructor can log in again.
  /// Clears the used flag and any existing session.
  Future<Instructor?> regenerateQrToken(String id) async {
    final newToken = _generateToken();
    try {
      final response = await _client
          .from('instructors')
          .update({
            'qr_token': newToken,
            'qr_used': false,
            'session_token': null,
          })
          .eq('id', id)
          .select()
          .single();
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Regenerate QR token error: $e');
      rethrow;
    }
  }

  /// Updates instructor profile info.
  Future<Instructor?> updateInstructor({
    required String id,
    String? fullName,
    String? email,
    String? department,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName.trim();
    if (email != null) data['email'] = email.trim();
    if (department != null) data['department'] = department.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (data.isEmpty) return null;

    try {
      final response = await _client
          .from('instructors')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Instructor.fromSupabase(response);
    } catch (e) {
      debugPrint('Update instructor error: $e');
      rethrow;
    }
  }

  // ── Token generation helper ──────────────────────────────
  String _generateToken() {
    // Use cryptographically-secure random bytes for a truly unique token
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
    String? themeColor,
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
        'instructor_id': instructorId.isEmpty ? null : instructorId,
        'late_threshold_minutes': lateThresholdMinutes,
        if (themeColor != null) 'theme_color': themeColor,
      };

      try {
        final response = await _client
            .from('subjects')
            .insert(data)
            .select('*, instructors(full_name)')
            .single();

        return Subject.fromSupabase(response);
      } catch (e) {
        if (data.containsKey('theme_color') &&
            (e.toString().contains('theme_color') || e.toString().contains('PGRST204'))) {
          data.remove('theme_color');
          final response = await _client
              .from('subjects')
              .insert(data)
              .select('*, instructors(full_name)')
              .single();
          return Subject.fromSupabase(response);
        }
        debugPrint('Create subject error: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Create subject error: $e');
      rethrow;
    }
  }

  Future<Subject?> updateSubject(
    String subjectId, {
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
      final data = <String, dynamic>{
        'subject_code': subjectCode.trim().toUpperCase(),
        'subject_title': subjectTitle.trim(),
        'units': units,
        'schedule_start_time': scheduleStartTime,
        'schedule_end_time': scheduleEndTime,
        'schedule_day': scheduleDay.trim().toUpperCase(),
        'room': room.trim(),
        'instructor_id': instructorId.isEmpty ? null : instructorId,
        'late_threshold_minutes': lateThresholdMinutes,
        if (themeColor != null) 'theme_color': themeColor,
      };

      try {
        final response = await _client
            .from('subjects')
            .update(data)
            .eq('id', subjectId)
            .select('*, instructors(full_name)')
            .single();

        return Subject.fromSupabase(response);
      } catch (e) {
        if (data.containsKey('theme_color') &&
            (e.toString().contains('theme_color') || e.toString().contains('PGRST204'))) {
          data.remove('theme_color');
          final response = await _client
              .from('subjects')
              .update(data)
              .eq('id', subjectId)
              .select('*, instructors(full_name)')
              .single();
          return Subject.fromSupabase(response);
        }
        debugPrint('Update subject error: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Update subject error: $e');
      rethrow;
    }
  }

  Future<List<Subject>> getSubjects({String? instructorId}) async {
    try {
      var query = _client
          .from('subjects')
          .select('*, instructors(full_name)');

      if (instructorId != null) {
        query = query.eq('instructor_id', instructorId);
      }

      final response = await query.order('subject_code');

      return (response as List).map((e) => Subject.fromSupabase(e)).toList();
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
          .insert({'student_id': studentId, 'subject_id': subjectId})
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

      return (response as List).map((e) => Enrollment.fromSupabase(e)).toList();
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

      return (response as List).map((e) => Enrollment.fromSupabase(e)).toList();
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

  /// Enroll a student by subject ID (used when student scans enrollment QR).
  /// Returns existing enrollment if already enrolled (no error).
  Future<Enrollment> enrollStudentBySubjectId(
    String studentId,
    String subjectId,
  ) async {
    try {
      final existing = await _client
          .from('enrollments')
          .select('*, subjects(*, instructors(full_name))')
          .eq('student_id', studentId)
          .eq('subject_id', subjectId)
          .maybeSingle();

      if (existing != null) return Enrollment.fromSupabase(existing);

      final response = await _client
          .from('enrollments')
          .insert({'student_id': studentId, 'subject_id': subjectId})
          .select('*, subjects(*, instructors(full_name))')
          .single();

      return Enrollment.fromSupabase(response);
    } catch (e) {
      debugPrint('Enroll by subject QR error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // ATTENDANCE — SMART MARKING
  // ═══════════════════════════════════════════════════

  /// Mark attendance for a student with smart late detection.
  /// Validates that the scan happens on the correct schedule day and within the
  /// allowed time window (30 min before start → end time).
  Future<AttendanceRecord?> markAttendance({
    required String enrollmentId,
    required Subject subject,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ── Schedule Validation ─── strict rejection ─────────────
      final slots = subject.scheduleSlots;
      final todaySlots = <ScheduleSlot>[];

      for (final slot in slots) {
        final slotDays = _scheduleDayToWeekdays(slot.day);
        if (slotDays.contains(now.weekday)) {
          todaySlots.add(slot);
        }
      }

      if (todaySlots.isEmpty) {
        const dayNames = [
          '',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        final todayName = dayNames[now.weekday];
        throw ScheduleValidationException(
          'No class today ($todayName). This subject is scheduled on ${subject.formattedSchedule}.',
        );
      }

      // ── Time Window Validation ────────────────────────────────────
      ScheduleSlot? activeSlot;
      DateTime? matchingStart;
      DateTime? matchingEnd;

      for (final slot in todaySlots) {
        final sParts = slot.startTime.split(':');
        final eParts = slot.endTime.split(':');
        final sHr = sParts.isNotEmpty ? (int.tryParse(sParts[0]) ?? 0) : 0;
        final sMin = sParts.length > 1 ? (int.tryParse(sParts[1]) ?? 0) : 0;
        final eHr = eParts.isNotEmpty ? (int.tryParse(eParts[0]) ?? 0) : 0;
        final eMin = eParts.length > 1 ? (int.tryParse(eParts[1]) ?? 0) : 0;

        final slotStart = DateTime(now.year, now.month, now.day, sHr, sMin);
        final slotEnd = DateTime(now.year, now.month, now.day, eHr, eMin);

        if (!now.isBefore(slotStart) && !now.isAfter(slotEnd)) {
          activeSlot = slot;
          matchingStart = slotStart;
          matchingEnd = slotEnd;
          break;
        }
      }

      if (activeSlot == null || matchingStart == null) {
        DateTime? earliestStart;
        DateTime? latestEnd;

        for (final slot in todaySlots) {
          final sParts = slot.startTime.split(':');
          final eParts = slot.endTime.split(':');
          final sHr = sParts.isNotEmpty ? (int.tryParse(sParts[0]) ?? 0) : 0;
          final sMin = sParts.length > 1 ? (int.tryParse(sParts[1]) ?? 0) : 0;
          final eHr = eParts.isNotEmpty ? (int.tryParse(eParts[0]) ?? 0) : 0;
          final eMin = eParts.length > 1 ? (int.tryParse(eParts[1]) ?? 0) : 0;

          final sDt = DateTime(now.year, now.month, now.day, sHr, sMin);
          final eDt = DateTime(now.year, now.month, now.day, eHr, eMin);

          if (earliestStart == null || sDt.isBefore(earliestStart)) earliestStart = sDt;
          if (latestEnd == null || eDt.isAfter(latestEnd)) latestEnd = eDt;
        }

        if (earliestStart != null && now.isBefore(earliestStart)) {
          final diff = earliestStart.difference(now).inMinutes;
          throw ScheduleValidationException(
            'Class hasn\'t started yet. Starts in $diff minute${diff == 1 ? '' : 's'}.',
          );
        }

        if (latestEnd != null && now.isAfter(latestEnd)) {
          throw ScheduleValidationException(
            'Class has already ended. Attendance can no longer be recorded.',
          );
        }

        matchingStart = subject.startTimeToday;
      }

      final startTime = matchingStart;

      // ── Duplicate Check ──────────────────────────────────────────
      final existing = await _client
          .from('attendance')
          .select()
          .eq('enrollment_id', enrollmentId)
          .eq('date', today.toIso8601String().split('T').first)
          .maybeSingle();

      if (existing != null) {
        return AttendanceRecord.fromSupabase(existing);
      }

      // ── Late vs Present (30-minute grace period) ─────────────────
      // Present: scanned within 30 minutes of class start
      // Late: more than 30 minutes after class start
      const lateGraceMinutes = 30;
      final lateThreshold = startTime.add(
        const Duration(minutes: lateGraceMinutes),
      );

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
        'scanned_at': now.toUtc().toIso8601String(),
        'minutes_late': minutesLate,
        'remarks': remarks,
      };

      final response = await _client
          .from('attendance')
          .insert(data)
          .select()
          .single();

      final record = AttendanceRecord.fromSupabase(response);

      // Auto-sync to grades
      await syncAttendanceToGrade(
        enrollmentId: enrollmentId,
        date: record.date,
      );

      return record;
    } on ScheduleValidationException {
      rethrow;
    } catch (e) {
      debugPrint('Mark attendance error: $e');
      rethrow;
    }
  }

  /// Mark all enrolled students who haven't scanned as absent.
  Future<int> markAbsentees(String subjectId) async {
    try {
      final today = DateTime.now();
      final dateStr = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String().split('T').first;

      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('subject_id', subjectId);

      int absentCount = 0;

      for (final enrollment in enrollments) {
        final enrollmentId = enrollment['id'] as String;

        final existing = await _client
            .from('attendance')
            .select('id')
            .eq('enrollment_id', enrollmentId)
            .eq('date', dateStr)
            .maybeSingle();

        if (existing == null) {
          await _client.from('attendance').insert({
            'enrollment_id': enrollmentId,
            'date': dateStr,
            'status': 'absent',
            'scanned_at': null,
            'minutes_late': 0,
            'remarks': 'Auto-absent (did not scan)',
          });

          // Auto-sync to grades
          await syncAttendanceToGrade(
            enrollmentId: enrollmentId,
            date: DateTime(today.year, today.month, today.day),
          );

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
    String subjectId, {
    DateTime? date,
  }) async {
    try {
      final dateStr = (date ?? DateTime.now())
          .toIso8601String()
          .split('T')
          .first;

      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('subject_id', subjectId);

      final enrollmentIds = (enrollments as List)
          .map((e) => e['id'] as String)
          .toList();

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

      final enrollmentIds = (enrollments as List)
          .map((e) => e['id'] as String)
          .toList();

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

  /// Get today's total attendance count (optionally filtered by instructor).
  Future<int> getTodayAttendanceCount({String? instructorId}) async {
    try {
      final today = DateTime.now();
      final dateStr = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String().split('T').first;

      var query = _client
          .from('attendance')
          .select('id, enrollments!inner(subjects!inner(instructor_id))')
          .eq('date', dateStr)
          .neq('status', 'absent');

      if (instructorId != null) {
        query = query.eq('enrollments.subjects.instructor_id', instructorId);
      }

      final response = await query;

      return (response as List).length;
    } catch (e) {
      debugPrint('Get today attendance error: $e');
      return 0;
    }
  }

  /// Find enrollment by student USN and subject ID.
  Future<Enrollment?> findEnrollment(
    String studentUsn,
    String subjectId,
  ) async {
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

  // ═══════════════════════════════════════════════════
  // ATTENDANCE — ADMIN EDIT
  // ═══════════════════════════════════════════════════

  /// Admin manually updates an attendance record's status.
  Future<void> updateAttendanceStatus(
    String attendanceId,
    String newStatus, {
    String? remarks,
  }) async {
    try {
      final data = <String, dynamic>{'status': newStatus};
      if (remarks != null) data['remarks'] = remarks;
      await _client.from('attendance').update(data).eq('id', attendanceId);

      // Fetch to get enrollment_id and date for syncing
      final existing = await _client
          .from('attendance')
          .select('enrollment_id, date')
          .eq('id', attendanceId)
          .maybeSingle();

      if (existing != null) {
        final enrollmentId = existing['enrollment_id'] as String;
        final date =
            DateTime.tryParse(existing['date'] as String) ?? DateTime.now();
        await syncAttendanceToGrade(enrollmentId: enrollmentId, date: date);
      }
    } catch (e) {
      debugPrint('Update attendance status error: $e');
      rethrow;
    }
  }

  /// Admin manually creates an attendance record for a student who has no entry.
  Future<AttendanceRecord?> createManualAttendance({
    required String enrollmentId,
    required String status,
    required DateTime date,
    String? remarks,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final existing = await _client
          .from('attendance')
          .select()
          .eq('enrollment_id', enrollmentId)
          .eq('date', dateStr)
          .maybeSingle();
      if (existing != null) {
        await updateAttendanceStatus(existing['id'], status, remarks: remarks);
        final updated = await _client
            .from('attendance')
            .select('*, enrollments(*, students(*), subjects(*))')
            .eq('id', existing['id'])
            .single();
        final record = AttendanceRecord.fromSupabase(updated);
        // Sync is already handled by updateAttendanceStatus
        return record;
      }
      final response = await _client
          .from('attendance')
          .insert({
            'enrollment_id': enrollmentId,
            'date': dateStr,
            'status': status,
            'minutes_late': 0,
            'remarks': remarks ?? 'Manually recorded',
          })
          .select('*, enrollments(*, students(*), subjects(*))')
          .single();

      final record = AttendanceRecord.fromSupabase(response);

      // Auto-sync to grades
      await syncAttendanceToGrade(
        enrollmentId: record.enrollmentId,
        date: record.date,
      );

      return record;
    } catch (e) {
      debugPrint('Create manual attendance error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // ATTENDANCE — FULL ROSTER (for spreadsheet tracker)
  // ═══════════════════════════════════════════════════

  /// Returns ALL enrolled students for a subject with their attendance record
  /// for [date] (or null if they haven't been marked yet).
  Future<List<RosterEntry>> getSubjectRoster(
    String subjectId, {
    DateTime? date,
  }) async {
    try {
      final dateStr = (date ?? DateTime.now())
          .toIso8601String()
          .split('T')
          .first;

      final enrollments = await _client
          .from('enrollments')
          .select('*, students(*)')
          .eq('subject_id', subjectId);

      final List<RosterEntry> roster = [];

      for (final e in (enrollments as List)) {
        final enrollmentId = e['id'] as String;
        final studentMap = e['students'] as Map<String, dynamic>?;

        final attMap = await _client
            .from('attendance')
            .select()
            .eq('enrollment_id', enrollmentId)
            .eq('date', dateStr)
            .maybeSingle();

        AttendanceRecord? record;
        if (attMap != null) {
          final merged = {
            ...attMap,
            'enrollments': {
              'id': enrollmentId,
              'students': studentMap,
              'subjects': null,
            },
          };
          record = AttendanceRecord.fromSupabase(merged);
        }

        roster.add(
          RosterEntry(
            enrollmentId: enrollmentId,
            studentId: studentMap?['id'] ?? '',
            lastName: studentMap?['last_name'] ?? '',
            firstName: studentMap?['first_name'] ?? '',
            usn: studentMap?['usn'] ?? '',
            course: studentMap?['course'] ?? '',
            yearLevel: studentMap?['year_level'] ?? '',
            section: studentMap?['section'] ?? '',
            attendanceRecord: record,
          ),
        );
      }

      roster.sort((a, b) {
        final last = a.lastName.compareTo(b.lastName);
        return last != 0 ? last : a.firstName.compareTo(b.firstName);
      });

      return roster;
    } catch (e) {
      debugPrint('Get subject roster error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // GRADE CAPTURES
  // ═══════════════════════════════════════════════════

  /// Upload a file to Supabase Storage and return the public URL.
  Future<String> uploadGradeCaptureFile(File file, String fileName) async {
    final bucket = _client.storage.from('grade-captures');
    await bucket.upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return bucket.getPublicUrl(fileName);
  }

  /// Insert a grade capture record into the DB.
  Future<GradeCapture?> createGradeCapture({
    required String fileUrl,
    required String fileType,
    String? studentNote,
    String? subjectId,
    String? studentName,
    String? section,
  }) async {
    final data = GradeCapture(
      fileUrl: fileUrl,
      fileType: fileType,
      studentNote: studentNote,
      subjectId: subjectId,
      studentName: studentName,
      section: section,
    ).toSupabase();

    final res = await _client
        .from('grade_captures')
        .insert(data)
        .select('*, subjects(subject_code)')
        .single();
    return GradeCapture.fromSupabase(res);
  }

  /// Fetch grade captures, optionally filtered by subject.
  Future<List<GradeCapture>> getGradeCaptures({String? subjectId}) async {
    var query = _client
        .from('grade_captures')
        .select('*, subjects(subject_code)');
    if (subjectId != null && subjectId.isNotEmpty) {
      query = query.eq('subject_id', subjectId);
    }
    final res = await query.order('captured_at', ascending: false);
    return (res as List).map((e) => GradeCapture.fromSupabase(e)).toList();
  }

  /// Delete a grade capture — removes from DB and Storage.
  Future<void> deleteGradeCapture(String id, String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      // URL format: .../storage/v1/object/public/grade-captures/<fileName>
      final bucketIdx = segments.indexOf('grade-captures');
      if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
        final filePath = segments.sublist(bucketIdx + 1).join('/');
        await _client.storage.from('grade-captures').remove([filePath]);
      }
    } catch (e) {
      debugPrint('Storage delete warning: $e');
    }
    await _client.from('grade_captures').delete().eq('id', id);
  }

  /// Delete all expired captures (expires_at < now).
  Future<int> cleanupExpiredCaptures() async {
    final now = DateTime.now().toIso8601String();
    final expired = await _client
        .from('grade_captures')
        .select('id, file_url')
        .lt('expires_at', now);

    if ((expired as List).isEmpty) return 0;

    for (final rec in expired) {
      try {
        final uri = Uri.parse(rec['file_url'] ?? '');
        final segments = uri.pathSegments;
        final bucketIdx = segments.indexOf('grade-captures');
        if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
          final filePath = segments.sublist(bucketIdx + 1).join('/');
          await _client.storage.from('grade-captures').remove([filePath]);
        }
      } catch (_) {}
    }

    await _client.from('grade_captures').delete().lt('expires_at', now);
    return expired.length;
  }

  // ═══════════════════════════════════════════════════
  // STUDENT PROFILE IMAGE
  // ═══════════════════════════════════════════════════

  /// Uploads a profile image to Supabase Storage and updates the student record.
  /// Returns the public URL of the uploaded image.
  Future<String> uploadStudentProfileImage(
    String studentId,
    Uint8List imageBytes,
    String extension,
  ) async {
    String url;
    try {
      final bucket = _client.storage.from('student-profiles');
      final fileName = '$studentId.$extension';
      await bucket.uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      final rawUrl = bucket.getPublicUrl(fileName);
      url = '$rawUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Storage upload fallback to base64 data URI: $e');
      final base64Str = base64Encode(imageBytes);
      final mime = extension == 'png' ? 'image/png' : 'image/jpeg';
      url = 'data:$mime;base64,$base64Str';
    }

    // Update the student record
    await _client
        .from('students')
        .update({'profile_image_url': url})
        .eq('id', studentId);
    return url;
  }

  /// Deletes a student profile image from Supabase Storage and clears the DB URL.
  Future<void> deleteStudentProfileImage(
    String studentId,
    String fileUrl,
  ) async {
    try {
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf('student-profiles');
      if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
        final filePath = segments.sublist(bucketIdx + 1).join('/');
        await _client.storage.from('student-profiles').remove([filePath]);
      }
      await _client
          .from('students')
          .update({'profile_image_url': null})
          .eq('id', studentId);
    } catch (e) {
      debugPrint('Delete profile image error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // CLASS CANCELLATIONS
  // ═══════════════════════════════════════════════════

  /// Mark a class day as cancelled (no_class / holiday / suspended).
  /// - Creates a record in `class_cancellations`.
  /// - Bulk-updates all enrolled students' attendance for that date to [reason].
  Future<ClassCancellation?> markClassCancelled({
    required String subjectId,
    required DateTime date,
    required String reason, // 'no_class', 'holiday', 'suspended'
    String? remarks,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      // Check if already cancelled
      final existing = await _client
          .from('class_cancellations')
          .select()
          .eq('subject_id', subjectId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existing != null) {
        // Update reason
        await _client
            .from('class_cancellations')
            .update({'reason': reason, 'remarks': remarks})
            .eq('id', existing['id']);
      } else {
        await _client.from('class_cancellations').insert({
          'subject_id': subjectId,
          'date': dateStr,
          'reason': reason,
          'remarks': remarks,
        });
      }

      // Update all attendance records for this subject+date to the cancelled status
      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('subject_id', subjectId);

      for (final enrollment in (enrollments as List)) {
        final enrollmentId = enrollment['id'] as String;
        final attRec = await _client
            .from('attendance')
            .select('id')
            .eq('enrollment_id', enrollmentId)
            .eq('date', dateStr)
            .maybeSingle();

        final reasonLabel = reason == 'no_class'
            ? 'No Class — Instructor Leave'
            : reason == 'holiday'
            ? 'Holiday'
            : 'Class Suspended';
        final remarkStr = remarks ?? reasonLabel;

        if (attRec != null) {
          await _client
              .from('attendance')
              .update({'status': reason, 'remarks': remarkStr})
              .eq('id', attRec['id']);
        } else {
          await _client.from('attendance').insert({
            'enrollment_id': enrollmentId,
            'date': dateStr,
            'status': reason,
            'scanned_at': null,
            'minutes_late': 0,
            'remarks': remarkStr,
          });
        }
      }

      // Fetch and return the cancellation record
      final cancellation = await _client
          .from('class_cancellations')
          .select()
          .eq('subject_id', subjectId)
          .eq('date', dateStr)
          .single();

      return ClassCancellation.fromMap(cancellation);
    } catch (e) {
      debugPrint('Mark class cancelled error: $e');
      rethrow;
    }
  }

  /// Restore a cancelled class day — removes the cancellation record and
  /// deletes the bulk-inserted attendance entries so the day is "clean" again.
  Future<void> restoreClassDay({
    required String subjectId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      // Delete the cancellation record
      await _client
          .from('class_cancellations')
          .delete()
          .eq('subject_id', subjectId)
          .eq('date', dateStr);

      // Delete all attendance records for this date that have a cancelled status
      final enrollments = await _client
          .from('enrollments')
          .select('id')
          .eq('subject_id', subjectId);

      for (final enrollment in (enrollments as List)) {
        final enrollmentId = enrollment['id'] as String;
        await _client
            .from('attendance')
            .delete()
            .eq('enrollment_id', enrollmentId)
            .eq('date', dateStr)
            .inFilter('status', ['no_class', 'holiday', 'suspended']);
      }
    } catch (e) {
      debugPrint('Restore class day error: $e');
      rethrow;
    }
  }

  /// Get all class cancellations for a subject.
  Future<List<ClassCancellation>> getCancellationsForSubject(
    String subjectId,
  ) async {
    try {
      final response = await _client
          .from('class_cancellations')
          .select()
          .eq('subject_id', subjectId)
          .order('date', ascending: false);

      return (response as List)
          .map((e) => ClassCancellation.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('Get cancellations error: $e');
      return [];
    }
  }

  /// Check if a specific date is cancelled for a subject.
  Future<ClassCancellation?> getCancellationForDate(
    String subjectId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final response = await _client
          .from('class_cancellations')
          .select()
          .eq('subject_id', subjectId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return ClassCancellation.fromMap(response);
    } catch (e) {
      debugPrint('Get cancellation for date error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════
  // LEARNING MODULES (Google Drive metadata)
  // ═══════════════════════════════════════════════════

  /// Fetch all learning modules, optionally filtered by subject.
  Future<List<LearningModule>> getModules({String? subject}) async {
    try {
      var query = _client.from('modules').select();
      if (subject != null && subject.isNotEmpty) {
        query = query.eq('subject', subject);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => LearningModule.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get modules error: $e');
      return [];
    }
  }

  /// Create a new learning module.
  Future<LearningModule?> createModule(LearningModule module) async {
    try {
      final response = await _client
          .from('modules')
          .insert(module.toSupabase())
          .select()
          .single();
      return LearningModule.fromSupabase(response);
    } catch (e) {
      debugPrint('Create module error: $e');
      rethrow;
    }
  }

  /// Update an existing learning module.
  Future<LearningModule?> updateModule(LearningModule module) async {
    try {
      final response = await _client
          .from('modules')
          .update(module.toSupabase())
          .eq('id', module.id!)
          .select()
          .single();
      return LearningModule.fromSupabase(response);
    } catch (e) {
      debugPrint('Update module error: $e');
      rethrow;
    }
  }

  /// Delete a learning module by ID.
  Future<void> deleteModule(String id) async {
    try {
      await _client.from('modules').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete module error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // GRADING CONFIG
  // ═══════════════════════════════════════════════════

  /// Fetch grading config for a subject, or null if not yet configured.
  Future<GradingConfig?> getGradingConfig(String subjectId) async {
    try {
      final response = await _client
          .from('subject_grading_config')
          .select()
          .eq('subject_id', subjectId)
          .maybeSingle();
      if (response == null) return null;
      return GradingConfig.fromSupabase(response);
    } catch (e) {
      debugPrint('Get grading config error: $e');
      return null;
    }
  }

  /// Upsert (insert or update) a grading config for a subject.
  Future<GradingConfig?> saveGradingConfig(GradingConfig config) async {
    try {
      final data = config.toSupabase();
      if (config.id != null) {
        // Update existing
        final response = await _client
            .from('subject_grading_config')
            .update({...data, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', config.id!)
            .select()
            .single();
        return GradingConfig.fromSupabase(response);
      } else {
        // Insert new (upsert on subject_id)
        final response = await _client
            .from('subject_grading_config')
            .upsert(data, onConflict: 'subject_id')
            .select()
            .single();
        return GradingConfig.fromSupabase(response);
      }
    } catch (e) {
      debugPrint('Save grading config error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT GRADES
  // ═══════════════════════════════════════════════════

  /// Get all grade records for a subject (all students × all terms).
  /// Joins through enrollments to get student info.
  Future<List<StudentGrade>> getSubjectGrades(String subjectId) async {
    try {
      final grades = await _client
          .from('student_grades')
          .select('*, enrollments!inner(*, students(*))')
          .eq('enrollments.subject_id', subjectId)
          .order('term');

      return (grades as List).map((e) => StudentGrade.fromSupabase(e)).toList();
    } catch (e) {
      debugPrint('Get subject grades error: $e');
      return [];
    }
  }

  /// Upsert a single student grade record.
  Future<StudentGrade?> upsertStudentGrade(StudentGrade grade) async {
    try {
      final data = grade.toSupabase();
      if (grade.id != null) {
        final response = await _client
            .from('student_grades')
            .update(data)
            .eq('id', grade.id!)
            .select('*, enrollments(*, students(*))')
            .single();
        return StudentGrade.fromSupabase(response);
      } else {
        final response = await _client
            .from('student_grades')
            .upsert(data, onConflict: 'enrollment_id,term')
            .select('*, enrollments(*, students(*))')
            .single();
        return StudentGrade.fromSupabase(response);
      }
    } catch (e) {
      debugPrint('Upsert student grade error: $e');
      rethrow;
    }
  }

  /// Get a flat list of enrollments for a subject (for building grade table).
  Future<List<Map<String, dynamic>>> getSubjectEnrollmentRoster(
    String subjectId,
  ) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('id, students(*)')
          .eq('subject_id', subjectId);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Get enrollment roster error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // ASSESSMENTS CRUD (admin creates quizzes/exams)
  // ═══════════════════════════════════════════════════

  Future<AssessmentConfig?> createAssessment(AssessmentConfig config) async {
    try {
      final data = config.toSupabase();
      try {
        final response = await _client
            .from('assessments')
            .insert(data)
            .select()
            .single();
        return AssessmentConfig.fromSupabase(response);
      } catch (e) {
        if (data.containsKey('theme_color') &&
            (e.toString().contains('theme_color') || e.toString().contains('PGRST204'))) {
          data.remove('theme_color');
          final response = await _client
              .from('assessments')
              .insert(data)
              .select()
              .single();
          return AssessmentConfig.fromSupabase(response);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Create assessment error: $e');
      rethrow;
    }
  }

  Future<AssessmentConfig?> updateAssessment(AssessmentConfig config) async {
    try {
      final data = config.toSupabase();
      data['updated_at'] = DateTime.now().toIso8601String();
      try {
        final response = await _client
            .from('assessments')
            .update(data)
            .eq('id', config.id!)
            .select()
            .single();
        return AssessmentConfig.fromSupabase(response);
      } catch (e) {
        if (data.containsKey('theme_color') &&
            (e.toString().contains('theme_color') || e.toString().contains('PGRST204'))) {
          data.remove('theme_color');
          final response = await _client
              .from('assessments')
              .update(data)
              .eq('id', config.id!)
              .select()
              .single();
          return AssessmentConfig.fromSupabase(response);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Update assessment error: $e');
      rethrow;
    }
  }

  Future<void> deleteAssessment(String id) async {
    try {
      await _client.from('assessments').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete assessment error: $e');
      rethrow;
    }
  }

  Future<List<AssessmentConfig>> getAssessmentsForSubject(
    String subjectId,
  ) async {
    try {
      final response = await _client
          .from('assessments')
          .select()
          .eq('subject_id', subjectId)
          .order('term')
          .order('type')
          .order('created_at');
      return (response as List)
          .map((e) => AssessmentConfig.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get assessments error: $e');
      return [];
    }
  }

  Future<List<AssessmentConfig>> getPublishedAssessments(
    String subjectId,
  ) async {
    try {
      final response = await _client
          .from('assessments')
          .select()
          .eq('subject_id', subjectId)
          .eq('is_published', true)
          .order('term')
          .order('type');
      return (response as List)
          .map((e) => AssessmentConfig.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get published assessments error: $e');
      return [];
    }
  }

  Future<void> publishAssessment(String id, bool publish) async {
    try {
      await _client
          .from('assessments')
          .update({
            'is_published': publish,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('Publish assessment error: $e');
      rethrow;
    }
  }

  Future<String> generateSessionCode(String assessmentId) async {
    try {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final code = List.generate(4, (_) {
        final idx = DateTime.now().microsecond % chars.length;
        return chars[idx];
      }).join();
      await _client
          .from('assessments')
          .update({'session_code': code})
          .eq('id', assessmentId);
      return code;
    } catch (e) {
      debugPrint('Generate session code error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // ASSESSMENT QUESTIONS CRUD
  // ═══════════════════════════════════════════════════

  Future<AssessmentQuestion?> addQuestion(AssessmentQuestion question) async {
    try {
      final response = await _client
          .from('assessment_questions')
          .insert(question.toSupabase())
          .select()
          .single();
      return AssessmentQuestion.fromSupabase(response);
    } catch (e) {
      debugPrint('Add question error: $e');
      rethrow;
    }
  }

  Future<AssessmentQuestion?> updateQuestion(
    AssessmentQuestion question,
  ) async {
    try {
      final response = await _client
          .from('assessment_questions')
          .update(question.toSupabase())
          .eq('id', question.id!)
          .select()
          .single();
      return AssessmentQuestion.fromSupabase(response);
    } catch (e) {
      debugPrint('Update question error: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(String id) async {
    try {
      await _client.from('assessment_questions').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete question error: $e');
      rethrow;
    }
  }

  Future<List<AssessmentQuestion>> getQuestions(String assessmentId) async {
    try {
      final response = await _client
          .from('assessment_questions')
          .select()
          .eq('assessment_id', assessmentId)
          .order('question_order');
      return (response as List)
          .map((e) => AssessmentQuestion.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get questions error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT SUBMISSIONS
  // ═══════════════════════════════════════════════════

  Future<AssessmentSubmission?> submitAssessment(
    AssessmentSubmission submission,
    List<AssessmentAnswer> answers,
  ) async {
    try {
      // Insert submission
      final subRes = await _client
          .from('assessment_submissions')
          .insert(submission.toSupabase())
          .select()
          .single();

      final submissionId = subRes['id'] as String;

      // Insert all answers
      if (answers.isNotEmpty) {
        final answerData = answers
            .map(
              (a) => AssessmentAnswer(
                submissionId: submissionId,
                questionId: a.questionId,
                studentAnswer: a.studentAnswer,
                isCorrect: a.isCorrect,
                pointsEarned: a.pointsEarned,
              ).toSupabase(),
            )
            .toList();
        await _client.from('assessment_answers').insert(answerData);
      }

      // Auto-record the score to grades
      await autoRecordAssessmentToGrade(
        assessmentId: submission.assessmentId,
        studentId: submission.studentId,
        score: submission.score,
        maxScore: submission.maxScore,
      );

      return AssessmentSubmission.fromSupabase(subRes);
    } catch (e) {
      debugPrint('Submit assessment error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // APPEAL SYSTEM
  // ═══════════════════════════════════════════════════

  /// Student files an appeal for an invalidated submission.
  Future<void> submitAppeal(String submissionId, String reason) async {
    try {
      await _client
          .from('assessment_submissions')
          .update({
            'appeal_status': 'pending',
            'appeal_reason': reason,
          })
          .eq('id', submissionId);
    } catch (e) {
      debugPrint('Submit appeal error: $e');
      rethrow;
    }
  }

  /// Admin: Get all pending appeals (with student and assessment info).
  Future<List<AssessmentSubmission>> getPendingAppeals() async {
    try {
      final res = await _client
          .from('assessment_submissions')
          .select('*, students(*), assessments(*)')
          .eq('is_invalidated', true)
          .eq('appeal_status', 'pending')
          .order('submitted_at', ascending: false);

      return (res as List).map((m) => AssessmentSubmission.fromSupabase(m)).toList();
    } catch (e) {
      debugPrint('Get pending appeals error: $e');
      return [];
    }
  }

  /// Admin: Approve appeal — deletes the submission + answers so the student can retake.
  Future<void> approveAppeal(String submissionId) async {
    try {
      // Delete answers first (FK constraint)
      await _client
          .from('assessment_answers')
          .delete()
          .eq('submission_id', submissionId);

      // Delete the submission itself
      await _client
          .from('assessment_submissions')
          .delete()
          .eq('id', submissionId);
    } catch (e) {
      debugPrint('Approve appeal error: $e');
      rethrow;
    }
  }

  /// Admin: Reject appeal
  Future<void> rejectAppeal(String submissionId) async {
    try {
      await _client
          .from('assessment_submissions')
          .update({'appeal_status': 'rejected'})
          .eq('id', submissionId);
    } catch (e) {
      debugPrint('Reject appeal error: $e');
      rethrow;
    }
  }

  /// Automatically records an assessment score to the student's grades.
  Future<void> autoRecordAssessmentToGrade({
    required String assessmentId,
    required String studentId,
    required double score,
    required double maxScore,
  }) async {
    try {
      // 1. Get the assessment to know subject + term + type
      final assessmentMap = await _client
          .from('assessments')
          .select()
          .eq('id', assessmentId)
          .maybeSingle();
      if (assessmentMap == null) return;
      final assessment = AssessmentConfig.fromSupabase(assessmentMap);

      // 2. Find enrollment
      final enrollmentMap = await _client
          .from('enrollments')
          .select('id')
          .eq('student_id', studentId)
          .eq('subject_id', assessment.subjectId)
          .maybeSingle();
      if (enrollmentMap == null) return;

      final enrollmentId = enrollmentMap['id'] as String;

      // 3. Find or create StudentGrade for this enrollment + term
      var gradeMap = await _client
          .from('student_grades')
          .select('id')
          .eq('enrollment_id', enrollmentId)
          .eq('term', assessment.term)
          .maybeSingle();

      String gradeId;
      if (gradeMap != null) {
        gradeId = gradeMap['id'] as String;
      } else {
        final newGrade = await _client
            .from('student_grades')
            .insert({'enrollment_id': enrollmentId, 'term': assessment.term})
            .select()
            .single();
        gradeId = newGrade['id'] as String;
      }

      // 4. Check if a grade item for this assessment already exists
      final existingItem = await _client
          .from('student_grade_items')
          .select('id')
          .eq('grade_id', gradeId)
          .eq('assessment_id', assessmentId)
          .maybeSingle();

      final category = assessment.isExam ? 'exam' : 'quiz';
      if (existingItem != null) {
        // Update existing
        await _client
            .from('student_grade_items')
            .update({'score': score, 'max_score': maxScore})
            .eq('id', existingItem['id']);
      } else {
        // Create new
        await _client.from('student_grade_items').insert({
          'grade_id': gradeId,
          'category': category,
          'label': assessment.title,
          'score': score,
          'max_score': maxScore,
          'source': 'auto', // Auto-recorded from submission
          'assessment_id': assessmentId,
        });
      }

      // 5. Recalculate grade totals
      await recalculateGradeTotals(gradeId);

      // 6. Mark submission as graded (if not already)
      await _client
          .from('assessment_submissions')
          .update({'is_graded': true})
          .eq('assessment_id', assessmentId)
          .eq('student_id', studentId);
    } catch (e) {
      debugPrint('Auto record assessment to grade error: $e');
    }
  }

  Future<bool> hasStudentSubmitted(
    String assessmentId,
    String studentId,
  ) async {
    try {
      final response = await _client
          .from('assessment_submissions')
          .select('id')
          .eq('assessment_id', assessmentId)
          .eq('student_id', studentId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Check submission error: $e');
      return false;
    }
  }

  Future<List<AssessmentSubmission>> getSubmissionsForAssessment(
    String assessmentId,
  ) async {
    try {
      final response = await _client
          .from('assessment_submissions')
          .select('*, students(usn, last_name, first_name)')
          .eq('assessment_id', assessmentId)
          .order('submitted_at', ascending: false);
      return (response as List)
          .map((e) => AssessmentSubmission.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get submissions error: $e');
      return [];
    }
  }

  Future<List<AssessmentSubmission>> getStudentSubmissions(
    String studentId,
    String subjectId,
  ) async {
    try {
      // Get all assessment IDs for this subject
      final assessments = await _client
          .from('assessments')
          .select('id')
          .eq('subject_id', subjectId);
      final ids = (assessments as List).map((e) => e['id'] as String).toList();
      if (ids.isEmpty) return [];

      final response = await _client
          .from('assessment_submissions')
          .select('*, assessments(title, term, type)')
          .eq('student_id', studentId)
          .inFilter('assessment_id', ids)
          .order('submitted_at', ascending: false);
      return (response as List)
          .map((e) => AssessmentSubmission.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get student submissions error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // QR → GRADE PIPELINE
  // ═══════════════════════════════════════════════════

  /// Process a scanned grade QR code.
  /// QR format: STIMSYS_GRADE|assessmentId|studentId|score|maxScore|timestamp
  ///
  /// Steps:
  /// 1. Parse the QR data
  /// 2. Find the assessment → subject → enrollment
  /// 3. Find or create the StudentGrade record for that enrollment+term
  /// 4. Create a StudentGradeItem for the quiz/exam score
  /// 5. Recalculate the grade totals
  /// 6. Mark submission as graded
  ///
  /// Returns (success, message).
  Future<(bool, String)> processGradeQR(String qrData) async {
    try {
      final parts = qrData.split('|');
      if (parts.length < 6 || parts[0] != 'STIMSYS_GRADE') {
        return (
          false,
          'Invalid QR format. Expected 6 parts, got ${parts.length}',
        );
      }

      final assessmentId = parts[1];
      final studentId = parts[2];
      final score = double.tryParse(parts[3]) ?? 0;
      final maxScore = double.tryParse(parts[4]) ?? 0;

      // 1. Get the assessment to know subject + term + type
      final assessmentMap = await _client
          .from('assessments')
          .select()
          .eq('id', assessmentId)
          .maybeSingle();
      if (assessmentMap == null) return (false, 'Assessment not found');
      final assessment = AssessmentConfig.fromSupabase(assessmentMap);

      // 2. Find enrollment
      final enrollmentMap = await _client
          .from('enrollments')
          .select('id')
          .eq('student_id', studentId)
          .eq('subject_id', assessment.subjectId)
          .maybeSingle();
      if (enrollmentMap == null) {
        return (false, 'Student not enrolled in this subject');
      }
      final enrollmentId = enrollmentMap['id'] as String;

      // 3. Find or create StudentGrade for this enrollment + term
      var gradeMap = await _client
          .from('student_grades')
          .select()
          .eq('enrollment_id', enrollmentId)
          .eq('term', assessment.term)
          .maybeSingle();

      String gradeId;
      if (gradeMap != null) {
        gradeId = gradeMap['id'] as String;
      } else {
        final newGrade = await _client
            .from('student_grades')
            .insert({'enrollment_id': enrollmentId, 'term': assessment.term})
            .select()
            .single();
        gradeId = newGrade['id'] as String;
      }

      // 4. Check if a grade item for this assessment already exists
      final existingItem = await _client
          .from('student_grade_items')
          .select()
          .eq('grade_id', gradeId)
          .eq('assessment_id', assessmentId)
          .maybeSingle();

      final category = assessment.isExam ? 'exam' : 'quiz';
      if (existingItem != null) {
        // Update existing
        await _client
            .from('student_grade_items')
            .update({'score': score, 'max_score': maxScore})
            .eq('id', existingItem['id']);
      } else {
        // Create new
        await _client.from('student_grade_items').insert({
          'grade_id': gradeId,
          'category': category,
          'label': assessment.title,
          'score': score,
          'max_score': maxScore,
          'source': 'assessment_qr',
          'assessment_id': assessmentId,
        });
      }

      // 5. Recalculate grade totals
      await recalculateGradeTotals(gradeId);

      // 6. Mark submission as graded
      await _client
          .from('assessment_submissions')
          .update({'is_graded': true})
          .eq('assessment_id', assessmentId)
          .eq('student_id', studentId);

      return (
        true,
        '${assessment.title} — Score: ${score.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)} recorded',
      );
    } catch (e) {
      debugPrint('Process grade QR error: $e');
      return (false, 'Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT GRADE ITEMS CRUD
  // ═══════════════════════════════════════════════════

  Future<List<StudentGradeItem>> getGradeItems(String gradeId) async {
    try {
      final response = await _client
          .from('student_grade_items')
          .select()
          .eq('grade_id', gradeId)
          .order('created_at');
      return (response as List)
          .map((e) => StudentGradeItem.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get grade items error: $e');
      return [];
    }
  }

  Future<StudentGradeItem?> upsertGradeItem(StudentGradeItem item) async {
    try {
      if (item.id != null) {
        final response = await _client
            .from('student_grade_items')
            .update(item.toSupabase())
            .eq('id', item.id!)
            .select()
            .single();
        return StudentGradeItem.fromSupabase(response);
      } else {
        final response = await _client
            .from('student_grade_items')
            .insert(item.toSupabase())
            .select()
            .single();
        return StudentGradeItem.fromSupabase(response);
      }
    } catch (e) {
      debugPrint('Upsert grade item error: $e');
      rethrow;
    }
  }

  Future<void> deleteGradeItem(String id) async {
    try {
      await _client.from('student_grade_items').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete grade item error: $e');
      rethrow;
    }
  }

  Future<void> deleteGradeItemsByLabelAndCategory({
    required List<String> gradeIds,
    required String category,
    required String label,
  }) async {
    try {
      if (gradeIds.isEmpty) return;
      await _client
          .from('student_grade_items')
          .delete()
          .inFilter('grade_id', gradeIds)
          .eq('category', category)
          .eq('label', label);

      for (final gid in gradeIds) {
        await recalculateGradeTotals(gid);
      }
    } catch (e) {
      debugPrint('Delete grade items by label and category error: $e');
      rethrow;
    }
  }

  /// Recalculate quiz_raw/quiz_max and exam_raw/exam_max from grade items.
  Future<void> recalculateGradeTotals(String gradeId) async {
    try {
      final items = await getGradeItems(gradeId);

      double quizRaw = 0, quizMax = 0, examRaw = 0, examMax = 0;
      for (final item in items) {
        if (item.category == 'quiz' || item.category == 'activity') {
          quizRaw += item.score;
          quizMax += item.maxScore;
        } else if (item.category == 'exam') {
          examRaw += item.score;
          examMax += item.maxScore;
        }
      }

      // Get the existing grade to preserve attendance + compute grade
      final gradeMap = await _client
          .from('student_grades')
          .select()
          .eq('id', gradeId)
          .single();
      final attendRaw = (gradeMap['attendance_raw'] as num?)?.toDouble() ?? 0;
      final attendMax = (gradeMap['attendance_max'] as num?)?.toDouble() ?? 0;

      // Get grading config to compute grade
      final enrollmentId = gradeMap['enrollment_id'] as String;
      final enrollment = await _client
          .from('enrollments')
          .select('subject_id')
          .eq('id', enrollmentId)
          .single();
      final subjectId = enrollment['subject_id'] as String;
      final configMap = await _client
          .from('subject_grading_config')
          .select()
          .eq('subject_id', subjectId)
          .maybeSingle();

      double? computedGrade;
      if (configMap != null) {
        final config = GradingConfig.fromSupabase(configMap);
        if (examMax > 0 && quizMax > 0 && attendMax > 0) {
          computedGrade = config.computeTermGrade(
            examRaw: examRaw,
            examMax: examMax,
            quizRaw: quizRaw,
            quizMax: quizMax,
            attendRaw: attendRaw,
            attendMax: attendMax,
          );
        }
      }

      await _client
          .from('student_grades')
          .update({
            'quiz_raw': quizRaw,
            'quiz_max': quizMax,
            'exam_raw': examRaw,
            'exam_max': examMax,
            'computed_grade': computedGrade,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gradeId);
    } catch (e) {
      debugPrint('Recalculate grade totals error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT-SIDE GRADE QUERIES
  // ═══════════════════════════════════════════════════

  /// Get all grade records for a single enrollment (one student × one subject).
  Future<List<StudentGrade>> getGradesForEnrollment(String enrollmentId) async {
    try {
      final response = await _client
          .from('student_grades')
          .select('*, enrollments(*, students(*))')
          .eq('enrollment_id', enrollmentId)
          .order('term');
      return (response as List)
          .map((e) => StudentGrade.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get grades for enrollment error: $e');
      return [];
    }
  }

  /// Get all grade items for multiple grade IDs at once.
  Future<Map<String, List<StudentGradeItem>>> getGradeItemsBatch(
    List<String> gradeIds,
  ) async {
    if (gradeIds.isEmpty) return {};
    try {
      final response = await _client
          .from('student_grade_items')
          .select()
          .inFilter('grade_id', gradeIds)
          .order('created_at');
      final items = (response as List)
          .map((e) => StudentGradeItem.fromSupabase(e))
          .toList();
      final map = <String, List<StudentGradeItem>>{};
      for (final item in items) {
        map.putIfAbsent(item.gradeId, () => []).add(item);
      }
      return map;
    } catch (e) {
      debugPrint('Get grade items batch error: $e');
      return {};
    }
  }

  /// Get live attendance stats for an enrollment (not yet synced to grades).
  Future<({int present, int late, int absent, int excused, int total})>
  getLiveAttendanceStats(String enrollmentId) async {
    try {
      final records = await _client
          .from('attendance')
          .select('status')
          .eq('enrollment_id', enrollmentId);

      int present = 0, late = 0, absent = 0, excused = 0, total = 0;
      for (final r in (records as List)) {
        final status = r['status'] as String? ?? '';
        if (status == 'no_class' ||
            status == 'holiday' ||
            status == 'suspended')
          continue;
        total++;
        if (status == 'present') present++;
        if (status == 'late') late++;
        if (status == 'absent') absent++;
        if (status == 'excused') excused++;
      }
      return (
        present: present,
        late: late,
        absent: absent,
        excused: excused,
        total: total,
      );
    } catch (e) {
      debugPrint('Get live attendance stats error: $e');
      return (present: 0, late: 0, absent: 0, excused: 0, total: 0);
    }
  }

  // ═══════════════════════════════════════════════════
  // ATTENDANCE → GRADE AUTO-COMPUTATION
  // ═══════════════════════════════════════════════════

  /// Compute attendance score from attendance records.
  /// Formula: (present + 0.5 * late) / total_days × maxScore
  Future<({double raw, double max})> computeAttendanceScore({
    required String enrollmentId,
    required double maxScore,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('attendance')
          .select('status, date')
          .eq('enrollment_id', enrollmentId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T').first);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T').first);
      }

      final records = await query;

      if ((records as List).isEmpty) return (raw: 0.0, max: maxScore);

      int present = 0, late = 0, total = 0;
      for (final r in records) {
        final status = r['status'] as String? ?? '';
        if (status == 'present' || status == 'late' || status == 'absent') {
          total++;
          if (status == 'present') present++;
          if (status == 'late') late++;
        }
      }

      if (total == 0) return (raw: 0.0, max: maxScore);
      final raw = ((present + 0.5 * late) / total) * maxScore;
      return (raw: double.parse(raw.toStringAsFixed(1)), max: maxScore);
    } catch (e) {
      debugPrint('Compute attendance score error: $e');
      return (raw: 0.0, max: maxScore);
    }
  }

  /// Syncs an attendance record to the corresponding term grade.
  Future<void> syncAttendanceToGrade({
    required String enrollmentId,
    required DateTime date,
  }) async {
    try {
      // 1. Get subject ID from enrollment
      final enrollmentMap = await _client
          .from('enrollments')
          .select('subject_id')
          .eq('id', enrollmentId)
          .maybeSingle();
      if (enrollmentMap == null) return;
      final subjectId = enrollmentMap['subject_id'] as String;

      // 2. Get grading config to determine the term for the date
      final configMap = await _client
          .from('subject_grading_config')
          .select()
          .eq('subject_id', subjectId)
          .maybeSingle();
      if (configMap == null) return;

      final config = GradingConfig.fromSupabase(configMap);
      final term = config.termForDate(date);

      // Determine the date range for the matched term
      DateTime? termStart, termEnd;
      if (term == 'prelim') {
        termStart = config.prelimStart;
        termEnd = config.prelimEnd;
      } else if (term == 'midterm') {
        termStart = config.midtermStart;
        termEnd = config.midtermEnd;
      } else if (term == 'semi_finals') {
        termStart = config.semiFinalsStart;
        termEnd = config.semiFinalsEnd;
      } else if (term == 'finals') {
        termStart = config.finalsStart;
        termEnd = config.finalsEnd;
      }

      // 3. Find or create StudentGrade for this enrollment + term
      var gradeMap = await _client
          .from('student_grades')
          .select('id, attendance_max')
          .eq('enrollment_id', enrollmentId)
          .eq('term', term)
          .maybeSingle();

      String gradeId;
      double attendMax = 0;
      if (gradeMap != null) {
        gradeId = gradeMap['id'] as String;
        attendMax = (gradeMap['attendance_max'] as num?)?.toDouble() ?? 100;
      } else {
        // We set 100 as default max attendance score when auto-creating
        final newGrade = await _client
            .from('student_grades')
            .insert({
              'enrollment_id': enrollmentId,
              'term': term,
              'attendance_max': 100,
            })
            .select()
            .single();
        gradeId = newGrade['id'] as String;
        attendMax = 100;
      }

      // 4. Compute the attendance score filtered to that term's date range
      final score = await computeAttendanceScore(
        enrollmentId: enrollmentId,
        maxScore: attendMax,
        startDate: termStart,
        endDate: termEnd,
      );

      // 5. Update attendance_raw and recalculate totals
      await _client
          .from('student_grades')
          .update({
            'attendance_raw': score.raw,
            'attendance_max': score.max,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gradeId);

      await recalculateGradeTotals(gradeId);
    } catch (e) {
      debugPrint('Sync attendance to grade error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════
// CLASS CANCELLATIONS (no_class / holiday / suspended)
// ═══════════════════════════════════════════════════

/// A class-level cancellation record stored in `class_cancellations`.
class ClassCancellation {
  final String? id;
  final String subjectId;
  final DateTime date;
  final String reason; // 'no_class', 'holiday', 'suspended'
  final String? remarks;

  const ClassCancellation({
    this.id,
    required this.subjectId,
    required this.date,
    required this.reason,
    this.remarks,
  });

  factory ClassCancellation.fromMap(Map<String, dynamic> m) =>
      ClassCancellation(
        id: m['id'],
        subjectId: m['subject_id'] ?? '',
        date: m['date'] != null ? DateTime.parse(m['date']) : DateTime.now(),
        reason: m['reason'] ?? 'no_class',
        remarks: m['remarks'],
      );

  String get reasonLabel {
    switch (reason) {
      case 'no_class':
        return 'No Class (Instructor Leave)';
      case 'holiday':
        return 'Holiday';
      case 'suspended':
        return 'Class Suspended';
      default:
        return reason;
    }
  }
}

// ═══════════════════════════════════════════════════
// ROSTER ENTRY DATA CLASS
// ═══════════════════════════════════════════════════

class RosterEntry {
  final String enrollmentId;
  final String studentId;
  final String lastName;
  final String firstName;
  final String usn;
  final String course;
  final String yearLevel;
  final String section;
  final AttendanceRecord? attendanceRecord;

  const RosterEntry({
    required this.enrollmentId,
    required this.studentId,
    required this.lastName,
    required this.firstName,
    required this.usn,
    required this.course,
    required this.yearLevel,
    required this.section,
    this.attendanceRecord,
  });

  String get fullName => '$firstName $lastName';
  String get sectionLabel => '$course $yearLevel $section'.trim();
}

// ═══════════════════════════════════════════════════
// ANNOUNCEMENTS
// ═══════════════════════════════════════════════════

extension AnnouncementServiceExtension on SupabaseService {
  /// Create a new announcement.
  Future<Announcement?> createAnnouncement(Announcement announcement) async {
    try {
      final response = await client
          .from('announcements')
          .insert(announcement.toMap())
          .select()
          .single();
      return Announcement.fromSupabase(response);
    } catch (e) {
      debugPrint('Create announcement error: $e');
      rethrow;
    }
  }

  /// Update an existing announcement.
  Future<Announcement?> updateAnnouncement(Announcement announcement) async {
    try {
      final response = await client
          .from('announcements')
          .update(announcement.toMap())
          .eq('id', announcement.id!)
          .select()
          .single();
      return Announcement.fromSupabase(response);
    } catch (e) {
      debugPrint('Update announcement error: $e');
      rethrow;
    }
  }

  /// Delete an announcement.
  Future<void> deleteAnnouncement(String id) async {
    try {
      await client.from('announcements').delete().eq('id', id);
    } catch (e) {
      debugPrint('Delete announcement error: $e');
      rethrow;
    }
  }

  /// Toggle the is_active flag.
  Future<void> toggleAnnouncementActive(String id, bool isActive) async {
    try {
      await client
          .from('announcements')
          .update({'is_active': isActive})
          .eq('id', id);
    } catch (e) {
      debugPrint('Toggle announcement error: $e');
      rethrow;
    }
  }

  /// Get all announcements (admin view).
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await client
          .from('announcements')
          .select()
          .order('start_date', ascending: false);
      return (response as List)
          .map((e) => Announcement.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get announcements error: $e');
      return [];
    }
  }

  /// Get active announcements (student view).
  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final response = await client
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('start_date', ascending: true);
      return (response as List)
          .map((e) => Announcement.fromSupabase(e))
          .toList();
    } catch (e) {
      debugPrint('Get active announcements error: $e');
      return [];
    }
  }
}
