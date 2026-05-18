import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/student_provider.dart';
import '../widgets/common/custom_text_field.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const LoginScreen({super.key, required this.themeProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usnController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_usnController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final student = await context
          .read<StudentProvider>()
          .login(_usnController.text.trim(), _passwordController.text);

      if (student != null && mounted) {
        // Block unconfirmed students — they must be scanned by admin first
        if (!student.isConfirmed) {
          _showUnconfirmedDialog(student.fullName, student.usn);
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasRegistered', true);
        await prefs.setString('usn', _usnController.text.trim());
        await prefs.setString('password', _passwordController.text);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              email: student.usn,
              themeProvider: widget.themeProvider,
            ),
          ),
        );
      } else if (mounted) {
        _showSnackBar('Invalid USN or password', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Connection error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showUnconfirmedDialog(String name, String usn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFFF59E0B),
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Account Pending Confirmation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Hi $name, your account has been created but must be confirmed by an admin before you can log in.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 What to do:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1. Open the Sign Up screen\n2. Show your QR code to your instructor/admin\n3. Once scanned, you can log in',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK, Got It',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(isDark),
                const SizedBox(height: 40),
                _buildHeader(isDark),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'USN',
                  hint: 'Enter your USN (numbers only)',
                  icon: Icons.badge_rounded,
                  controller: _usnController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_rounded,
                  controller: _passwordController,
                  isPassword: true,
                  isPasswordVisible: _passwordVisible,
                  onPasswordToggle: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showSnackBar('Coming Soon');
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildSignUpLink(isDark),
                const SizedBox(height: 24),
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                WelcomeScreen(themeProvider: widget.themeProvider),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: const Icon(Icons.arrow_back_ios_rounded, size: 18),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      SignUpScreen(themeProvider: widget.themeProvider),
                ),
              );
            },
            child: const Text(
              'Sign up',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Text(
        'Powered by krepsusenpai and Rensusama',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
        ),
      ),
    );
  }
}