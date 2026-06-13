import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

class QRScannerScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const QRScannerScreen({
    super.key, 
    this.title = "Scan QR Code",
    this.subtitle = "Align the QR code within the frame",
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanned = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = Colors.black.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Scanner
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture barcodeCapture) {
              if (_isScanned) return; 
              final List<Barcode> barcodes = barcodeCapture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  setState(() => _isScanned = true);
                  // Brief haptic or feedback could be here
                  Navigator.pop(context, code);
                  return;
                }
              }
            },
          ),
          
          // Dark Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(overlayColor, BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      
                      // Flashlight Toggle
                      ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (context, state, child) {
                          final hasTorch = state.torchState == TorchState.on;
                          return GestureDetector(
                            onTap: () => _controller.toggleTorch(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: hasTorch 
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2) 
                                  : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: hasTorch 
                                  ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)) 
                                  : null,
                              ),
                              child: Icon(
                                hasTorch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: hasTorch ? const Color(0xFFF59E0B) : Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  margin: const EdgeInsets.only(bottom: 60),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Frame Corners overlay
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: _getBorder(alignment),
        ),
      ),
    );
  }

  Border _getBorder(Alignment alignment) {
    const BorderSide side = BorderSide(color: Color(0xFF6366F1), width: 4);
    if (alignment == Alignment.topLeft) {
      return const Border(top: side, left: side);
    } else if (alignment == Alignment.topRight) {
      return const Border(top: side, right: side);
    } else if (alignment == Alignment.bottomLeft) {
      return const Border(bottom: side, left: side);
    } else {
      return const Border(bottom: side, right: side);
    }
  }
}