import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/theme_provider.dart';
import '../pages/overview_page.dart';
import '../pages/courses_page.dart';
import '../pages/quiz_page.dart';
import '../pages/calendar_page.dart';
import '../pages/grades_page.dart';
import '../pages/profile_page.dart';

class DashboardScreen extends StatefulWidget {
  final String email;
  final ThemeProvider themeProvider;

  const DashboardScreen({
    super.key,
    required this.email,
    required this.themeProvider,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _updateIndex(int newIndex) {
    if (newIndex == _currentIndex) return;

    setState(() {
      _currentIndex = newIndex;
    });

    Future.delayed(Duration.zero, () {
      if (_pageController != null && _pageController!.hasClients) {
        try {
          _pageController!.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            OverviewPage(
              email: widget.email,
              themeProvider: widget.themeProvider,
            ),
            CoursesPage(
              themeProvider: widget.themeProvider,
            ),
            QuizPage(
              themeProvider: widget.themeProvider,
            ),
            CalendarPage(
              themeProvider: widget.themeProvider,
            ),
            GradesPage(
              themeProvider: widget.themeProvider,
            ),
            ProfilePage(
              email: widget.email,
              themeProvider: widget.themeProvider,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(isDark),
    );
  }

  Widget _buildModernBottomNav(bool isDark) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.cast_for_education_rounded, 'label': 'Courses'},
      {'icon': Icons.quiz_rounded, 'label': 'Quiz'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Calendar'},
      {'icon': Icons.assessment_rounded, 'label': 'Grades'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                items.length,
                (index) {
                  final isActive = _currentIndex == index;
                  return Expanded(
                    flex: isActive ? 5 : 2,
                    child: _buildNavItem(
                      icon: items[index]['icon'] as IconData,
                      label: items[index]['label'] as String,
                      isActive: isActive,
                      isDark: isDark,
                      onTap: () => _updateIndex(index),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF6366F1);
    final inactiveColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 6,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.2 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: isDark ? 0.35 : 0.25)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isActive ? 1.0 : 0.0,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
