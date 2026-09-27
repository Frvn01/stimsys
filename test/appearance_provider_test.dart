import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimsys/providers/appearance_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppearanceProvider defaults', () {
    test('starts with the stock look', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();

      expect(provider.backgroundColor, isNull);
      expect(provider.backgroundImagePath, isNull);
      expect(provider.glassBlur, AppearanceProvider.defaultBlur);
      expect(provider.glassOpacity, AppearanceProvider.defaultOpacity);
      expect(provider.glassTint, AppearanceProvider.defaultTint);
      expect(provider.animationIntensity, 1.0);
      expect(provider.isCustomized, isFalse);
    });

    test('stays device-local — values round-trip via SharedPreferences only',
        () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();
      await provider.setBackgroundColor(const Color(0xFF8B5CF6));
      await provider.setGlassBlur(32);
      await provider.setGlassOpacity(0.6);
      await provider.setGlassTint(const Color(0xFF0F172A));
      await provider.setAnimationIntensity(0.3);
      expect(provider.isCustomized, isTrue);

      // A fresh provider (same device prefs) sees the same values.
      final reloaded = AppearanceProvider();
      await reloaded.loadFromPrefs();
      expect(reloaded.backgroundColor, const Color(0xFF8B5CF6));
      expect(reloaded.glassBlur, 32);
      expect(reloaded.glassOpacity, closeTo(0.6, 0.001));
      expect(reloaded.glassTint, const Color(0xFF0F172A));
      expect(reloaded.animationIntensity, closeTo(0.3, 0.001));
      expect(reloaded.isCustomized, isTrue);
    });
  });

  group('AppearanceProvider clamping', () {
    test('blur, opacity and intensity stay in range', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();

      await provider.setGlassBlur(999);
      expect(provider.glassBlur, AppearanceProvider.maxBlur);

      await provider.setGlassBlur(-5);
      expect(provider.glassBlur, AppearanceProvider.minBlur);

      await provider.setGlassOpacity(5.0);
      expect(provider.glassOpacity, AppearanceProvider.maxOpacity);

      await provider.setGlassOpacity(0.0);
      expect(provider.glassOpacity, AppearanceProvider.minOpacity);

      await provider.setAnimationIntensity(3.0);
      expect(provider.animationIntensity, 1.0);

      await provider.setAnimationIntensity(-1.0);
      expect(provider.animationIntensity, 0.0);
    });
  });

  group('animateDuration', () {
    test('uses the base duration at full intensity', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();
      expect(
        provider.animateDuration(const Duration(milliseconds: 300)),
        const Duration(milliseconds: 300),
      );
    });

    test('scales down with intensity but never below 50ms', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();
      await provider.setAnimationIntensity(0.5);
      expect(
        provider.animateDuration(const Duration(milliseconds: 300)),
        const Duration(milliseconds: 150),
      );

      await provider.setAnimationIntensity(0.0);
      expect(
        provider.animateDuration(const Duration(milliseconds: 300)),
        const Duration(milliseconds: 50),
      );
    });

    test('leaves already-minimal durations untouched', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();
      await provider.setAnimationIntensity(0.0);
      expect(
        provider.animateDuration(const Duration(milliseconds: 30)),
        const Duration(milliseconds: 30),
      );
      expect(provider.animateDuration(Duration.zero), Duration.zero);
    });
  });

  group('resetAll', () {
    test('clears every customization and reports stock state', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();
      await provider.setBackgroundColor(const Color(0xFF0EA5E9));
      await provider.setGlassBlur(10);
      await provider.setGlassTint(const Color(0xFF334155));
      await provider.setAnimationIntensity(0.1);
      expect(provider.isCustomized, isTrue);

      await provider.resetAll();
      expect(provider.backgroundColor, isNull);
      expect(provider.backgroundImagePath, isNull);
      expect(provider.glassBlur, AppearanceProvider.defaultBlur);
      expect(provider.glassOpacity, AppearanceProvider.defaultOpacity);
      expect(provider.glassTint, AppearanceProvider.defaultTint);
      expect(provider.animationIntensity, 1.0);
      expect(provider.isCustomized, isFalse);

      // Reset also persists so the stock look survives a restart.
      final reloaded = AppearanceProvider();
      await reloaded.loadFromPrefs();
      expect(reloaded.isCustomized, isFalse);
    });

    test('clearing just the background color keeps other settings', () async {
      final provider = AppearanceProvider();
      await provider.loadFromPrefs();
      await provider.setBackgroundColor(const Color(0xFF0EA5E9));
      await provider.setGlassBlur(25);

      await provider.setBackgroundColor(null);
      expect(provider.backgroundColor, isNull);
      expect(provider.glassBlur, 25);
      expect(provider.isCustomized, isTrue);
    });
  });
}
