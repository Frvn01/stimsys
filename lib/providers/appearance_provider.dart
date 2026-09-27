import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only appearance customization for the student app.
///
/// Everything stored here lives on the device only (SharedPreferences for the
/// values, app documents storage for a picked background image). Nothing is
/// ever synced to Supabase.
class AppearanceProvider extends ChangeNotifier {
  static const String _kBgColor = 'appearance_bg_color';
  static const String _kBgImage = 'appearance_bg_image';
  static const String _kGlassBlur = 'appearance_glass_blur';
  static const String _kGlassOpacity = 'appearance_glass_opacity';
  static const String _kGlassTint = 'appearance_glass_tint';
  static const String _kAnimIntensity = 'appearance_anim_intensity';

  static const double defaultBlur = 18;
  static const double defaultOpacity = 0.25;
  static const Color defaultTint = Colors.white;
  static const double defaultAnimationIntensity = 1.0;

  static const double minBlur = 0;
  static const double maxBlur = 40;
  static const double minOpacity = 0.05;
  static const double maxOpacity = 0.9;

  Color? _backgroundColor;
  String? _backgroundImagePath;
  double _glassBlur = defaultBlur;
  double _glassOpacity = defaultOpacity;
  Color _glassTint = defaultTint;
  double _animationIntensity = defaultAnimationIntensity;

  Color? get backgroundColor => _backgroundColor;
  String? get backgroundImagePath => _backgroundImagePath;
  double get glassBlur => _glassBlur;
  double get glassOpacity => _glassOpacity;
  Color get glassTint => _glassTint;
  double get animationIntensity => _animationIntensity;

  /// True when anything deviates from the stock look (used to show "Reset").
  bool get isCustomized =>
      _backgroundColor != null ||
      _backgroundImagePath != null ||
      (_glassBlur - defaultBlur).abs() > 0.01 ||
      (_glassOpacity - defaultOpacity).abs() > 0.01 ||
      _glassTint.toARGB32() != defaultTint.toARGB32() ||
      (_animationIntensity - defaultAnimationIntensity).abs() > 0.01;

  AppearanceProvider() {
    _ready = _loadFromPrefs();
  }

  late final Future<void> _ready;

  /// Waits for the initial preferences load to complete. Called by tests (and
  /// any code that must not race the async constructor load).
  Future<void> loadFromPrefs() => _ready;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_kBgColor)) {
        _backgroundColor = Color(prefs.getInt(_kBgColor)!);
      }
      _backgroundImagePath = prefs.getString(_kBgImage);
      _glassBlur =
          (prefs.getDouble(_kGlassBlur) ?? defaultBlur).clamp(minBlur, maxBlur);
      _glassOpacity = (prefs.getDouble(_kGlassOpacity) ?? defaultOpacity)
          .clamp(minOpacity, maxOpacity);
      _glassTint = Color(prefs.getInt(_kGlassTint) ?? defaultTint.toARGB32());
      _animationIntensity =
          (prefs.getDouble(_kAnimIntensity) ?? defaultAnimationIntensity)
              .clamp(0.0, 1.0);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading appearance preference: $e');
    }
  }

  Future<void> _save(String key, Object? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      }
    } catch (e) {
      debugPrint('Error saving appearance preference: $e');
    }
  }

  Future<void> setBackgroundColor(Color? color) async {
    _backgroundColor = color;
    notifyListeners();
    if (color == null) {
      await _save(_kBgColor, null);
    } else {
      await _save(_kBgColor, color.toARGB32());
    }
  }

  /// Copies a picked image into app-local storage (it never leaves the
  /// device) and remembers its path. Returns false on platforms where the
  /// filesystem is unavailable (web).
  Future<bool> importBackgroundImage(String sourcePath) async {
    if (kIsWeb) return false;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}${Platform.pathSeparator}appearance');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final extension = sourcePath.contains('.')
          ? sourcePath.split('.').last.toLowerCase()
          : 'jpg';
      final destination =
          '${dir.path}${Platform.pathSeparator}background.$extension';

      final previous = _backgroundImagePath;
      await File(sourcePath).copy(destination);

      _backgroundImagePath = destination;
      notifyListeners();
      await _save(_kBgImage, destination);

      // Remove the superseded local copy.
      if (previous != null &&
          previous != destination &&
          previous.contains('${Platform.pathSeparator}appearance${Platform.pathSeparator}')) {
        try {
          final oldFile = File(previous);
          if (await oldFile.exists()) await oldFile.delete();
        } catch (_) {}
      }
      return true;
    } catch (e) {
      debugPrint('Error importing background image: $e');
      return false;
    }
  }

  Future<void> clearBackgroundImage() async {
    final previous = _backgroundImagePath;
    _backgroundImagePath = null;
    notifyListeners();
    await _save(_kBgImage, null);
    if (previous != null &&
        previous.contains('${Platform.pathSeparator}appearance${Platform.pathSeparator}')) {
      try {
        final file = File(previous);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> setGlassBlur(double value) async {
    _glassBlur = value.clamp(minBlur, maxBlur);
    notifyListeners();
    await _save(_kGlassBlur, _glassBlur);
  }

  Future<void> setGlassOpacity(double value) async {
    _glassOpacity = value.clamp(minOpacity, maxOpacity);
    notifyListeners();
    await _save(_kGlassOpacity, _glassOpacity);
  }

  Future<void> setGlassTint(Color color) async {
    _glassTint = color;
    notifyListeners();
    await _save(_kGlassTint, color.toARGB32());
  }

  Future<void> setAnimationIntensity(double value) async {
    _animationIntensity = value.clamp(0.0, 1.0);
    notifyListeners();
    await _save(_kAnimIntensity, _animationIntensity);
  }

  /// Returns every preference back to its stock value.
  Future<void> resetAll() async {
    final previousImage = _backgroundImagePath;
    _backgroundColor = null;
    _backgroundImagePath = null;
    _glassBlur = defaultBlur;
    _glassOpacity = defaultOpacity;
    _glassTint = defaultTint;
    _animationIntensity = defaultAnimationIntensity;
    notifyListeners();

    await _save(_kBgColor, null);
    await _save(_kBgImage, null);
    await _save(_kGlassBlur, defaultBlur);
    await _save(_kGlassOpacity, defaultOpacity);
    await _save(_kGlassTint, defaultTint.toARGB32());
    await _save(_kAnimIntensity, defaultAnimationIntensity);

    if (previousImage != null &&
        previousImage.contains('${Platform.pathSeparator}appearance${Platform.pathSeparator}')) {
      try {
        final file = File(previousImage);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Scales an animation duration by the user's animation intensity so the
  /// whole app speeds up (or slows down) together. Intensity 0 still yields a
  /// tiny duration so navigation never feels broken.
  Duration animateDuration(Duration base) {
    final baseMs = base.inMilliseconds;
    if (baseMs <= 50) return base; // already minimal — leave untouched
    final scaled = (baseMs * _animationIntensity).round();
    return Duration(milliseconds: scaled < 50 ? 50 : scaled);
  }
}
