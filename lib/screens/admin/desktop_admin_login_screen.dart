import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'desktop_admin_dashboard_screen.dart';

class DesktopAdminLoginScreen extends StatefulWidget {
  const DesktopAdminLoginScreen({super.key});

  @override
  State<DesktopAdminLoginScreen> createState() =>
      _DesktopAdminLoginScreenState();
}

class _DesktopAdminLoginScreenState extends State<DesktopAdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _pinCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isError = false;
  bool _obscure = true;
  bool _isLoading = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // ── Design tokens ──────────────────────────────────────────────
  static const _bgPrimary  = Color(0xFF0F172A);
  static const _bgCard     = Color(0xFF1E293B);
  static const _border     = Color(0xFF2D3B52);
  static const _accent     = Color(0xFF6366F1);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pinCtrl.text.length < 4) return;
    setState(() { _isLoading = true; _isError = false; });

    await Future.delayed(const Duration(milliseconds: 200)); // feel responsive

    final provider = context.read<AdminProvider>();
    final success = provider.authenticatePin(_pinCtrl.text.trim());

    if (success) {
      provider.loadAll();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const DesktopAdminDashboardScreen()),
        );
      }
    } else {
      _pinCtrl.clear();
      setState(() { _isError = true; _isLoading = false; });
      _shakeCtrl.forward(from: 0);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      body: Row(
        children: [
          // ── Left brand panel ───────────────────────────────────
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
                  // Feature list
                  ..._features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: f.$3.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(f.$2, color: f.$3, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(f.$1,
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

          // ── Right login panel ───────────────────────────────────
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text('Admin Login',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Enter your PIN to access the admin panel',
                          style: GoogleFonts.inter(
                              color: Colors.grey[600], fontSize: 14)),

                      const SizedBox(height: 36),

                      // PIN label
                      Text('Admin PIN',
                          style: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),

                      // PIN field (shake on error)
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) {
                          final dx = _shakeCtrl.isAnimating
                              ? (_shakeAnim.value * 2 - 1) * 8
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
                          child: TextField(
                            controller: _pinCtrl,
                            focusNode: _focusNode,
                            obscureText: _obscure,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofocus: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) {
                              if (_isError) setState(() => _isError = false);
                            },
                            onSubmitted: (_) => _submit(),
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                letterSpacing: 8,
                                fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _bgCard,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isError ? _errorColor : _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isError
                                        ? _errorColor
                                        : _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color:
                                        _isError ? _errorColor : _accent,
                                    width: 2),
                              ),
                              hintText: '••••',
                              hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[700],
                                  fontSize: 20,
                                  letterSpacing: 8),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.grey[600],
                                    size: 20),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Error message
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _isError
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: _errorColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Incorrect PIN. Please try again.',
                                      style: GoogleFonts.inter(
                                          color: _errorColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor:
                                _accent.withValues(alpha: 0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('Sign In',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Footer
                      Center(
                        child: Text(
                          'STIMSYS Desktop Admin v1.0',
                          style: GoogleFonts.inter(
                              color: Colors.grey[700],
                              fontSize: 11),
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
    );
  }

  static const _features = [
    ('Student Registry & Enrollment', Icons.people_rounded,    Color(0xFF6366F1)),
    ('Subject Management & QR Codes', Icons.book_rounded,      Color(0xFFF59E0B)),
    ('Attendance Tracker & Editor',   Icons.bar_chart_rounded, Color(0xFF10B981)),
    ('Real-time Supabase Sync',       Icons.cloud_done_rounded,Color(0xFF8B5CF6)),
  ];
}
