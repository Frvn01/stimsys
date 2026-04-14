import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import 'student_registry_screen.dart';
import 'subject_management_screen.dart';
import 'attendance_scanner_screen.dart';
import 'attendance_tracker_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _AdminHomeTab(),
    StudentRegistryScreen(),
    SubjectManagementScreen(),
    AttendanceScannerScreen(),
    AttendanceTrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (icon: Icons.dashboard_rounded, label: 'Home'),
      (icon: Icons.people_rounded, label: 'Students'),
      (icon: Icons.book_rounded, label: 'Subjects'),
      (icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
      (icon: Icons.bar_chart_rounded, label: 'Tracker'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1226),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final isActive = _currentIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF6366F1).withValues(alpha: 0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedScale(
                      scale: isActive ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(item.icon,
                        color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
                        size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(item.label,
                      style: GoogleFonts.inter(
                        color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      )),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════════

class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  int _todayAttendance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<AdminProvider>();
    await provider.loadAll();
    final count = await provider.getTodayAttendanceCount();
    if (mounted) setState(() => _todayAttendance = count);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) => SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF111633),
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Top bar ──
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('STIMSYS Admin', style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ])),
                _circleBtn(Icons.refresh_rounded, () => _load()),
                const SizedBox(width: 10),
                _circleBtn(Icons.logout_rounded, () {
                  provider.logout();
                  Navigator.of(context).pop();
                }, color: Colors.red[800]!),
              ]),

              const SizedBox(height: 24),

              // ── Hero banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1060), Color(0xFF0F0A3A)],
                  ),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('SYSTEM ACTIVE', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text('Instructor\nPortal', style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 8),
                  Text('Rens Joshua Cardaña', style: GoogleFonts.inter(color: const Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Stats grid ──
              Text('Overview', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(label: 'Total Students', value: '${provider.totalStudents}', icon: Icons.people_alt_rounded, color: const Color(0xFF6366F1)),
                  _StatCard(label: "Today's Present", value: '$_todayAttendance', icon: Icons.how_to_reg_rounded, color: const Color(0xFF10B981)),
                  _StatCard(label: 'Subjects', value: '${provider.totalSubjects}', icon: Icons.book_rounded, color: const Color(0xFFF59E0B)),
                  _StatCard(label: 'Confirmed', value: '${provider.confirmedStudents}', icon: Icons.verified_rounded, color: const Color(0xFF8B5CF6)),
                ],
              ),

              const SizedBox(height: 24),

              // ── Quick actions ──
              Text('Quick Actions', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              _QuickAction(
                icon: Icons.qr_code_scanner_rounded, label: 'Scan for Attendance',
                subtitle: 'Mark attendance by scanning student QR',
                color: const Color(0xFF10B981),
                onTap: () {
                  context.findAncestorStateOfType<_AdminDashboardScreenState>()
                    ?.setState(() => context.findAncestorStateOfType<_AdminDashboardScreenState>()?._currentIndex = 3);
                },
              ),
              const SizedBox(height: 10),
              _QuickAction(
                icon: Icons.qr_code_rounded, label: 'Register Student',
                subtitle: 'Scan student\'s registration QR to confirm',
                color: const Color(0xFF6366F1),
                onTap: () {
                  context.findAncestorStateOfType<_AdminDashboardScreenState>()
                    ?.setState(() => context.findAncestorStateOfType<_AdminDashboardScreenState>()?._currentIndex = 1);
                },
              ),
              const SizedBox(height: 10),
              _QuickAction(
                icon: Icons.add_box_rounded, label: 'Create Subject',
                subtitle: 'Add new subject with schedule & room',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  context.findAncestorStateOfType<_AdminDashboardScreenState>()
                    ?.setState(() => context.findAncestorStateOfType<_AdminDashboardScreenState>()?._currentIndex = 2);
                },
              ),
              const SizedBox(height: 10),
              _QuickAction(
                icon: Icons.bar_chart_rounded, label: 'View Attendance Log',
                subtitle: 'Track present, late and absent per subject',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  context.findAncestorStateOfType<_AdminDashboardScreenState>()
                    ?.setState(() => context.findAncestorStateOfType<_AdminDashboardScreenState>()?._currentIndex = 4);
                },
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? Colors.white).withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: color ?? Colors.white70, size: 20),
      ),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111633),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

// ── Quick Action ──
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111633),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11)),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[700], size: 20),
        ]),
      ),
    );
  }
}
