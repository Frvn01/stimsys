import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local answer caching service for quiz/exam resilience.
///
/// Saves student answers to SharedPreferences so they survive
/// app crashes, network drops, or accidental closes.
class AnswerCacheService {
  static String _key(String assessmentId, String usn) =>
      'answer_cache_${assessmentId}_$usn';

  /// Save current answers to local storage.
  static Future<void> saveAnswers(
      String assessmentId, String usn, Map<String, String> answers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(assessmentId, usn), jsonEncode(answers));
  }

  /// Restore cached answers. Returns null if no cache exists.
  static Future<Map<String, String>?> restoreAnswers(
      String assessmentId, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(assessmentId, usn));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  /// Clear cache after successful submission.
  static Future<void> clearCache(String assessmentId, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(assessmentId, usn));
  }

  /// Check if a cache exists for this assessment + student.
  static Future<bool> hasCache(String assessmentId, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(assessmentId, usn));
  }

  /// Save the timestamp when the student started (for resuming timer).
  static Future<void> saveStartTime(
      String assessmentId, String usn, DateTime startTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${_key(assessmentId, usn)}_start', startTime.toIso8601String());
  }

  /// Get the saved start time (for resuming timer).
  static Future<DateTime?> getStartTime(
      String assessmentId, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_key(assessmentId, usn)}_start');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Clear start time.
  static Future<void> clearStartTime(
      String assessmentId, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_key(assessmentId, usn)}_start');
  }

  /// Full cleanup — clear answers + start time.
  static Future<void> clearAll(String assessmentId, String usn) async {
    await clearCache(assessmentId, usn);
    await clearStartTime(assessmentId, usn);
  }
}
