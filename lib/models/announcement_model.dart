import 'package:flutter/material.dart';

/// Announcement categories with display helpers.
class AnnouncementCategory {
  static const quiz       = 'quiz';
  static const exam       = 'exam';
  static const grades     = 'grades';
  static const clearance  = 'clearance';
  static const activity   = 'activity';
  static const compliance = 'compliance';
  static const general    = 'general';

  static const all = [quiz, exam, grades, clearance, activity, compliance, general];

  static String label(String category) {
    switch (category) {
      case quiz:       return 'Quiz';
      case exam:       return 'Exam';
      case grades:     return 'Grades';
      case clearance:  return 'Clearance';
      case activity:   return 'Activity';
      case compliance: return 'Compliance';
      case general:    return 'General';
      default:         return category;
    }
  }

  static IconData icon(String category) {
    switch (category) {
      case quiz:       return Icons.quiz_rounded;
      case exam:       return Icons.assignment_rounded;
      case grades:     return Icons.grade_rounded;
      case clearance:  return Icons.verified_rounded;
      case activity:   return Icons.celebration_rounded;
      case compliance: return Icons.checklist_rounded;
      case general:    return Icons.campaign_rounded;
      default:         return Icons.info_rounded;
    }
  }

  static Color color(String category) {
    switch (category) {
      case quiz:       return const Color(0xFF3B82F6); // blue
      case exam:       return const Color(0xFFEF4444); // red
      case grades:     return const Color(0xFF8B5CF6); // purple
      case clearance:  return const Color(0xFF10B981); // green
      case activity:   return const Color(0xFFF59E0B); // amber
      case compliance: return const Color(0xFFF97316); // orange
      case general:    return const Color(0xFF64748B); // slate
      default:         return const Color(0xFF64748B);
    }
  }
}

class Announcement {
  final String? id;
  final String title;
  final String? description;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? subjectId;
  final DateTime? createdAt;

  const Announcement({
    this.id,
    required this.title,
    this.description,
    this.category = 'general',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.subjectId,
    this.createdAt,
  });

  /// Whether [date] falls within this announcement's range (inclusive).
  bool coversDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// Whether this announcement is currently active and covers today.
  bool get isOngoing {
    final now = DateTime.now();
    return isActive && coversDate(now);
  }

  /// Whether this announcement is in the future.
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    return isActive && s.isAfter(today);
  }

  /// Category display helpers.
  String get categoryLabel => AnnouncementCategory.label(category);
  IconData get categoryIcon => AnnouncementCategory.icon(category);
  Color get categoryColor => AnnouncementCategory.color(category);

  factory Announcement.fromSupabase(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'general',
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
      subjectId: map['subject_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'is_active': isActive,
      'subject_id': subjectId,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? subjectId,
    DateTime? createdAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      subjectId: subjectId ?? this.subjectId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
