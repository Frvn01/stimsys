import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimsys/services/biometric_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('BiometricService defaults to disabled', () async {
    final enabled = await BiometricService.isBiometricEnabled();
    expect(enabled, isFalse);
  });

  test('BiometricService saves and retrieves enabled preference', () async {
    await BiometricService.setBiometricEnabled(true);
    final enabled = await BiometricService.isBiometricEnabled();
    expect(enabled, isTrue);

    await BiometricService.setBiometricEnabled(false);
    final disabled = await BiometricService.isBiometricEnabled();
    expect(disabled, isFalse);
  });
}
