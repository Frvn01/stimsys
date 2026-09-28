import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../providers/appearance_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/glass_dialog.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersionChanges();
    });
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

    final duration =
        context.read<AppearanceProvider>().animateDuration(
              const Duration(milliseconds: 300),
            );

    Future.delayed(Duration.zero, () {
      if (_pageController != null && _pageController!.hasClients) {
        try {
          _pageController!.animateToPage(
            newIndex,
            duration: duration,
            curve: Curves.easeInOut,
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      }
    });
  }

  Future<void> _checkVersionChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenV1_6_Changes') ?? false;

    if (!hasSeen && mounted) {
      await prefs.setBool('hasSeenV1_6_Changes', true);
      // Clear older seen-flags so the fresh notice always shows.
      await prefs.remove('hasSeenV1_5_1_Changes');
      await prefs.remove('hasSeenV1_5_Changes');
      await prefs.remove('hasSeenV1_4_Changes');
      if (!mounted) return;

      showGlassDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GlassDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.new_releases_rounded,
                    color: Color(0xFF6366F1),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to Version 1.6! 🚀',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "What's new in this update:",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildChangeItem(Icons.shield_rounded, 'ACLC Houses', 'Official house mascot logos now shown on your profile badge & selector.', isDark),
                const SizedBox(height: 12),
                _buildChangeItem(Icons.bolt_rounded, 'Optimization', 'Faster, smoother performance across all screens.', isDark),
                const SizedBox(height: 12),
                _buildChangeItem(Icons.auto_awesome_rounded, 'Glassmorphism', 'A fresh iOS 27-style frosted glass design throughout the app.', isDark),
                const SizedBox(height: 12),
                _buildChangeItem(Icons.vibration_rounded, 'Haptics', 'Subtle tactile feedback on navigation and interactive elements.', isDark),
                const SizedBox(height: 12),
                _buildChangeItem(Icons.palette_rounded, 'Make It Yours', 'Adaptive colors, background, glass & animation — all in Profile → Appearance.', isDark),
                const SizedBox(height: 24),
                // ── Special Thanks ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFF87171),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            children: const [
                              TextSpan(text: 'Special thanks to '),
                              TextSpan(
                                text: 'CJ Medina',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF818CF8),
                                ),
                              ),
                              TextSpan(text: ' for providing the ACLC house mascot images!'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Awesome, Let\'s Go!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildChangeItem(IconData icon, String title, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appearance = context.watch<AppearanceProvider>();
    // Adaptive scaffold color: use the user's chosen background color if set,
    // otherwise fall back to the theme default.
    final bgColor = appearance.backgroundColor ??
        (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA));

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Customizable local-only background (color / wallpaper / drift).
          const Positioned.fill(child: AppBackground()),
          SafeArea(
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
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(isDark, appearance),
    );
  }

  /// Apple iOS 27 Liquid Island Dock — Icon-only design with frosted refraction.
  /// The dock tint adapts to the user's chosen background color.
  Widget _buildModernBottomNav(bool isDark, AppearanceProvider appearance) {
    const items = [
      (
        activeIcon: CupertinoIcons.house_fill,
        inactiveIcon: CupertinoIcons.house,
        tooltip: 'Home',
      ),
      (
        activeIcon: CupertinoIcons.book_fill,
        inactiveIcon: CupertinoIcons.book,
        tooltip: 'Courses',
      ),
      (
        activeIcon: CupertinoIcons.pencil_circle_fill,
        inactiveIcon: CupertinoIcons.pencil_circle,
        tooltip: 'Quiz & Exams',
      ),
      (
        activeIcon: CupertinoIcons.calendar,
        inactiveIcon: CupertinoIcons.calendar_today,
        tooltip: 'Calendar',
      ),
      (
        activeIcon: CupertinoIcons.chart_bar_square_fill,
        inactiveIcon: CupertinoIcons.chart_bar_square,
        tooltip: 'Class Record',
      ),
      (
        activeIcon: CupertinoIcons.person_crop_circle_fill,
        inactiveIcon: CupertinoIcons.person_crop_circle,
        tooltip: 'Profile',
      ),
    ];

    final opacity = appearance.glassOpacity;
    final blur = appearance.glassBlur.clamp(20.0, 45.0);
    // Adaptive dock tint: blend the chosen background color into the dock.
    final Color dockBase = appearance.backgroundColor ??
        (isDark ? const Color(0xFF0F172A) : Colors.white);

    const activeColor = Color(0xFF6366F1);
    final inactiveColor =
        isDark ? const Color(0xFF8E9BAE) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: dockBase.withValues(alpha: (opacity + 0.50).clamp(0.68, 0.92)),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.90),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: activeColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                items.length,
                (index) {
                  final isActive = _currentIndex == index;
                  final item = items[index];
                  return Expanded(
                    child: _buildNavItem(
                      activeIcon: item.activeIcon,
                      inactiveIcon: item.inactiveIcon,
                      tooltip: item.tooltip,
                      isActive: isActive,
                      isDark: isDark,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _updateIndex(index);
                      },
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
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String tooltip,
    required bool isActive,
    required bool isDark,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final duration = context
        .watch<AppearanceProvider>()
        .animateDuration(const Duration(milliseconds: 260));

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: 46,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor.withValues(alpha: isDark ? 0.22 : 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? activeColor.withValues(alpha: isDark ? 0.42 : 0.30)
                        : Colors.transparent,
                    width: 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: isDark ? 0.25 : 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: isActive ? 1.12 : 1.0,
                    duration: duration,
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isActive ? activeIcon : inactiveIcon,
                      size: isActive ? 22 : 21,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: isActive ? 14 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.8),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
