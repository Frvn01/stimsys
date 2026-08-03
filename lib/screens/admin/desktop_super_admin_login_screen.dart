import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'desktop_super_admin_dashboard_screen.dart';

class DesktopSuperAdminLoginScreen extends StatefulWidget {
  const DesktopSuperAdminLoginScreen({super.key});

  @override
  State<DesktopSuperAdminLoginScreen> createState() =>
      _DesktopSuperAdminLoginScreenState();
}

class _DesktopSuperAdminLoginScreenState
    extends State<DesktopSuperAdminLoginScreen>
    with TickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isError = false;
  bool _obscure = true;
  bool _isLoading = false;
  String _errorMsg = '';

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Design tokens ─────────────────────────────────────
  static const _bg       = Color(0xFF060B14);
  static const _bgCard   = Color(0xFF0D1526);
  static const _surface  = Color(0xFF111D30);
  static const _border   = Color(0xFF1E2D44);
  static const _accent   = Color(0xFFDC2626); // Red — super admin is danger-level access
  static const _accentSoft = Color(0xFFEF4444);
  static const _gold     = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isError = true;
        _errorMsg = 'Please fill in all fields.';
      });
      _shakeCtrl.forward(from: 0);
      return;
    }

    setState(() { _isLoading = true; _isError = false; });

    final provider = context.read<AdminProvider>();
    await Future.delayed(const Duration(milliseconds: 300));

    final success = provider.authenticateSuperAdmin(username, password);

    if (success) {
      await provider.loadInstructors();
      if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DesktopSuperAdminDashboardScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
    } else {
      setState(() {
        _isError = true;
        _isLoading = false;
        _errorMsg = 'Invalid credentials. Access denied.';
      });
      _passwordCtrl.clear();
      _shakeCtrl.forward(from: 0);
      _passwordFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Left brand panel ────────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFF07101F),
                child: Stack(
                  children: [
                    // Subtle grid pattern
                    Positioned.fill(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    // Glow at center
                    Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _accent.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Shield icon with glow
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.shield_rounded,
                                color: _accentSoft, size: 38),
                          ),

                          const SizedBox(height: 28),

                          Text('SUPER ADMIN',
                              style: GoogleFonts.inter(
                                  color: _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4)),
                          const SizedBox(height: 8),
                          Text('STIMSYS',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text('Developer Control Portal',
                              style: GoogleFonts.inter(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400)),

                          const SizedBox(height: 56),

                          // Warning badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _accent.withValues(alpha: 0.2)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.warning_amber_rounded, color: _gold, size: 16),
                              const SizedBox(width: 10),
                              Text('Restricted Access — Developer Only',
                                  style: GoogleFonts.inter(
                                      color: _gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),

                          const SizedBox(height: 40),

                          // Feature list
                          ..._features.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: f.color.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Icon(f.icon, color: f.color, size: 14),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(f.label,
                                        style: GoogleFonts.inter(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Container(width: 1, color: _border),

            // ── Right login panel ────────────────────────────────
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded,
                                color: _accentSoft, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text('Super Admin',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 6),
                        Text('Developer-level access. Credentials required.',
                            style: GoogleFonts.inter(
                                color: Colors.grey[600], fontSize: 13)),

                        const SizedBox(height: 40),

                        // Username
                        _buildLabel('Username'),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (context, child) {
                            final dx = _shakeCtrl.isAnimating
                                ? (_shakeAnim.value * 2 - 1) * 9
                                : 0.0;
                            return Transform.translate(
                                offset: Offset(dx, 0), child: child);
                          },
                          child: _buildTextField(
                            controller: _usernameCtrl,
                            focusNode: _usernameFocus,
                            hint: 'Enter your username',
                            icon: Icons.person_outline_rounded,
                            isError: _isError,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (context, child) {
                            final dx = _shakeCtrl.isAnimating
                                ? (_shakeAnim.value * 2 - 1) * 9
                                : 0.0;
                            return Transform.translate(
                                offset: Offset(dx, 0), child: child);
                          },
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (e) {
                              if (e is KeyDownEvent &&
                                  e.logicalKey == LogicalKeyboardKey.enter) {
                                _submit();
                              }
                            },
                            child: _buildTextField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              hint: '••••••••••••',
                              icon: Icons.lock_outline_rounded,
                              isError: _isError,
                              obscure: _obscure,
                              onObscureToggle: () =>
                                  setState(() => _obscure = !_obscure),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ),

                        // Error
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _isError
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _accent.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: _accent.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.block_rounded,
                                          color: _accentSoft, size: 14),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_errorMsg,
                                            style: GoogleFonts.inter(
                                                color: _accentSoft,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ]),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 28),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              disabledBackgroundColor:
                                  _accent.withValues(alpha: 0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.login_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Access Control Panel',
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Footer
                        Center(
                          child: Text(
                            'STIMSYS Super Admin • Developer Portal',
                            style: GoogleFonts.inter(
                                color: Colors.grey[800], fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required bool isError,
    bool obscure = false,
    VoidCallback? onObscureToggle,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      onChanged: (_) { if (_isError) setState(() => _isError = false); },
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: _bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
        prefixIcon: Icon(icon, color: isError ? _accentSoft : Colors.grey[600], size: 18),
        suffixIcon: onObscureToggle != null
            ? IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey[600], size: 18),
                onPressed: onObscureToggle)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isError ? _accent : _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isError ? _accent : _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isError ? _accentSoft : const Color(0xFF3B4F6B), width: 2),
        ),
      ),
    );
  }

  static const _features = [
    (label: 'Register & manage instructor accounts', icon: Icons.person_add_rounded,     color: Color(0xFFEF4444)),
    (label: 'Generate one-time login QR codes',      icon: Icons.qr_code_2_rounded,      color: Color(0xFFF59E0B)),
    (label: 'Deactivate / re-issue credentials',     icon: Icons.manage_accounts_rounded, color: Color(0xFF10B981)),
    (label: 'Full STIMSYS system oversight',         icon: Icons.shield_rounded,          color: Color(0xFF8B5CF6)),
  ];
}

// ── Subtle grid background painter ──────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2235).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
