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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  items.length,
                  (index) => Expanded(
                    child: _buildNavItem(
                      icon: items[index]['icon'] as IconData,
                      label: items[index]['label'] as String,
                      isActive: _currentIndex == index,
                      isDark: isDark,
                      onTap: () => _updateIndex(index),
                    ),
                  ),
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 6 : 4,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? const Color(0xFF6366F1)
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            if (isActive)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}