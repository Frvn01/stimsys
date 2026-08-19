import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import 'desktop_student_registry_screen.dart';
import 'desktop_subject_management_screen.dart';
import 'desktop_attendance_tracker_screen.dart';
import 'desktop_grade_gallery_screen.dart';
import 'desktop_modules_screen.dart';
import 'desktop_assessment_screen.dart';
import 'desktop_student_grades_screen.dart';
import 'desktop_announcements_screen.dart';
import 'desktop_appeals_screen.dart';
import 'desktop_admin_login_screen.dart';

class DesktopAdminDashboardScreen extends StatefulWidget {
  const DesktopAdminDashboardScreen({super.key});

  @override
  State<DesktopAdminDashboardScreen> createState() =>
      _DesktopAdminDashboardScreenState();
}

class _DesktopAdminDashboardScreenState
    extends State<DesktopAdminDashboardScreen> {
  int _selectedIndex = 0;

  // ── Design tokens ─────────────────────────────────────────────────
  static const _bg        = Color(0xFF0F172A);
  static const _sidebar   = Color(0xFF0C1321);
  static const _surface   = Color(0xFF1A2235);
  static const _border    = Color(0xFF232D3F);
  static const _accent    = Color(0xFF6366F1);

  final _screens = const [
    _DesktopPlaceholder(),
    DesktopStudentRegistryScreen(),
    DesktopSubjectManagementScreen(),
    DesktopAttendanceTrackerScreen(),
    DesktopGradeGalleryScreen(),
    DesktopModulesScreen(),
    DesktopAssessmentScreen(),
    DesktopStudentGradesScreen(),
    DesktopAnnouncementsScreen(),
    DesktopAppealsScreen(),
  ];

  static const _navItems = [
    (icon: Icons.dashboard_rounded,       label: 'Dashboard'),
    (icon: Icons.people_rounded,          label: 'Students'),
    (icon: Icons.book_rounded,            label: 'Subjects'),
    (icon: Icons.fact_check_rounded,      label: 'Attendance'),
    (icon: Icons.photo_library_rounded,   label: 'Grade Gallery'),
    (icon: Icons.folder_copy_rounded,     label: 'Modules'),
    (icon: Icons.assignment_rounded,      label: 'Assessments'),
    (icon: Icons.grade_rounded,           label: 'Grades'),
    (icon: Icons.campaign_rounded,        label: 'Announcements'),
    (icon: Icons.gavel_rounded,           label: 'Appeals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        _buildSidebar(),
        Container(width: 1, color: _border),
        Expanded(
          child: _selectedIndex == 0
              ? _buildDashboardHome()
              : IndexedStack(
                  index: _selectedIndex - 1,
                  children: _screens.sublist(1),
                ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SIDEBAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSidebar() {
    final provider = context.watch<AdminProvider>();
    return Container(
      width: 220,
      color: _sidebar,
      child: Column(children: [
        // ── Brand ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STIMSYS',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              Text('Admin Panel',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),

        Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16)),
        const SizedBox(height: 10),

        // ── Nav items ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: List.generate(_navItems.length, (idx) {
              final item = _navItems[idx];
              final isActive = _selectedIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedIndex = idx),
                    hoverColor: const Color(0xFF1E2D42),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? _accent.withValues(alpha: 0.10) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        // Active left indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 3,
                          height: isActive ? 18 : 0,
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: isActive ? 10 : 0),
                        Icon(item.icon,
                            color: isActive ? _accent : const Color(0xFF4B5E78),
                            size: 18),
                        const SizedBox(width: 10),
                        Text(item.label,
                            style: GoogleFonts.inter(
                                color: isActive ? Colors.white : const Color(0xFF4B5E78),
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const Spacer(),

        // ── Instructor card ──
        Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_rounded, color: _accent, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(provider.currentInstructor?.fullName ?? 'Instructor',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text('Instructor',
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 10)),
            ])),
          ]),
        ),

        // ── Logout ──
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await context.read<AdminProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DesktopAdminLoginScreen()),
                    (_) => false,
                  );
                }
              },
              hoverColor: Colors.red.withValues(alpha: 0.06),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(Icons.logout_rounded, color: Colors.red[400], size: 16),
                  const SizedBox(width: 10),
                  Text('Log out',
                      style: GoogleFonts.inter(
                          color: Colors.red[400], fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDashboardHome() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) => _DesktopHomeContent(
        provider: provider,
        onNavigate: (idx) => setState(() => _selectedIndex = idx),
      ),
    );
  }
}

