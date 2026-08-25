import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// In-app and web-compatible viewer that renders learning modules.
/// - Web: Provides an interactive document launcher and Google Drive viewer card.
/// - Mobile/Desktop: PDFs are loaded natively using SfPdfViewer; Slides via WebView.
class ModuleViewerScreen extends StatefulWidget {
  final String title;
  final String fileUrl;

  const ModuleViewerScreen({
    super.key,
    required this.title,
    required this.fileUrl,
  });

  @override
  State<ModuleViewerScreen> createState() => _ModuleViewerScreenState();
}

class _ModuleViewerScreenState extends State<ModuleViewerScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadProgress = 0;
  bool _isPdf = false;
  String _targetUrl = '';
  String _browserUrl = '';

  @override
  void initState() {
    super.initState();
    _checkFileTypeAndInit();
  }

  void _checkFileTypeAndInit() {
    final url = widget.fileUrl.toLowerCase();
    final title = widget.title.toLowerCase();

    // Determine if the file is a PDF
    if (url.contains('.pdf') || title.contains('pdf')) {
      _isPdf = true;
    } else {
      // If it doesn't explicitly look like slides/ppt, default to PDF
      final isSlides = url.contains('presentation') ||
          url.contains('docs.google.com/presentation') ||
          title.contains('ppt') ||
          title.contains('powerpoint') ||
          title.contains('slide');
      _isPdf = !isSlides;
    }

    _targetUrl = _toPreviewUrl(widget.fileUrl);
    _browserUrl = _toBrowserUrl(widget.fileUrl);

    if (kIsWeb) {
      _isLoading = false;
    } else if (!_isPdf) {
      _initWebView();
    } else {
      _isLoading = false; // SfPdfViewer manages its own loading state
    }
  }

  void _initWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0F172A))
        ..enableZoom(true)
        ..setOnConsoleMessage((_) {}) // suppress console noise
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _loadProgress = 0;
                });
              }
            },
            onProgress: (progress) {
              if (mounted) setState(() => _loadProgress = progress);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame ?? false) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                  });
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_targetUrl));
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Convert Google Drive / Docs / Slides URLs into optimal preview URLs.
  String _toPreviewUrl(String url) {
    final driveFileRegex =
        RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = driveFileRegex.firstMatch(url);
    
    if (match != null) {
      final fileId = match.group(1);
      if (_isPdf && !kIsWeb) {
        // Return direct download link for native PDF viewer on mobile
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      } else {
        // Return preview link for webview/browser
        return 'https://drive.google.com/file/d/$fileId/preview';
      }
    }

    final slidesRegex =
        RegExp(r'docs\.google\.com/presentation/d/([a-zA-Z0-9_-]+)');
    final slidesMatch = slidesRegex.firstMatch(url);
    if (slidesMatch != null) {
      final fileId = slidesMatch.group(1);
      return 'https://docs.google.com/presentation/d/$fileId/preview';
    }

    return url;
  }

  /// Clean browser URL for external opening in new tab or Google Drive.
  String _toBrowserUrl(String url) {
    final driveFileRegex =
        RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = driveFileRegex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
    }

    final slidesRegex =
        RegExp(r'docs\.google\.com/presentation/d/([a-zA-Z0-9_-]+)');
    final slidesMatch = slidesRegex.firstMatch(url);
    if (slidesMatch != null) {
      final fileId = slidesMatch.group(1);
      return 'https://docs.google.com/presentation/d/$fileId/present';
    }

    return url;
  }

  Future<void> _launchInBrowser() async {
    final uri = Uri.parse(_browserUrl.isNotEmpty ? _browserUrl : widget.fileUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isPdf ? Icons.picture_as_pdf_rounded : Icons.slideshow_rounded,
                color: const Color(0xFF6366F1),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isPdf ? 'PDF Document' : 'Google Slides',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            color: const Color(0xFF6366F1),
            tooltip: 'Open in new tab',
            onPressed: _launchInBrowser,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: kIsWeb
          ? _buildWebDocViewer(isDark)
          : _hasError
              ? _buildErrorState(isDark)
              : _isPdf
                  ? _buildPdfViewer(isDark)
                  : _buildWebViewer(isDark),
    );
  }

  Widget _buildWebDocViewer(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final isSlides = !_isPdf;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Format Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSlides ? Icons.slideshow_rounded : Icons.picture_as_pdf_rounded,
                    color: const Color(0xFF6366F1),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSlides ? 'Google Slides Presentation' : 'PDF Document',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Click the button below to open and view this learning material in Google Drive / Docs with full zoom and reading controls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Launch Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _launchInBrowser,
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: Text(
                      isSlides ? 'Open Presentation' : 'Open PDF Document',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Direct link preview button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _launchInBrowser,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text(
                      'View in Google Drive',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                      side: BorderSide(color: borderCol),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer(bool isDark) {
    return SfPdfViewer.network(
      _targetUrl,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      onDocumentLoadFailed: (details) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      },
    );
  }

  Widget _buildWebViewer(bool isDark) {
    if (_controller == null) {
      return _buildErrorState(isDark);
    }
    return Stack(
      children: [
        if (_isLoading)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF6366F1)),
                const SizedBox(height: 12),
                Text(
                  'Loading document...',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadProgress > 0 ? _loadProgress / 100 : null,
              minHeight: 3,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Preview File',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The document could not be rendered in-app. You can open it directly in your browser.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _launchInBrowser,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text('Open in Browser',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  if (!_isPdf) {
                    _isLoading = true;
                    _loadProgress = 0;
                  }
                });
                if (!_isPdf && _controller != null) {
                  _controller!.loadRequest(Uri.parse(_targetUrl));
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
