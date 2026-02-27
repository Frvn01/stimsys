import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows a dialog with a QR code payload for a quiz or exam.
/// Payload format: QUIZ|<course>|<assessment>|<student>|<score>|<iso-timestamp>
Future<void> showQuizQrDialog(
  BuildContext context, {
  required String courseName,
  required String assessmentTitle,
  required String studentName,
  required int score,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final timestamp = DateTime.now().toIso8601String();
  final payload = 'QUIZ|$courseName|$assessmentTitle|$studentName|$score|$timestamp';

  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$assessmentTitle QR',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.L,
                    size: 200,
                    gapless: false,
                    backgroundColor: isDark ? Colors.black : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.blueAccent,
                  ),
                ),

                const SizedBox(height: 12),

                SelectableText(
                  payload,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}