class _DesktopPlaceholder extends StatelessWidget {
  const _DesktopPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

// ═══════════════════════════════════════════════════════════════════
// DASHBOARD HOME
// ═══════════════════════════════════════════════════════════════════
class _DesktopHomeContent extends StatefulWidget {
  final AdminProvider provider;
  final void Function(int) onNavigate;
  const _DesktopHomeContent({required this.provider, required this.onNavigate});

  @override
  State<_DesktopHomeContent> createState() => _DesktopHomeContentState();
}

class _DesktopHomeContentState extends State<_DesktopHomeContent> {
  int _todayAttendance = 0;

  static const _bg      = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A2235);
  static const _border  = Color(0xFF232D3F);
  static const _accent  = Color(0xFF6366F1);
  static const _green   = Color(0xFF10B981);
  static const _amber   = Color(0xFFF59E0B);
  static const _purple  = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await widget.provider.loadAll();
    final count = await widget.provider.getTodayAttendanceCount();
    if (mounted) setState(() => _todayAttendance = count);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$_greeting, ${widget.provider.currentInstructor?.fullName ?? 'Instructor'}',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 13)),
            ])),
            _iconBtn(Icons.refresh_rounded, _load),
          ]),

          const SizedBox(height: 28),

          // ── Stat Cards ────────────────────────────────────────────
          Row(children: [
            _StatCard(label: 'Total Students',  value: '${p.totalStudents}',   icon: Icons.people_alt_rounded,  color: _accent),
            const SizedBox(width: 14),
            _StatCard(label: "Today's Present", value: '$_todayAttendance',     icon: Icons.how_to_reg_rounded,  color: _green),
            const SizedBox(width: 14),
            _StatCard(label: 'Subjects',        value: '${p.totalSubjects}',   icon: Icons.book_rounded,        color: _amber),
            const SizedBox(width: 14),
            _StatCard(label: 'Confirmed',       value: '${p.confirmedStudents}',icon: Icons.verified_rounded,   color: _purple),
          ]),

          const SizedBox(height: 28),

          // ── Section label ─────────────────────────────────────────
          Text('Quick Actions',
              style: GoogleFonts.inter(
                  color: const Color(0xFF8B9AB2), fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 12),

          // ── Quick Actions ─────────────────────────────────────────
          Row(children: [
            _QuickAction(
              icon: Icons.people_rounded,
              label: 'Student Registry',
              subtitle: 'Manage and confirm students',
              color: _accent,
              onTap: () => widget.onNavigate(1),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              icon: Icons.book_rounded,
              label: 'Subject Management',
              subtitle: 'Create subjects & enroll',
              color: _amber,
              onTap: () => widget.onNavigate(2),
            ),
            const SizedBox(width: 12),
            _QuickAction(
              icon: Icons.fact_check_rounded,
              label: 'Attendance Tracker',
              subtitle: 'View & edit attendance records',
              color: _green,
              onTap: () => widget.onNavigate(3),
            ),
          ]),

          const SizedBox(height: 28),

          // ── System status ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: _green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text('System Active',
                  style: GoogleFonts.inter(
                      color: _green, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              Expanded(
                child: Text('STIMSYS is running normally. All services operational.',
                    style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 12)),
              ),
              Text('v1.0.0',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF2E3D54), fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: const Color(0xFF4B5E78), size: 18),
          ),
        ),
      );
}

// ── Stat Card ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF232D3F)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78), fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────────
class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xFF1E2D42) : const Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _hovered
                      ? widget.color.withValues(alpha: 0.3)
                      : const Color(0xFF232D3F)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF4B5E78), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ])),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: _hovered ? widget.color : const Color(0xFF2E3D54), size: 13),
            ]),
          ),
        ),
      ),
    );
  }
}
