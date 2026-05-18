import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../widgets/cards/feature_card.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'admin/admin_login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const WelcomeScreen({super.key, required this.themeProvider});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Secret admin passage state
  int _secretTapCount = 0;
  DateTime? _firstTapTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Hidden admin passage: long-press the footer text 5 times within 10 seconds
  void _handleSecretTap() {
    final now = DateTime.now();

    if (_firstTapTime == null ||
        now.difference(_firstTapTime!).inSeconds > 10) {
      // Reset counter if too much time has passed
      _secretTapCount = 0;
      _firstTapTime = now;
    }

    _secretTapCount++;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _firstTapTime = null;
      // Show admin PIN dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AdminLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildThemeToggle(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildHeader(isDark),
                    const SizedBox(height: 50),
                    _buildFeatures(),
                  ],
                ),
              ),
            ),
            _buildBottomSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => widget.themeProvider.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.yellow[300] : Colors.orange[700],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.school,
          size: 70,
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        const Text(
          'Welcome to STIMSYS',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your modern student information platform',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return const Column(
      children: [
        FeatureCard(
          icon: Icons.dashboard_rounded,
          title: 'Smart Dashboard',
          description: 'View all your academic data in one place',
        ),
        SizedBox(height: 16),
        FeatureCard(
          icon: Icons.assignment_rounded,
          title: 'Track Progress',
          description: 'Monitor assignments and performance metrics',
        ),
        SizedBox(height: 16),
        FeatureCard(
          icon: Icons.grade_rounded,
          title: 'Grade Tracking',
          description: 'Stay updated with your academic progress',
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(themeProvider: widget.themeProvider),
                  ),
                );
              },
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToLogin(),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // SECRET ADMIN PASSAGE — long-press 5× to access admin
          GestureDetector(
            onTap: _handleSecretTap,
            child: Text(
              'Powered by krepsusenpai and Rensusama',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(themeProvider: widget.themeProvider),
      ),
    );
  }
}