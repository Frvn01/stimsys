import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimsys/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeProvider initializes with default light mode (false)', () async {
    final provider = ThemeProvider();
    expect(provider.isDarkMode, isFalse);
  });

  test('ThemeProvider saves and loads dark mode state', () async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': true});
    final provider = ThemeProvider();
    
    // Give async _loadThemeFromPrefs a moment to complete
    await Future.delayed(Duration.zero);
    
    expect(provider.isDarkMode, isTrue);
  });

  test('toggleTheme updates state and saves to SharedPreferences', () async {
    final provider = ThemeProvider();
    await provider.toggleTheme();

    expect(provider.isDarkMode, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('is_dark_mode'), isTrue);
  });
}
