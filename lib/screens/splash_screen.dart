import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../services/biometric_service.dart';
import '../theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SplashScreen({super.key, required this.themeProvider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final minSplashDuration = Future.delayed(const Duration(milliseconds: 900));
    final provider = context.read<StudentProvider>();
    final sessionTask = provider.restoreSession();

    final results = await Future.wait([minSplashDuration, sessionTask]);
    final isRestored = results[1] as bool;

    if (mounted) {
      if (isRestored && provider.currentStudent != null) {
        final biometricEnabled = await BiometricService.isBiometricEnabled();
        final biometricAvailable = await BiometricService.isBiometricAvailable();

        bool authenticated = true;
        if (biometricEnabled && biometricAvailable) {
          authenticated = await BiometricService.authenticate(
            reason: 'Unlock STIMSYS Student App',
          );
        }

        if (mounted) {
          if (authenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  email: provider.currentStudent!.usn,
                  themeProvider: widget.themeProvider,
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    LoginScreen(themeProvider: widget.themeProvider),
              ),
            );
          }
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final hasRegistered = prefs.getBool('hasRegistered') ?? false;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => hasRegistered
                ? LoginScreen(themeProvider: widget.themeProvider)
                : WelcomeScreen(themeProvider: widget.themeProvider),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(isDark ? 0.1 : 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'STIMSYS',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Student Information System',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}