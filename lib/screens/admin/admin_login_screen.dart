import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_dashboard_screen.dart';
import '../qr_scanner_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isError = false;
  bool _checkingSession = true;
  String _errorMsg = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

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
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      setState(() => _checkingSession = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    setState(() { _isError = false; _errorMsg = ''; });

    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerScreen(
          title: 'Scan Login QR',
          subtitle: 'Scan your instructor QR code to log in',
        ),
      ),
    );

    if (token == null || token.isEmpty || !mounted) return;

    setState(() => _isLoading = true);

    final provider = context.read<AdminProvider>();
    final success = await provider.authenticateInstructorQr(token);

    if (!mounted) return;
    if (success) {
      await provider.loadAll();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMsg = 'Invalid or already-used QR code.\nContact your Super Admin for a new one.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Animated QR icon ────────────────────────────
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.25),
                        const Color(0xFF6366F1).withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: Color(0xFF6366F1), size: 44),
                ),
              ),

              const SizedBox(height: 30),

              Text('Instructor Login',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),

              const SizedBox(height: 10),

              Text(
                'Scan your one-time QR code\nto access the admin panel',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.grey[500], fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 48),

              // Error card
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _isError
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMsg,
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFEF4444),
                                    fontSize: 13,
                                    height: 1.4)),
                          ),
                        ]),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Scan button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _scanQr,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  label: Text(
                    _isLoading ? 'Verifying…' : 'Scan QR Code',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor:
                        const Color(0xFF6366F1).withValues(alpha: 0.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.grey[700], size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your QR code is provided by the Super Admin. Each code is valid for one use only.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.grey[700], fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Text('STIMSYS Admin • v1.0',
                  style: GoogleFonts.inter(
                      color: Colors.grey[800], fontSize: 11)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
