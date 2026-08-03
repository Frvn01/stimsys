import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/instructor_model.dart';
import '../../providers/admin_provider.dart';
import 'desktop_admin_login_screen.dart';

class DesktopSuperAdminDashboardScreen extends StatefulWidget {
  const DesktopSuperAdminDashboardScreen({super.key});

  @override
  State<DesktopSuperAdminDashboardScreen> createState() =>
      _DesktopSuperAdminDashboardScreenState();
}

class _DesktopSuperAdminDashboardScreenState
    extends State<DesktopSuperAdminDashboardScreen> {
  String _searchQuery = '';

  // ── Design tokens ─────────────────────────────────────
  static const _bg      = Color(0xFF060B14);
  static const _sidebar = Color(0xFF07101F);
  static const _surface = Color(0xFF0D1526);
  static const _card    = Color(0xFF111D30);
  static const _border  = Color(0xFF1E2D44);
  static const _accent  = Color(0xFFDC2626);
  static const _accentSoft = Color(0xFFEF4444);
  static const _gold    = Color(0xFFF59E0B);
  static const _green   = Color(0xFF10B981);
  static const _purple  = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(children: [
        _buildSidebar(),
        Container(width: 1, color: _border),
        Expanded(child: _buildMain()),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SIDEBAR
  // ═══════════════════════════════════════════════════════
  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: _sidebar,
      child: Column(children: [
        // Brand
        Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.shield_rounded, color: _accentSoft, size: 16),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STIMSYS',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Super Admin',
                    style: GoogleFonts.inter(
                        color: _accentSoft,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ]),
            ]),
          ]),
        ),

        Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16)),
        const SizedBox(height: 16),

        // Nav (just instructors for super admin)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _navItem(Icons.manage_accounts_rounded, 'Instructors', true),
        ),

        const Spacer(),

        // Developer badge
        Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.code_rounded, color: _accentSoft, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Developer',
                  style: GoogleFonts.inter(
                      color: _accentSoft, fontSize: 11, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              Text('Super Admin',
                  style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 9)),
            ])),
          ]),
        ),

        // Logout
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
                          color: Colors.red[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? _accent.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        if (isActive) ...[
          Container(
            width: 3, height: 18,
            decoration: BoxDecoration(
              color: _accent, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
        ],
        Icon(icon, color: isActive ? _accentSoft : const Color(0xFF4B5E78), size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.inter(
                color: isActive ? Colors.white : const Color(0xFF4B5E78),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MAIN CONTENT
  // ═══════════════════════════════════════════════════════
  Widget _buildMain() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final instructors = provider.instructors
            .where((i) => _searchQuery.isEmpty ||
                i.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (i.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (i.department?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
            .toList();

        return Container(
          color: _bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider, instructors),
              Expanded(child: _buildTable(provider, instructors)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AdminProvider provider, List<Instructor> filtered) {
    final total = provider.instructors.length;
    final active = provider.instructors.where((i) => i.isActive).length;
    final pending = provider.instructors.where((i) => i.isActive && !i.qrUsed).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title row
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Instructor Management',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Register teachers and issue login QR codes',
                style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 13)),
          ])),
          // Refresh button
          _iconBtn(Icons.refresh_rounded, () => provider.loadInstructors()),
          const SizedBox(width: 10),
          // Register button
          ElevatedButton.icon(
            onPressed: () => _showRegisterDialog(context, provider),
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: Text('Register Instructor',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),

        const SizedBox(height: 22),

        // Stat row
        Row(children: [
          _miniStat('Total Instructors', '$total', Icons.group_rounded, _purple),
          const SizedBox(width: 12),
          _miniStat('Active', '$active', Icons.check_circle_outline_rounded, _green),
          const SizedBox(width: 12),
          _miniStat('Pending QR Scan', '$pending', Icons.qr_code_rounded, _gold),
        ]),

        const SizedBox(height: 22),

        // Search
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: _surface,
            hintText: 'Search instructors by name, email or department…',
            hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[700], size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3B4F6B), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            _th('Name & Department', flex: 3),
            _th('Email', flex: 3),
            _th('QR Status', flex: 2),
            _th('Status', flex: 1),
            _th('Registered', flex: 2),
            _th('Actions', flex: 2),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTable(AdminProvider provider, List<Instructor> instructors) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
      );
    }
    if (instructors.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.group_off_rounded, color: Colors.grey[800], size: 56),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No instructors registered yet.\nTap "Register Instructor" to add the first one.'
                : 'No instructors match "$_searchQuery".',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
          ),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        child: ListView.separated(
          itemCount: instructors.length,
          separatorBuilder: (_, __) => Container(height: 1, color: _border),
          itemBuilder: (context, idx) =>
              _buildRow(context, provider, instructors[idx], idx),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, AdminProvider provider,
      Instructor instructor, int idx) {
    final isEven = idx % 2 == 0;
    final qrStatus = instructor.qrUsed
        ? ('Used', _green, Icons.check_circle_rounded)
        : ('Pending', _gold, Icons.schedule_rounded);

    return Container(
      color: isEven ? _surface : _card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Name & department
          Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    instructor.fullName.isNotEmpty
                        ? instructor.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        color: _accentSoft,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(instructor.fullName,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                if (instructor.department != null)
                  Text(instructor.department!,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF4B5E78), fontSize: 11),
                      overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),

          // Email
          Expanded(
            flex: 3,
            child: Text(
              instructor.email ?? '—',
              style: GoogleFonts.inter(color: const Color(0xFF6B7E99), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // QR Status
          Expanded(
            flex: 2,
            child: Row(children: [
              Icon(qrStatus.$3, color: qrStatus.$2, size: 14),
              const SizedBox(width: 6),
              Text(qrStatus.$1,
                  style: GoogleFonts.inter(
                      color: qrStatus.$2, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),

          // Active status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: instructor.isActive
                    ? _green.withValues(alpha: 0.10)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                instructor.isActive ? 'Active' : 'Inactive',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: instructor.isActive ? _green : Colors.red[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Registered date
          Expanded(
            flex: 2,
            child: Text(
              instructor.createdAt != null
                  ? DateFormat('MMM d, yyyy').format(instructor.createdAt!)
                  : '—',
              style: GoogleFonts.inter(color: const Color(0xFF4B5E78), fontSize: 12),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(children: [
              // Show QR
              _actionBtn(
                icon: Icons.qr_code_rounded,
                tooltip: instructor.qrUsed ? 'Re-issue QR' : 'Show QR',
                color: _gold,
                onTap: () => _showQrDialog(context, provider, instructor),
              ),
              const SizedBox(width: 6),
              // Toggle active
              _actionBtn(
                icon: instructor.isActive
                    ? Icons.person_off_rounded
                    : Icons.person_rounded,
                tooltip: instructor.isActive ? 'Deactivate' : 'Reactivate',
                color: instructor.isActive ? Colors.orange[400]! : _green,
                onTap: () => _toggleActive(context, provider, instructor),
              ),
              const SizedBox(width: 6),
              // Delete
              _actionBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Remove Instructor',
                color: Colors.red[400]!,
                onTap: () => _confirmDelete(context, provider, instructor),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════

  void _showRegisterDialog(BuildContext context, AdminProvider provider) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _border)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: _accentSoft, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Register Instructor',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ]),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogField(nameCtrl, 'Full Name *', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _dialogField(emailCtrl, 'Email', Icons.email_outlined),
              const SizedBox(height: 14),
              _dialogField(deptCtrl, 'Department', Icons.business_outlined),
              const SizedBox(height: 14),
              _dialogField(phoneCtrl, 'Phone', Icons.phone_outlined),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(error!,
                      style: GoogleFonts.inter(color: _accentSoft, fontSize: 12)),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
            ),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        setS(() => error = 'Full name is required.');
                        return;
                      }
                      setS(() { isLoading = true; error = null; });
                      try {
                        final newInstructor = await provider.registerInstructor(
                          fullName: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          department: deptCtrl.text.trim().isEmpty ? null : deptCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showQrDialog(context, provider, newInstructor, isNew: true);
                        }
                      } catch (e) {
                        setS(() {
                          isLoading = false;
                          error = 'Failed to register: ${e.toString()}';
                        });
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: Text('Register & Generate QR',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, AdminProvider provider,
      Instructor instructor, {bool isNew = false}) async {
    // Re-fetch instructor to guarantee qr_token is present (may be null in list cache)
    Instructor current = instructor;
    if (current.id != null && current.qrToken == null) {
      final fresh = await provider.getInstructorById(current.id!);
      if (fresh != null) current = fresh;
    }

    final qrKey = GlobalKey();

    // ignore: use_build_context_synchronously
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _border)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: _gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  isNew ? 'QR Code Generated!' : 'Instructor QR Code',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                Text(current.fullName,
                    style: GoogleFonts.inter(
                        color: Colors.grey[600], fontSize: 12)),
              ]),
            ),
          ]),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (current.qrUsed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange[400], size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This QR code has already been used. '
                        'Re-issue a new one to allow this instructor to log in again.',
                        style: GoogleFonts.inter(
                            color: Colors.orange[400], fontSize: 12),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await provider.regenerateQrToken(current.id!);
                    if (updated != null) setS(() => current = updated);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text('Re-issue New QR Code',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                // QR Code display
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: QrImageView(
                      data: current.qrToken ?? '',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Always-visible Regenerate button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await provider.regenerateQrToken(current.id!);
                      if (updated != null) setS(() => current = updated);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: Text('Regenerate QR Token',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info
                if (isNew)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded, color: _green, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Show this QR code to the instructor. '
                          'They scan it once to log in. '
                          'It will be invalidated after first use.',
                          style: GoogleFonts.inter(color: _green, fontSize: 12),
                        ),
                      ),
                    ]),
                  ),

                const SizedBox(height: 14),

                // Token display + copy
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07101F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        current.qrToken ?? '',
                        style: GoogleFonts.sourceCodePro(
                            color: _gold, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: Color(0xFF4B5E78), size: 16),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: current.qrToken ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Token copied to clipboard',
                                style: GoogleFonts.inter(fontSize: 12)),
                            backgroundColor: _green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ),
              ],
            ]),
          ),
          actions: [
            // Save QR Image button
            if (!current.qrUsed && current.qrToken != null)
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final boundary = qrKey.currentContext!.findRenderObject()
                        as RenderRepaintBoundary;
                    final image = await boundary.toImage(pixelRatio: 4.0);
                    final byteData =
                        await image.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData == null) return;
                    final bytes = byteData.buffer.asUint8List();

                    Directory dir;
                    if (Platform.isWindows) {
                      dir = await getApplicationDocumentsDirectory();
                    } else {
                      dir = await getApplicationDocumentsDirectory();
                    }
                    final fileName =
                        'QR_${current.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
                    final file = File('${dir.path}/$fileName');
                    await file.writeAsBytes(bytes);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'QR saved → ${file.path}',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          backgroundColor: _green,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Save failed: $e',
                              style: GoogleFonts.inter(fontSize: 12)),
                          backgroundColor: Colors.red[700]!,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_alt_rounded, size: 16),
                label: Text('Save QR',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _surface,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _border)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Done',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, AdminProvider provider,
      Instructor instructor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _border)),
        title: Text(
          instructor.isActive ? 'Deactivate Instructor?' : 'Reactivate Instructor?',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          instructor.isActive
              ? 'This will immediately revoke ${instructor.fullName}\'s access. Their session will be invalidated.'
              : 'This will re-enable ${instructor.fullName}\'s account. They will need a new QR code to log in.',
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: instructor.isActive ? _accent : _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              instructor.isActive ? 'Deactivate' : 'Reactivate',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    if (instructor.isActive) {
      await provider.deactivateInstructor(instructor.id!);
    } else {
      await provider.reactivateInstructor(instructor.id!);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AdminProvider provider,
      Instructor instructor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _border)),
        title: Text(
          'Remove Instructor?',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete ${instructor.fullName} and their QR token. '
          'This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await provider.deleteInstructor(instructor.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${instructor.fullName} removed',
                style: GoogleFonts.inter(fontSize: 12)),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e',
                style: GoogleFonts.inter(fontSize: 12)),
            backgroundColor: Colors.red[700]!,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────
  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFF4B5E78), fontSize: 10, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }

  Widget _th(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.inter(
                color: const Color(0xFF4B5E78),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

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

  Widget _actionBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: _surface,
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[700], size: 17),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B4F6B), width: 1.5),
        ),
      ),
    );
  }
}
