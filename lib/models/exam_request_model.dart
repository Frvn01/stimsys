import 'package:flutter/foundation.dart';

/// Represents a student's submitted Exam Request / Permit with proctor details & signature images.
class ExamRequest {
  final String? id;
  final String studentId;
  final String subjectId;
  final String? assessmentId;
  final String proctorName;
  final String section;
  final String course;
  final String subjectName;
  final String? proctorSignatureUrl;
  final String? documentImageUrl;
  final String status; // 'submitted', 'verified', 'approved'
  final DateTime? createdAt;

  // Joined / Display fields
  final String? studentName;
  final String? studentUsn;

  const ExamRequest({
    this.id,
    required this.studentId,
    required this.subjectId,
    this.assessmentId,
    required this.proctorName,
    required this.section,
    required this.course,
    required this.subjectName,
    this.proctorSignatureUrl,
    this.documentImageUrl,
    this.status = 'submitted',
    this.createdAt,
    this.studentName,
    this.studentUsn,
  });

  Map<String, dynamic> toSupabase() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'subject_id': subjectId,
        'assessment_id': assessmentId,
        'proctor_name': proctorName,
        'section': section,
        'course': course,
        'subject_name': subjectName,
        'proctor_signature_url': proctorSignatureUrl,
        'document_image_url': documentImageUrl,
        'status': status,
      };

  factory ExamRequest.fromSupabase(Map<String, dynamic> map) {
    final studentMap = map['students'] as Map<String, dynamic>?;

    return ExamRequest(
      id: map['id']?.toString(),
      studentId: map['student_id'] ?? '',
      subjectId: map['subject_id'] ?? '',
      assessmentId: map['assessment_id'],
      proctorName: map['proctor_name'] ?? '',
      section: map['section'] ?? '',
      course: map['course'] ?? '',
      subjectName: map['subject_name'] ?? '',
      proctorSignatureUrl: map['proctor_signature_url'],
      documentImageUrl: map['document_image_url'],
      status: map['status'] ?? 'submitted',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      studentName: studentMap != null
          ? '${studentMap['last_name']}, ${studentMap['first_name']}'
          : null,
      studentUsn: studentMap?['usn'],
    );
  }

  ExamRequest copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? assessmentId,
    String? proctorName,
    String? section,
    String? course,
    String? subjectName,
    String? proctorSignatureUrl,
    String? documentImageUrl,
    String? status,
    DateTime? createdAt,
    String? studentName,
    String? studentUsn,
  }) =>
      ExamRequest(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        subjectId: subjectId ?? this.subjectId,
        assessmentId: assessmentId ?? this.assessmentId,
        proctorName: proctorName ?? this.proctorName,
        section: section ?? this.section,
        course: course ?? this.course,
        subjectName: subjectName ?? this.subjectName,
        proctorSignatureUrl: proctorSignatureUrl ?? this.proctorSignatureUrl,
        documentImageUrl: documentImageUrl ?? this.documentImageUrl,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        studentName: studentName ?? this.studentName,
        studentUsn: studentUsn ?? this.studentUsn,
      );
}
