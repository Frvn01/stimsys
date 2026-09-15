import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // import to access globalScaffoldMessengerKey
import '../models/student_model.dart';
import '../models/enrollment_model.dart';
import '../models/attendance_model.dart';
import '../models/module_model.dart';
import '../models/assessment_model.dart';
import '../models/grading_config_model.dart';
import '../models/student_grade_model.dart';
import '../models/student_grade_item_model.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/announcement_model.dart';
import '../models/exam_request_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class StudentProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  Student? _currentStudent;
  List<Enrollment> _enrollments = [];
  List<AttendanceRecord> _attendanceRecords = [];
  List<LearningModule> _modules = [];
  List<AssessmentConfig> _availableAssessments = [];
  List<AssessmentSubmission> _mySubmissions = [];
  List<Announcement> _announcements = [];
  bool _isLoading = false;

  Student? get currentStudent => _currentStudent;
  List<Enrollment> get enrollments => _enrollments;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  List<LearningModule> get modules => _modules;
  List<AssessmentConfig> get availableAssessments => _availableAssessments;
  List<AssessmentSubmission> get mySubmissions => _mySubmissions;
  List<Announcement> get announcements => _announcements;
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
        await loadAllData(notifyAtEnd: false);
        _setupNotifications();
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

  Future<bool> resetPassword(String usn, String lastName, String newPassword) async {
    _setLoading(true);
    try {
      return await _service.resetStudentPassword(usn, lastName, newPassword);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentStudent == null) return;
    _setLoading(true);
    try {
      await _service.updateStudentPassword(_currentStudent!.usn, newPassword);
    } finally {
      _setLoading(false);
    }
  }

  /// Efficient parallel data loader for startup and pull-to-refresh
  Future<void> loadAllData({bool notifyAtEnd = true}) async {
    if (_currentStudent?.id == null) return;
    try {
      await Future.wait([
        _service.getStudentEnrollments(_currentStudent!.id!).then((data) => _enrollments = data).catchError((e) {
          debugPrint('Load enrollments error: $e');
          return <Enrollment>[];
        }),
        _service.getStudentAttendance(_currentStudent!.id!).then((data) => _attendanceRecords = data).catchError((e) {
          debugPrint('Load attendance error: $e');
          return <AttendanceRecord>[];
        }),
        _service.getActiveAnnouncements().then((data) => _announcements = data).catchError((e) {
          debugPrint('Load announcements error: $e');
          return <Announcement>[];
        }),
        _service.getModules().then((data) => _modules = data).catchError((e) {
          debugPrint('Load modules error: $e');
          return <LearningModule>[];
        }),
        _service.getExamRequestsForStudent(_currentStudent!.id!).then((data) => _myExamRequests = data).catchError((e) {
          debugPrint('Load exam requests error: $e');
          return <ExamRequest>[];
        }),
      ]);
    } catch (e) {
      debugPrint('Load all data error: $e');
    } finally {
      if (notifyAtEnd) notifyListeners();
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
    String? phone,
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
        phone: phone,
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

  /// Get learning modules for a specific subject.
  List<LearningModule> getModulesForSubject(String subject) {
    return _modules.where((m) => m.subject == subject).toList();
  }

  /// Load all available learning modules.
  Future<void> loadModules() async {
    try {
      _modules = await _service.getModules();
      notifyListeners();
    } catch (e) {
      debugPrint('Load modules error: $e');
    }
  }

  RealtimeChannel? _assessmentsChannel;
  RealtimeChannel? _announcementsChannel;
  RealtimeChannel? _modulesChannel;

  void _showInAppNotification({
    required String title,
    required String body,
    required IconData icon,
    Color color = const Color(0xFF6366F1),
  }) {
    if (globalScaffoldMessengerKey.currentState != null) {
      globalScaffoldMessengerKey.currentState!.clearSnackBars();
      globalScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(body,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _setupNotifications() {
    _assessmentsChannel?.unsubscribe();
    _announcementsChannel?.unsubscribe();
    _modulesChannel?.unsubscribe();

    // 1. ASSESSMENTS REALTIME (New Quizzes/Exams Published)
    _assessmentsChannel = _service.client
        .channel('public:assessments_student')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'assessments',
          callback: (payload) async {
            try {
              final newRecord = payload.newRecord;
              final oldRecord = payload.oldRecord;
              final isPublishedNow = newRecord['is_published'] == true;
              final wasPublished = oldRecord['is_published'] == true;

              final subjectId = newRecord['subject_id'] as String?;
              if (subjectId == null) return;

              final isEnrolled =
                  _enrollments.any((e) => e.subjectId == subjectId);
              if (isEnrolled && isPublishedNow && !wasPublished) {
                final title = newRecord['title'] as String? ?? 'Assessment';
                final type = newRecord['type'] as String? ?? 'quiz';
                final isExam = type == 'exam';

                final notifTitle = isExam ? 'New Exam Published!' : 'New Quiz Published!';
                final notifBody = '$title has been published for your subject.';
                final rawId = newRecord['id']?.toString() ?? '';
                final notifId = rawId.isNotEmpty
                    ? rawId.hashCode.abs()
                    : DateTime.now().millisecondsSinceEpoch % 100000;

                await NotificationService().showNotification(
                  id: notifId,
                  title: notifTitle,
                  body: notifBody,
                );

                _showInAppNotification(
                  title: notifTitle,
                  body: notifBody,
                  icon: isExam ? Icons.school_rounded : Icons.assignment_rounded,
                  color: isExam ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                );

                if (_enrollments.isNotEmpty) {
                  loadAvailableAssessments(subjectId);
                }
              }
            } catch (e) {
              debugPrint('Error in realtime assessment update callback: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'assessments',
          callback: (payload) async {
            try {
              final record = payload.newRecord;
              final subjectId = record['subject_id'] as String?;
              final isPublished = record['is_published'] == true;
              if (subjectId == null) return;

              final isEnrolled =
                  _enrollments.any((e) => e.subjectId == subjectId);
              if (isEnrolled && isPublished) {
                final title = record['title'] as String? ?? 'Assessment';
                final type = record['type'] as String? ?? 'quiz';
                final isExam = type == 'exam';

                final notifTitle = isExam ? 'New Exam Published!' : 'New Quiz Published!';
                final notifBody = '$title is now available for your subject.';
                final rawId = record['id']?.toString() ?? '';
                final notifId = rawId.isNotEmpty
                    ? rawId.hashCode.abs()
                    : DateTime.now().millisecondsSinceEpoch % 100000;

                await NotificationService().showNotification(
                  id: notifId,
                  title: notifTitle,
                  body: notifBody,
                );

                _showInAppNotification(
                  title: notifTitle,
                  body: notifBody,
                  icon: isExam ? Icons.school_rounded : Icons.assignment_rounded,
                  color: isExam ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                );

                if (_enrollments.isNotEmpty) {
                  loadAvailableAssessments(subjectId);
                }
              }
            } catch (e) {
              debugPrint('Error in realtime assessment insert callback: $e');
            }
          },
        )
        .subscribe();

    // 2. ANNOUNCEMENTS REALTIME
    _announcementsChannel = _service.client
        .channel('public:announcements_student')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'announcements',
          callback: (payload) async {
            try {
              final record = payload.newRecord;
              debugPrint('Announcement realtime payload: $record');

              final title = record['title'] as String? ?? 'New Announcement';
              final desc = record['description'] as String? ??
                  'Check the calendar for details.';
              final rawId = record['id']?.toString() ?? '';
              final notifId = rawId.isNotEmpty
                  ? rawId.hashCode.abs()
                  : DateTime.now().millisecondsSinceEpoch % 100000;

              debugPrint('Showing notification: $title (id: $notifId)');

              await NotificationService().showNotification(
                id: notifId,
                title: 'Announcement: $title',
                body: desc.isNotEmpty
                    ? desc
                    : 'Check the calendar for details.',
              );

              _showInAppNotification(
                title: 'Announcement: $title',
                body: desc.isNotEmpty
                    ? desc
                    : 'Check the calendar for details.',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF6366F1),
              );

              loadAnnouncements();
            } catch (e) {
              debugPrint('Error in announcement notification callback: $e');
            }
          },
        )
        .subscribe();

    // 3. LEARNING MODULES REALTIME
    _modulesChannel = _service.client
        .channel('public:modules_student')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'modules',
          callback: (payload) async {
            try {
              final record = payload.newRecord;
              final subject = record['subject'] as String?;
              final title = record['title'] as String? ?? 'New Module';

              // Check if enrolled by subject code or subject title
              final isEnrolled = _enrollments.any((e) =>
                  subject == null ||
                  subject.isEmpty ||
                  (e.subject?.subjectCode.toLowerCase() ==
                      subject.toLowerCase()) ||
                  (e.subject?.subjectTitle.toLowerCase() ==
                      subject.toLowerCase()));

              if (isEnrolled) {
                final rawId = record['id']?.toString() ?? '';
                final notifId = rawId.isNotEmpty
                    ? rawId.hashCode.abs()
                    : DateTime.now().millisecondsSinceEpoch % 100000;

                const notifTitle = 'New Learning Module Added!';
                final notifBody = '$title has been uploaded.';

                await NotificationService().showNotification(
                  id: notifId,
                  title: notifTitle,
                  body: notifBody,
                );

                _showInAppNotification(
                  title: notifTitle,
                  body: notifBody,
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF10B981),
                );

                loadModules();
              }
            } catch (e) {
              debugPrint('Error in module notification callback: $e');
            }
          },
        )
        .subscribe();
  }

  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsn = prefs.getString('usn');
      final savedPassword = prefs.getString('password');
      if (savedUsn != null && savedPassword != null) {
        final student = await login(savedUsn, savedPassword);
        return student != null;
      }
    } catch (e) {
      debugPrint('Restore session error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _assessmentsChannel?.unsubscribe();
    _announcementsChannel?.unsubscribe();
    _modulesChannel?.unsubscribe();
    _currentStudent = null;
    _enrollments = [];
    _attendanceRecords = [];
    _modules = [];
    _availableAssessments = [];
    _mySubmissions = [];
    _announcements = [];
    _myExamRequests = [];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('usn');
      await prefs.remove('password');
    } catch (e) {
      debugPrint('Logout prefs error: $e');
    }
  }

  Future<(bool, String)> enrollBySubjectQR(String subjectId) async {
    if (_currentStudent?.id == null) return (false, 'Not logged in');
    try {
      final enrollment = await _service.enrollStudentBySubjectId(
          _currentStudent!.id!, subjectId);
      // Refresh enrollments list
      await loadEnrollments();
      final subjectName = enrollment.subject?.subjectTitle ?? 'subject';
      final subjectCode = enrollment.subject?.subjectCode ?? '';
      return (true, 'Enrolled in $subjectName ($subjectCode)!');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate') || msg.contains('already')) {
        return (false, 'You are already enrolled in this subject.');
      }
      return (false, 'Enrollment failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════

  /// Load active announcements visible to students.
  Future<void> loadAnnouncements() async {
    try {
      _announcements = await _service.getActiveAnnouncements();
      notifyListeners();
    } catch (e) {
      debugPrint('Load announcements error: $e');
    }
  }

  /// Get announcements that cover a specific date.
  List<Announcement> announcementsForDate(DateTime date) {
    return _announcements.where((a) => a.coversDate(date)).toList();
  }

  /// Get upcoming announcements (start date is in the future).
  List<Announcement> get upcomingAnnouncements {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _announcements
        .where((a) {
          final end = DateTime(a.endDate.year, a.endDate.month, a.endDate.day);
          return !end.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Upload a profile image (compressed bytes) to Supabase and update the student record.
  Future<(bool, String)> uploadProfileImage(
      Uint8List imageBytes, String extension) async {
    if (_currentStudent?.id == null) return (false, 'Not logged in');
    try {
      final url = await _service.uploadStudentProfileImage(
          _currentStudent!.id!, imageBytes, extension);
      // Update local state
      _currentStudent = _currentStudent!.copyWith(profileImageUrl: url);
      notifyListeners();
      return (true, url);
    } catch (e) {
      debugPrint('Upload profile image error: $e');
      return (false, 'Upload failed: $e');
    }
  }

  /// Delete the current student's profile image from Supabase and update local state.
  Future<(bool, String)> deleteProfileImage() async {
    if (_currentStudent?.id == null) return (false, 'Not logged in');
    if (_currentStudent?.profileImageUrl == null) return (false, 'No profile image to delete');
    
    try {
      await _service.deleteStudentProfileImage(
          _currentStudent!.id!, _currentStudent!.profileImageUrl!);
      // Update local state
      _currentStudent = _currentStudent!.copyWith(profileImageUrl: null);
      notifyListeners();
      return (true, 'Profile image deleted successfully');
    } catch (e) {
      debugPrint('Delete profile image error: $e');
      return (false, 'Failed to delete profile image: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // STUDENT GRADES (class record view)
  // ═══════════════════════════════════════════════════

  /// Grading configs cached by subjectId
  final Map<String, GradingConfig?> _gradingConfigs = {};

  /// Grade records cached by enrollmentId → list of StudentGrade (per term)
  final Map<String, List<StudentGrade>> _enrollmentGrades = {};

  /// Grade items cached by gradeId → list of StudentGradeItem
  final Map<String, List<StudentGradeItem>> _gradeItems = {};

  /// Live attendance stats cached by enrollmentId
  final Map<String, ({int present, int late, int absent, int excused, int total})>
      _liveAttendance = {};

  bool _gradesLoading = false;

  bool get gradesLoading => _gradesLoading;

  GradingConfig? gradingConfigFor(String subjectId) =>
      _gradingConfigs[subjectId];

  List<StudentGrade> gradesForEnrollment(String enrollmentId) =>
      _enrollmentGrades[enrollmentId] ?? [];

  StudentGrade? gradeFor(String enrollmentId, String term) {
    final grades = _enrollmentGrades[enrollmentId];
    if (grades == null) return null;
    try {
      return grades.firstWhere((g) => g.term == term);
    } catch (_) {
      return null;
    }
  }

  List<StudentGradeItem> gradeItemsFor(String gradeId) =>
      _gradeItems[gradeId] ?? [];

  ({int present, int late, int absent, int excused, int total})?
      liveAttendanceFor(String enrollmentId) =>
          _liveAttendance[enrollmentId];

  /// Load all grade data for a subject (config + grades + items + live attendance).
  Future<void> loadGradesForSubject(Enrollment enrollment) async {
    if (enrollment.id == null || enrollment.subjectId == null) return;
    _gradesLoading = true;
    notifyListeners();

    try {
      // 1. Load grading config for the subject
      if (!_gradingConfigs.containsKey(enrollment.subjectId)) {
        _gradingConfigs[enrollment.subjectId!] =
            await _service.getGradingConfig(enrollment.subjectId!);
      }

      // 2. Load grade records for this enrollment
      final grades =
          await _service.getGradesForEnrollment(enrollment.id!);
      _enrollmentGrades[enrollment.id!] = grades;

      // 3. Load all grade items in one batch
      final gradeIds = grades
          .where((g) => g.id != null)
          .map((g) => g.id!)
          .toList();
      if (gradeIds.isNotEmpty) {
        final items = await _service.getGradeItemsBatch(gradeIds);
        _gradeItems.addAll(items);
      }

      // 4. Load live attendance stats
      _liveAttendance[enrollment.id!] =
          await _service.getLiveAttendanceStats(enrollment.id!);
    } catch (e) {
      debugPrint('Load grades for subject error: $e');
    } finally {
      _gradesLoading = false;
      notifyListeners();
    }
  }

  /// Compute weighted final grade from term grades.
  double? computeFinalGrade(String enrollmentId, GradingConfig config) {
    final grades = _enrollmentGrades[enrollmentId];
    if (grades == null || grades.isEmpty) return null;
    final termGrades = <String, double?>{};
    for (final g in grades) {
      termGrades[g.term] = g.computedGrade;
    }
    return config.computeFinalGrade(termGrades);
  }

  // ═══════════════════════════════════════════════════
  // ASSESSMENTS (Student Side)
  // ═══════════════════════════════════════════════════

  /// Load published assessments for a subject.
  Future<void> loadAvailableAssessments(String subjectId) async {
    try {
      _availableAssessments =
          await _service.getPublishedAssessments(subjectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load available assessments error: $e');
    }
  }

  /// Load student's submissions for a subject.
  Future<void> loadMySubmissions(String subjectId) async {
    if (_currentStudent?.id == null) return;
    try {
      _mySubmissions =
          await _service.getStudentSubmissions(_currentStudent!.id!, subjectId);
      notifyListeners();
    } catch (e) {
      debugPrint('Load my submissions error: $e');
    }
  }

  /// Check if student has submitted a specific assessment.
  Future<bool> hasSubmitted(String assessmentId) async {
    if (_currentStudent?.id == null) return false;
    return _service.hasStudentSubmitted(assessmentId, _currentStudent!.id!);
  }

  /// Check locally from cached submissions.
  bool hasSubmittedLocally(String assessmentId) {
    return _mySubmissions.any((s) => s.assessmentId == assessmentId);
  }

  /// Get submission for a specific assessment.
  AssessmentSubmission? submissionFor(String assessmentId) {
    try {
      return _mySubmissions
          .firstWhere((s) => s.assessmentId == assessmentId);
    } catch (_) {
      return null;
    }
  }

  /// Get assessments for a specific term.
  List<AssessmentConfig> assessmentsForTerm(String subjectId, String term) {
    return _availableAssessments
        .where((a) => a.subjectId == subjectId && a.term == term)
        .toList();
  }

  /// Load questions for an assessment.
  Future<List<AssessmentQuestion>> loadQuestions(String assessmentId) async {
    return _service.getQuestions(assessmentId);
  }

  /// Submit an assessment with all answers.
  Future<AssessmentSubmission?> submitAssessment(
    AssessmentSubmission submission,
    List<AssessmentAnswer> answers,
  ) async {
    try {
      final result = await _service.submitAssessment(submission, answers);
      if (result != null) {
        _mySubmissions.add(result);
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('Submit assessment error: $e');
      rethrow;
    }
  }

  /// Submit an appeal for an invalidated assessment.
  Future<void> submitAppeal(String submissionId, String reason) async {
    try {
      await _service.submitAppeal(submissionId, reason);
      // Update local cache
      final idx = _mySubmissions.indexWhere((s) => s.id == submissionId);
      if (idx >= 0) {
        _mySubmissions[idx] = _mySubmissions[idx].copyWith(
          appealStatus: 'pending',
          appealReason: reason,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Submit appeal error: $e');
      rethrow;
    }
  }

  /// Check if all assessments for a term are completed (for term locking).
  bool isTermComplete(String subjectId, String term) {
    final termAssessments = assessmentsForTerm(subjectId, term);
    if (termAssessments.isEmpty) return true; // No assessments = unlocked
    return termAssessments.every(
        (a) => _mySubmissions.any((s) => s.assessmentId == a.id));
  }

  /// Check if a term is unlocked (previous term must be complete).
  bool isTermUnlocked(String subjectId, String term) {
    const termOrder = ['prelim', 'midterm', 'semi_finals', 'finals'];
    final idx = termOrder.indexOf(term);
    if (idx <= 0) return true; // Prelim always unlocked
    // All previous terms must be complete
    for (int i = 0; i < idx; i++) {
      if (!isTermComplete(subjectId, termOrder[i])) return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════
  // EXAM REQUESTS (Student Side)
  // ═══════════════════════════════════════════════════

  List<ExamRequest> _myExamRequests = [];
  List<ExamRequest> get myExamRequests => _myExamRequests;

  /// Load current student's exam requests
  Future<void> loadMyExamRequests({String? subjectId}) async {
    if (_currentStudent?.id == null) return;
    try {
      _myExamRequests = await _service.getExamRequestsForStudent(
        _currentStudent!.id!,
        subjectId: subjectId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Load my exam requests error: $e');
    }
  }

  /// Get current exam request for a specific subject and term (if any)
  ExamRequest? getExamRequestForTerm({
    required String subjectId,
    required String term,
    String? assessmentId,
  }) {
    final normTerm =
        term.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

    try {
      return _myExamRequests.firstWhere((req) {
        if (req.subjectId != subjectId) return false;

        // Direct assessment link
        if (assessmentId != null && req.assessmentId == assessmentId) {
          return true;
        }

        // Term match
        if (req.term != null) {
          final reqTerm =
              req.term!.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
          if (reqTerm == normTerm) return true;
          if ((normTerm == 'pre_finals' || normTerm == 'semi_finals') &&
              (reqTerm == 'pre_finals' || reqTerm == 'semi_finals')) {
            return true;
          }
        }

        // Legacy fallback
        if (req.term == null && req.assessmentId == null) {
          return true;
        }

        return false;
      });
    } catch (_) {
      return null;
    }
  }

  /// Check if the student has an APPROVED exam permit for a specific subject and term
  bool hasExamPermit({
    required String subjectId,
    required String term,
    String? assessmentId,
  }) {
    final req = getExamRequestForTerm(
      subjectId: subjectId,
      term: term,
      assessmentId: assessmentId,
    );
    if (req == null) return false;
    return req.status.toLowerCase() == 'approved';
  }

  /// Submit an exam request with optional proctor signature & document image
  Future<ExamRequest?> submitExamRequest({
    required String subjectId,
    String? term,
    String? assessmentId,
    required String proctorName,
    required String section,
    required String course,
    required String subjectName,
    Uint8List? signatureBytes,
    Uint8List? documentBytes,
  }) async {
    if (_currentStudent?.id == null) return null;
    try {
      String? signatureUrl;
      String? documentUrl;

      if (signatureBytes != null) {
        signatureUrl = await _service.uploadExamRequestImage(
          signatureBytes,
          'sig_${_currentStudent!.usn}_$subjectId',
          extension: 'png',
        );
      }

      if (documentBytes != null) {
        documentUrl = await _service.uploadExamRequestImage(
          documentBytes,
          'doc_${_currentStudent!.usn}_$subjectId',
          extension: 'jpg',
        );
      }

      final request = ExamRequest(
        studentId: _currentStudent!.id!,
        subjectId: subjectId,
        term: term,
        assessmentId: assessmentId,
        proctorName: proctorName,
        section: section,
        course: course,
        subjectName: subjectName,
        proctorSignatureUrl: signatureUrl,
        documentImageUrl: documentUrl,
      );

      final created = await _service.createExamRequest(request);
      if (created != null) {
        _myExamRequests.insert(0, created);
        notifyListeners();
      }
      return created;
    } catch (e) {
      debugPrint('Submit exam request error: $e');
      rethrow;
    }
  }
}
