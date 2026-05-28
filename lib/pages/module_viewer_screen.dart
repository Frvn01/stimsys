import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// In-app viewer that renders learning modules.
/// - PDFs are loaded natively and instantly using SfPdfViewer.
/// - Google Slides and PPTs are loaded via WebView with a non-blocking top progress bar.
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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadProgress = 0;
  bool _isPdf = false;
  String _targetUrl = '';

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

    if (!_isPdf) {
      _initWebView();
    } else {
      _isLoading = false; // SfPdfViewer manages its own loading state
    }
  }

  void _initWebView() {
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
            // Ignore minor sub-resource errors (analytics, ads, etc.)
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
  }

  /// Convert various Google Drive / Docs / Slides URLs into optimal preview URLs.
  String _toPreviewUrl(String url) {
    // Extract file ID from Google Drive URLs
    final driveFileRegex =
        RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = driveFileRegex.firstMatch(url);
    
    if (match != null) {
      final fileId = match.group(1);
      if (_isPdf) {
        // Return direct download link for native PDF viewer
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      } else {
        // Return preview link for webview
        return 'https://drive.google.com/file/d/$fileId/preview';
      }
    }

    // Google Slides Native Presentations
    final slidesRegex =
        RegExp(r'docs\.google\.com/presentation/d/([a-zA-Z0-9_-]+)');
    final slidesMatch = slidesRegex.firstMatch(url);
    if (slidesMatch != null) {
      final fileId = slidesMatch.group(1);
      return 'https://docs.google.com/presentation/d/$fileId/preview';
    }

    return url;
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
      ),
      body: _hasError
          ? _buildErrorState(isDark)
          : _isPdf
              ? _buildPdfViewer(isDark)
              : _buildWebViewer(isDark),
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
    return Stack(
      children: [
        // Background loading indicator (visible before WebView loads content)
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
        
        // The WebView content itself
        WebViewWidget(controller: _controller),
        
        // Slim top progress bar (non-blocking)
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadProgress > 0 ? _loadProgress / 100 : null, // null shows running indicator if stuck at 0%
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
              'Unable to Load File',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The file could not be displayed. Please check that the link is valid and the file is publicly shared.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  if (!_isPdf) {
                    _isLoading = true;
                    _loadProgress = 0;
                  }
                });
                if (!_isPdf) {
                  _controller.loadRequest(Uri.parse(_targetUrl));
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
