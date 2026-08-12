import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'desktop_admin_dashboard_screen.dart';
import 'desktop_super_admin_login_screen.dart';

class DesktopAdminLoginScreen extends StatefulWidget {
  const DesktopAdminLoginScreen({super.key});

  @override
  State<DesktopAdminLoginScreen> createState() =>
      _DesktopAdminLoginScreenState();
}

class _DesktopAdminLoginScreenState extends State<DesktopAdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _tokenCtrl = TextEditingController();
  final _tokenFocus = FocusNode();

  bool _isError = false;
  bool _isLoading = false;
  bool _checkingSession = true;
  String _errorMsg = '';

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // ── Design tokens ─────────────────────────────────────
  static const _bgPrimary = Color(0xFF0F172A);
  static const _bgCard    = Color(0xFF1E293B);
  static const _border    = Color(0xFF2D3B52);
  static const _accent    = Color(0xFF6366F1);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    // Try to restore an existing instructor session
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryRestoreSession());
  }

  Future<void> _tryRestoreSession() async {
    final provider = context.read<AdminProvider>();
    final restored = await provider.restoreInstructorSession();
    if (!mounted) return;
    if (restored) {
      await provider.loadAll();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DesktopAdminDashboardScreen()),
      );
    } else {
      if (mounted) setState(() => _checkingSession = false);
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _tokenFocus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) return;

    setState(() { _isLoading = true; _isError = false; });

    final provider = context.read<AdminProvider>();
    final success = await provider.authenticateInstructorQr(token);

    if (success) {
      await provider.loadAll();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DesktopAdminDashboardScreen()),
        );
      }
    } else {
      _tokenCtrl.clear();
      setState(() {
        _isError = true;
        _isLoading = false;
        _errorMsg = 'Invalid or inactive QR token. Contact your Super Admin.';
      });
      _shakeCtrl.forward(from: 0);
      _tokenFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgPrimary,
      body: Row(children: [
        // ── Left brand panel ─────────────────────────────
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF0B1120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 28),
                Text('STIMSYS',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Student Information Management System',
                    style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5)),
                const SizedBox(height: 48),
                ..._features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: f.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(f.icon, color: f.color, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(f.label,
                              style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),

        // Divider
        Container(width: 1, color: _border),

        // ── Right login panel ─────────────────────────────
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_rounded,
                            color: _accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Instructor Login',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      'Paste your one-time QR token to access the admin panel.',
                      style: GoogleFonts.inter(
                          color: Colors.grey[600], fontSize: 13),
                    ),

                    const SizedBox(height: 36),

                    // How-to hint
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _accent.withValues(alpha: 0.12)),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: _accent.withValues(alpha: 0.7), size: 15),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your Super Admin will provide a QR code. '
                            'Scan it with your phone, or copy the token here.',
                            style: GoogleFonts.inter(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // Token label
                    Text('QR Token',
                        style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),

                    // Token field with shake
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        final dx = _shakeCtrl.isAnimating
                            ? (_shakeAnim.value * 2 - 1) * 8
                            : 0.0;
                        return Transform.translate(
                            offset: Offset(dx, 0), child: child);
                      },
                      child: TextField(
                        controller: _tokenCtrl,
                        focusNode: _tokenFocus,
                        autofocus: true,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_isError) setState(() => _isError = false);
                        },
                        style: GoogleFonts.sourceCodePro(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 1),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _bgCard,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          hintText: 'Paste token here…',
                          hintStyle: GoogleFonts.inter(
                              color: Colors.grey[700], fontSize: 13),
                          prefixIcon: Icon(Icons.key_rounded,
                              color: _isError
                                  ? _errorColor
                                  : Colors.grey[600],
                              size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _isError ? _errorColor : _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _isError ? _errorColor : _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: _isError ? _errorColor : _accent,
                                width: 2),
                          ),
                        ),
                      ),
                    ),

                    // Error
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isError
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: _errorColor, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(_errorMsg,
                                      style: GoogleFonts.inter(
                                          color: _errorColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ]),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.login_rounded, size: 18),
                        label: Text(
                          _isLoading ? 'Verifying…' : 'Sign In with QR Token',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor:
                              _accent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Super Admin link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const DesktopSuperAdminLoginScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded,
                                color: Colors.grey[700], size: 13),
                            const SizedBox(width: 6),
                            Text('Super Admin Portal',
                                style: GoogleFonts.inter(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.grey[800])),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text('STIMSYS Desktop Admin v1.0',
                          style: GoogleFonts.inter(
                              color: Colors.grey[800], fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  static const _features = [
    (label: 'Student Registry & Enrollment',  icon: Icons.people_rounded,     color: Color(0xFF6366F1)),
    (label: 'Subject Management & QR Codes',  icon: Icons.book_rounded,       color: Color(0xFFF59E0B)),
    (label: 'Attendance Tracker & Editor',    icon: Icons.bar_chart_rounded,  color: Color(0xFF10B981)),
    (label: 'Real-time Supabase Sync',        icon: Icons.cloud_done_rounded, color: Color(0xFF8B5CF6)),
  ];
}
