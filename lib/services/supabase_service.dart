import 'dart:convert';
import 'dart:io';
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

/// Thrown when a QR scan happens outside the subject's valid schedule window.
class ScheduleValidationException implements Exception {
  final String message;
  const ScheduleValidationException(this.message);
  @override
  String toString() => message;
}

/// Maps a scheduleDay code to the list of Dart weekday integers (1=Mon … 7=Sun).
List<int> _scheduleDayToWeekdays(String scheduleDay) {
  switch (scheduleDay.toUpperCase().trim()) {
    case 'MON':    return [DateTime.monday];
    case 'TUE':    return [DateTime.tuesday];
    case 'WED':    return [DateTime.wednesday];
    case 'THU':    return [DateTime.thursday];
    case 'FRI':    return [DateTime.friday];
    case 'SAT':    return [DateTime.saturday];
    case 'SUN':    return [DateTime.sunday];
    case 'MWF':    return [DateTime.monday, DateTime.wednesday, DateTime.friday];
    case 'TTH':    return [DateTime.tuesday, DateTime.thursday];
    case 'MTWTHF': return [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday];
    default:       return [];
  }
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = SupabaseConfig.client;

  /// Expose client for advanced queries.
  get client => _client;

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

  /// Enroll a student by subject ID (used when student scans enrollment QR).
  /// Returns existing enrollment if already enrolled (no error).
  Future<Enrollment> enrollStudentBySubjectId(
      String studentId, String subjectId) async {
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

      // ── Schedule Day Validation ──────────────────────────────────
      final validDays = _scheduleDayToWeekdays(subject.scheduleDay);
      if (validDays.isNotEmpty && !validDays.contains(now.weekday)) {
        throw const ScheduleValidationException(
            'No class scheduled today for this subject.');
      }

      // ── Time Window Validation ───────────────────────────────────
      final startTime = subject.startTimeToday;
      final endTime = subject.endTimeToday;
      final openTime = startTime.subtract(const Duration(minutes: 30));

      if (now.isBefore(openTime)) {
        final diff = openTime.difference(now).inMinutes;
        throw ScheduleValidationException(
            "Class hasn't started yet — opens in $diff min.");
      }
      if (now.isAfter(endTime)) {
        throw const ScheduleValidationException(
            'Class session has already ended.');
      }

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

      // ── Late vs Present Determination ────────────────────────────
      final lateThreshold =
          startTime.add(Duration(minutes: subject.lateThresholdMinutes));

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
      final dateStr = DateTime(today.year, today.month, today.day)
          .toIso8601String()
          .split('T')
          .first;

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

  // ═══════════════════════════════════════════════════
  // ATTENDANCE — ADMIN EDIT
  // ═══════════════════════════════════════════════════

  /// Admin manually updates an attendance record's status.
  Future<void> updateAttendanceStatus(
      String attendanceId, String newStatus, {String? remarks}) async {
    try {
      final data = <String, dynamic>{'status': newStatus};
      if (remarks != null) data['remarks'] = remarks;
      await _client.from('attendance').update(data).eq('id', attendanceId);
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
        return AttendanceRecord.fromSupabase(updated);
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
      return AttendanceRecord.fromSupabase(response);
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
      String subjectId, {DateTime? date}) async {
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

        roster.add(RosterEntry(
          enrollmentId: enrollmentId,
          studentId: studentMap?['id'] ?? '',
          lastName: studentMap?['last_name'] ?? '',
          firstName: studentMap?['first_name'] ?? '',
          usn: studentMap?['usn'] ?? '',
          course: studentMap?['course'] ?? '',
          yearLevel: studentMap?['year_level'] ?? '',
          section: studentMap?['section'] ?? '',
          attendanceRecord: record,
        ));
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
    await bucket.upload(fileName, file,
        fileOptions: const FileOptions(upsert: true));
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
      String studentId, Uint8List imageBytes, String extension) async {
    final bucket = _client.storage.from('student-profiles');
    final fileName = '$studentId.$extension';
    await bucket.uploadBinary(
      fileName,
      imageBytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    final url = bucket.getPublicUrl(fileName);
    // Update the student record
    await _client
        .from('students')
        .update({'profile_image_url': url})
        .eq('id', studentId);
    return url;
  }

  /// Deletes a student profile image from Supabase Storage and clears the DB URL.
  Future<void> deleteStudentProfileImage(String studentId, String fileUrl) async {
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
          await _client.from('attendance').update({
            'status': reason,
            'remarks': remarkStr,
          }).eq('id', attRec['id']);
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
      String subjectId) async {
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
      String subjectId, DateTime date) async {
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
      final response =
          await query.order('created_at', ascending: false);
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
      // First get all enrollments for the subject
      final enrollments = await _client
          .from('enrollments')
          .select('id, students(*)')
          .eq('subject_id', subjectId);

      if ((enrollments as List).isEmpty) return [];

      final enrollmentIds =
          enrollments.map((e) => e['id'] as String).toList();

      final grades = await _client
          .from('student_grades')
          .select('*, enrollments(*, students(*))')
          .inFilter('enrollment_id', enrollmentIds)
          .order('term');

      return (grades as List)
          .map((e) => StudentGrade.fromSupabase(e))
          .toList();
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
      String subjectId) async {
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
      final response = await _client
          .from('assessments')
          .insert(config.toSupabase())
          .select()
          .single();
      return AssessmentConfig.fromSupabase(response);
    } catch (e) {
      debugPrint('Create assessment error: $e');
      rethrow;
    }
  }

  Future<AssessmentConfig?> updateAssessment(AssessmentConfig config) async {
    try {
      final data = config.toSupabase();
      data['updated_at'] = DateTime.now().toIso8601String();
      final response = await _client
          .from('assessments')
          .update(data)
          .eq('id', config.id!)
          .select()
          .single();
      return AssessmentConfig.fromSupabase(response);
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
      String subjectId) async {
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
      String subjectId) async {
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
      AssessmentQuestion question) async {
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
            .map((a) => AssessmentAnswer(
                  submissionId: submissionId,
                  questionId: a.questionId,
                  studentAnswer: a.studentAnswer,
                  isCorrect: a.isCorrect,
                  pointsEarned: a.pointsEarned,
                ).toSupabase())
            .toList();
        await _client.from('assessment_answers').insert(answerData);
      }

      return AssessmentSubmission.fromSupabase(subRes);
    } catch (e) {
      debugPrint('Submit assessment error: $e');
      rethrow;
    }
  }

  Future<bool> hasStudentSubmitted(
      String assessmentId, String studentId) async {
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
      String assessmentId) async {
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
      String studentId, String subjectId) async {
    try {
      // Get all assessment IDs for this subject
      final assessments = await _client
          .from('assessments')
          .select('id')
          .eq('subject_id', subjectId);
      final ids =
          (assessments as List).map((e) => e['id'] as String).toList();
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
        return (false, 'Invalid QR format');
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
            .insert({
              'enrollment_id': enrollmentId,
              'term': assessment.term,
            })
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

      return (true, '${assessment.title} — Score: ${score.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)} recorded');
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
      final attendRaw =
          (gradeMap['attendance_raw'] as num?)?.toDouble() ?? 0;
      final attendMax =
          (gradeMap['attendance_max'] as num?)?.toDouble() ?? 0;

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

      await _client.from('student_grades').update({
        'quiz_raw': quizRaw,
        'quiz_max': quizMax,
        'exam_raw': examRaw,
        'exam_max': examMax,
        'computed_grade': computedGrade,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', gradeId);
    } catch (e) {
      debugPrint('Recalculate grade totals error: $e');
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
  }) async {
    try {
      final records = await _client
          .from('attendance')
          .select('status')
          .eq('enrollment_id', enrollmentId);

      if ((records as List).isEmpty) return (raw: 0.0, max: maxScore);

      int present = 0, late = 0, total = 0;
      for (final r in records) {
        final status = r['status'] as String? ?? '';
        if (status == 'present' ||
            status == 'late' ||
            status == 'absent') {
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

  factory ClassCancellation.fromMap(Map<String, dynamic> m) => ClassCancellation(
    id: m['id'],
    subjectId: m['subject_id'] ?? '',
    date: m['date'] != null ? DateTime.parse(m['date']) : DateTime.now(),
    reason: m['reason'] ?? 'no_class',
    remarks: m['remarks'],
  );

  String get reasonLabel {
    switch (reason) {
      case 'no_class': return 'No Class (Instructor Leave)';
      case 'holiday': return 'Holiday';
      case 'suspended': return 'Class Suspended';
      default: return reason;
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
