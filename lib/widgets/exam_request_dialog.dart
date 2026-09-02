import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/enrollment_model.dart';
import '../providers/student_provider.dart';

class ExamRequestDialog extends StatefulWidget {
  final Enrollment enrollment;
  final bool isDark;
  final Color primaryColor;

  const ExamRequestDialog({
    super.key,
    required this.enrollment,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<ExamRequestDialog> createState() => _ExamRequestDialogState();
}

class _ExamRequestDialogState extends State<ExamRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _proctorNameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();

  Uint8List? _signatureBytes;
  String? _signatureName;

  Uint8List? _docBytes;
  String? _docName;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final student = context.read<StudentProvider>().currentStudent;
    _sectionCtrl.text = student?.section ?? '';
    _courseCtrl.text = student?.course ?? '';
  }

  @override
  void dispose() {
    _proctorNameCtrl.dispose();
    _sectionCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isSignature}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          if (isSignature) {
            _signatureBytes = bytes;
            _signatureName = picked.name;
          } else {
            _docBytes = bytes;
            _docName = picked.name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_signatureBytes == null && _docBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least the Proctor Signature or Document photo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<StudentProvider>();
      final subjectId = widget.enrollment.subjectId;
      final subjectName = widget.enrollment.subjectTitle ?? 'Subject';

      await provider.submitExamRequest(
        subjectId: subjectId,
        proctorName: _proctorNameCtrl.text.trim(),
        section: _sectionCtrl.text.trim(),
        course: _courseCtrl.text.trim(),
        subjectName: subjectName,
        signatureBytes: _signatureBytes,
        documentBytes: _docBytes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exam Request / Permit submitted successfully for $subjectName!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.assignment_turned_in_rounded,
                        color: widget.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exam Request & Permit',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.enrollment.subjectTitle ?? 'Subject',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Proctor Name
                      Text('PROCTOR NAME',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700])),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _proctorNameCtrl,
                        decoration: _inputDec(
                          hint: 'Enter supervising proctor name',
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Proctor name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Course & Section Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('COURSE',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[700])),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _courseCtrl,
                                  decoration: _inputDec(
                                    hint: 'e.g. BSIT',
                                    icon: Icons.school_outlined,
                                    isDark: isDark,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'Course is required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SECTION',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[700])),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _sectionCtrl,
                                  decoration: _inputDec(
                                    hint: 'e.g. 3A',
                                    icon: Icons.group_outlined,
                                    isDark: isDark,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'Section is required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Upload Attachments Section
                      Text('ATTACH PROCTOR SIGNATURE & PERMIT',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700])),
                      const SizedBox(height: 10),

                      // Signature Picker
                      _buildUploadBox(
                        title: 'Proctor Signature Image',
                        subtitle: _signatureName ?? 'Tap to select signature photo',
                        icon: Icons.draw_rounded,
                        bytes: _signatureBytes,
                        onTap: () => _pickImage(isSignature: true),
                        onClear: _signatureBytes != null
                            ? () => setState(() {
                                  _signatureBytes = null;
                                  _signatureName = null;
                                })
                            : null,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 12),

                      // Document / Permit Picker
                      _buildUploadBox(
                        title: 'Exam Permit / Document Photo',
                        subtitle:
                            _docName ?? 'Tap to attach document / signed form',
                        icon: Icons.document_scanner_rounded,
                        bytes: _docBytes,
                        onTap: () => _pickImage(isSignature: false),
                        onClear: _docBytes != null
                            ? () => setState(() {
                                  _docBytes = null;
                                  _docName = null;
                                })
                            : null,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer / Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131B2B)
                    : Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600])),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text('Submit Request',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required Uint8List? bytes,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bytes != null
                ? const Color(0xFF10B981)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (bytes != null ? const Color(0xFF10B981) : widget.primaryColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: bytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: widget.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: bytes != null
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]))),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.redAccent, size: 18),
                onPressed: onClear,
              )
            else
              Icon(Icons.add_photo_alternate_rounded,
                  color: widget.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
      ),
    );
  }
}
