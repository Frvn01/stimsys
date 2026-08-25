import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/biometric_service.dart';
import '../theme/theme_provider.dart';
import '../models/student_model.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/custom_dropdown.dart';
import '../screens/welcome_screen.dart';
import '../providers/student_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final ThemeProvider themeProvider;

  const ProfilePage({
    super.key,
    required this.email,
    required this.themeProvider,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _usnController;
  late TextEditingController _phoneController;

  String? _selectedCourse;
  String? _selectedYear;
  String? _selectedSection;

  String _selectedFrame = 'cyber'; // 'cyber', 'flame', 'rgb', 'diamond', 'none'
  String _serverTag = '⚡ STIM';
  String _selectedHouse = 'azul'; // 'vierrdy', 'giallio', 'roxxo', 'azul', 'cahel'
  late TextEditingController _customTagController;

  bool _isLoaded = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricLabel = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _usnController = TextEditingController();
    _phoneController = TextEditingController();
    _customTagController = TextEditingController(text: _serverTag);

    _checkBiometrics();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      final student = provider.currentStudent;

      if (student != null) {
        _lastNameController.text = student.lastName;
        _firstNameController.text = student.firstName;
        _middleNameController.text = student.middleName ?? '';
        _usnController.text = student.usn;
        _phoneController.text = student.phone ?? '';

        _selectedCourse = StudentConstants.courses.contains(student.course) 
            ? student.course : null;
        _selectedYear = StudentConstants.years.contains(student.yearLevel) 
            ? student.yearLevel : null;
        _selectedSection = StudentConstants.sections.contains(student.section) 
            ? student.section : null;

        _loadCustomizations(student.usn);
      }
      setState(() => _isLoaded = true);
    });
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final label = await BiometricService.getBiometricTypeLabel();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricLabel = label;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to enable $_biometricLabel login',
      );
      if (authenticated) {
        await BiometricService.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _biometricEnabled = true);
          _showSnackBar('$_biometricLabel login enabled successfully!');
        }
      } else {
        if (mounted) {
          _showSnackBar('Biometric authentication failed', isError: true);
        }
      }
    } else {
      await BiometricService.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        _showSnackBar('$_biometricLabel login disabled.');
      }
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _usnController.dispose();
    _phoneController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => _getImage(ImageSource.camera),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _imageSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => _getImage(ImageSource.gallery),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (context.read<StudentProvider>().currentStudent?.profileImageUrl != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final student = context.read<StudentProvider>().currentStudent;
                      if (student != null) _deleteProfileImage(student);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                    label: const Text('Remove Photo', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF6366F1)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        File finalFile = File(pickedFile.path);

        if (Platform.isAndroid || Platform.isIOS) {
          try {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final croppedFile = await ImageCropper().cropImage(
              sourcePath: pickedFile.path,
              uiSettings: [
                AndroidUiSettings(
                  toolbarTitle: 'Crop Profile Photo',
                  toolbarColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  toolbarWidgetColor: isDark ? Colors.white : Colors.black87,
                  initAspectRatio: CropAspectRatioPreset.square,
                  lockAspectRatio: true,
                  hideBottomControls: false,
                ),
                IOSUiSettings(
                  title: 'Crop Profile Photo',
                  aspectRatioLockEnabled: true,
                  resetAspectRatioEnabled: false,
                ),
              ],
            );
            if (croppedFile != null) {
              finalFile = File(croppedFile.path);
            }
          } catch (_) {
            // Ignore cropper errors on unsupported platforms
          }
        }

        setState(() {
          _imageFile = finalFile;
        });

        // Automatically upload image to Supabase
        await _autoUploadImage(finalFile);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _autoUploadImage(File file) async {
    setState(() => _isSaving = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final (success, msg) = await context
          .read<StudentProvider>()
          .uploadProfileImage(bytes, ext);

      if (mounted) {
        if (success) {
          _showSnackBar('Profile photo updated successfully!');
          setState(() {
            _imageFile = null;
          });
        } else {
          _showSnackBar('Photo upload failed: $msg', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Photo upload error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteProfileImage(Student student) async {
    // If they picked a new local image but haven't saved, just clear it.
    if (_imageFile != null) {
      setState(() => _imageFile = null);
      return;
    }

    // Otherwise, if they have a saved remote image, ask for confirmation then delete from DB.
    if (student.profileImageUrl != null && student.profileImageUrl!.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to remove your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      setState(() => _isSaving = true);
      try {
        final (success, msg) = await context.read<StudentProvider>().deleteProfileImage();
        if (mounted) {
          _showSnackBar(msg, isError: !success);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      // Upload profile image if a new one was picked
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final ext = _imageFile!.path.split('.').last.toLowerCase();
        final (success, msg) = await context
            .read<StudentProvider>()
            .uploadProfileImage(bytes, ext);
        if (!success && mounted) {
          _showSnackBar('Image upload failed: $msg', isError: true);
        }
      }

      // TODO: persist name/course edits to Supabase when that endpoint is added
      await Future.delayed(const Duration(milliseconds: 400));

      // Persist frame, tag, and house
      final student = context.read<StudentProvider>().currentStudent;
      if (student != null) {
        await _saveCustomizations(student.usn);
      }

      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
          _isSaving = false;
        });
        _showSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Save failed: $e', isError: true);
      }
    }
  }

  void _cancelEdit() {
    final provider = context.read<StudentProvider>();
    final student = provider.currentStudent;
    setState(() {
      _isEditing = false;
      if (student != null) {
        _lastNameController.text = student.lastName;
        _firstNameController.text = student.firstName;
        _middleNameController.text = student.middleName ?? '';
        _usnController.text = student.usn;
        _phoneController.text = student.phone ?? '';
        _selectedCourse = student.course;
        _selectedYear = student.yearLevel;
        _selectedSection = student.section;
      }
      _imageFile = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    bool isSaving = false;
    bool showPass = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: Color(0xFF6366F1), size: 28),
                const SizedBox(width: 8),
                Text('Change Password', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'New Password',
                  hint: 'Enter new password',
                  icon: Icons.lock_rounded,
                  controller: newPassCtrl,
                  isPassword: true,
                  isPasswordVisible: showPass,
                  onPasswordToggle: () => setState(() => showPass = !showPass),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (newPassCtrl.text.isEmpty) {
                          _showSnackBar('Please enter a new password', isError: true);
                          return;
                        }
                        setState(() => isSaving = true);
                        try {
                          await this.context.read<StudentProvider>().changePassword(newPassCtrl.text);
                          if (mounted) {
                            Navigator.pop(ctx);
                            _showSnackBar('Password updated successfully!');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showSnackBar('Failed to update password', isError: true);
                          }
                        } finally {
                          if (mounted) setState(() => isSaving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final student = provider.currentStudent;

    if (!_isLoaded || student == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title & Actions ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEditing ? 'Update details' : 'Personal information',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_isEditing)
                    IconButton(
                      onPressed: _cancelEdit,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFFEF4444),
                      tooltip: 'Cancel',
                    ),
                  GestureDetector(
                    onTap: _isSaving ? null : _toggleEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? const Color(0xFF6366F1)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isEditing ? const Color(0xFF6366F1) : borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSaving)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(
                              _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                              size: 16,
                              color: _isEditing
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _isEditing ? 'Save' : 'Edit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isEditing
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Minimalist Hero Section (Avatar + Name + Pills) ───────────────
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      _buildAnimatedAvatarFrame(
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: _buildAvatarImageWidget(
                            _imageFile,
                            student.profileImageUrl,
                          ),
                        ),
                        _selectedFrame,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Name + Clan Server Tag Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        student.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_serverTag.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2B2D31)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3F4248)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          _serverTag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'USN: ${student.usn}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${student.course} • Year ${student.yearLevel}-${student.section}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),

                // ── Official STIMSYS House Badge Banner ──
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _showFrameAndTagCustomizer,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildHouseBannerWidget(_selectedHouse),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Discord-style Profile Badges (Raven Privilege)
                if (student.usn == '23002137800') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111214) : const Color(0xFFE3E5E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B2D31) : const Color(0xFFD1D5DB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _discordBadge(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Founder Developer',
                          tooltip: 'Founder Developer — Original Architect',
                          gradientColors: const [Color(0xFFFEE75C), Color(0xFFF59E0B)],
                          badgeColor: const Color(0xFFFEE75C),
                          textColor: Colors.black87,
                        ),
                        _discordBadge(
                          icon: Icons.terminal_rounded,
                          label: 'Core Developer',
                          tooltip: 'Core Developer — Systems Engineer',
                          gradientColors: const [Color(0xFF5865F2), Color(0xFF3B82F6)],
                          badgeColor: const Color(0xFF5865F2),
                        ),
                        _discordBadge(
                          icon: Icons.stars_rounded,
                          label: 'krepsusenpai',
                          tooltip: 'krepsusenpai — Creator',
                          gradientColors: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          badgeColor: const Color(0xFFEC4899),
                        ),
                        _discordBadge(
                          icon: Icons.bolt_rounded,
                          label: 'Full-Stack Dev',
                          tooltip: 'Full-Stack Engineer',
                          gradientColors: const [Color(0xFF57F287), Color(0xFF10B981)],
                          badgeColor: const Color(0xFF57F287),
                          textColor: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _showFrameAndTagCustomizer,
                  icon: const Icon(Icons.palette_outlined, size: 16),
                  label: const Text('Customize House, Frame & Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Minimalist Stats Row ─────────────────────────────────────────
          Row(
            children: [
              _minimalStatCard('Subjects', '${provider.enrollments.length}', isDark, surfaceColor, borderColor),
              const SizedBox(width: 12),
              _minimalStatCard('Year', student.yearLevel, isDark, surfaceColor, borderColor),
              const SizedBox(width: 12),
              _minimalStatCard('Section', student.section, isDark, surfaceColor, borderColor),
            ],
          ),
          const SizedBox(height: 24),

          // ── Personal Info Grouped Card / Edit Form ───────────────────────
          if (_isEditing)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Last Name',
                    hint: 'Enter last name',
                    icon: Icons.person_outline_rounded,
                    controller: _lastNameController,
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'First Name',
                    hint: 'Enter first name',
                    icon: Icons.person_outline_rounded,
                    controller: _firstNameController,
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Middle Name',
                    hint: 'Enter middle name',
                    icon: Icons.person_outline_rounded,
                    controller: _middleNameController,
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'USN',
                    hint: 'Enter USN',
                    icon: Icons.badge_rounded,
                    controller: _usnController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown<String>(
                    label: 'Course',
                    hint: 'Select course',
                    icon: Icons.school_rounded,
                    value: _selectedCourse,
                    items: StudentConstants.courses,
                    onChanged: (v) => setState(() => _selectedCourse = v),
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<String>(
                          label: 'Year',
                          hint: 'Year',
                          icon: Icons.calendar_today_rounded,
                          value: _selectedYear,
                          items: StudentConstants.years,
                          onChanged: (v) => setState(() => _selectedYear = v),
                          enabled: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomDropdown<String>(
                          label: 'Section',
                          hint: 'Section',
                          icon: Icons.class_rounded,
                          value: _selectedSection,
                          items: StudentConstants.sections,
                          onChanged: (v) => setState(() => _selectedSection = v),
                          enabled: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Phone',
                    hint: 'Enter phone number',
                    icon: Icons.phone_rounded,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: const Text(
                        'Change Password',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: BorderSide(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _minimalInfoTile('Full Name', student.fullName, Icons.person_outline_rounded, isDark, showDivider: true),
                  _minimalInfoTile('USN', student.usn, Icons.badge_outlined, isDark, showDivider: true),
                  _minimalInfoTile('Program', student.course, Icons.school_outlined, isDark, showDivider: true),
                  _minimalInfoTile('Year & Section', student.yearSection, Icons.class_outlined, isDark, showDivider: true),
                  _minimalInfoTile('Phone', student.phone ?? 'Not provided', Icons.phone_outlined, isDark, showDivider: true),
                  _minimalInfoTile(
                    'Registered Date',
                    student.createdAt != null
                        ? DateFormat('MMMM d, yyyy').format(student.createdAt!)
                        : 'N/A',
                    Icons.calendar_today_outlined,
                    isDark,
                    showDivider: false,
                  ),
                ],
              ),
            ),
          if (_biometricAvailable) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _biometricLabel.contains('Face')
                          ? Icons.face_rounded
                          : Icons.fingerprint_rounded,
                      color: const Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_biometricLabel Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlock app quickly using your device biometrics',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _biometricEnabled,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: _toggleBiometric,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── About Stimsys Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1)),
                          const SizedBox(width: 10),
                          Text(
                            'About Stimsys',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Version 1.4',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to Stimsys! A beautifully crafted, seamless, and highly efficient system designed to provide the best user experience.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Core Developers:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Raven Ulrich A. Fabre (krepsusenpai)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          Text(
                            '• Rens Joshua Cardaña (rensusama) - Collaborator',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text(
                'About Stimsys',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: BorderSide(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                ),
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Minimalist Logout Button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<StudentProvider>().logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        WelcomeScreen(themeProvider: widget.themeProvider),
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Minimalist Footer ─────────────────────────────────────────────
          Center(
            child: Text(
              'Powered by krepsusenpai & Rensusama',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _discordBadge({
    required IconData icon,
    required String label,
    required String tooltip,
    required List<Color> gradientColors,
    required Color badgeColor,
    Color textColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      decoration: BoxDecoration(
        color: const Color(0xFF111214),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2B2D31)),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1200.ms, curve: Curves.easeInOut),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.04, duration: 1800.ms, curve: Curves.easeInOut)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2400.ms, color: Colors.white.withValues(alpha: 0.35)),
    );
  }

  Widget _minimalStatCard(String label, String value, bool isDark, Color surface, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _minimalInfoTile(String label, String value, IconData icon, bool isDark, {required bool showDivider}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 48,
            color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  Future<void> _loadCustomizations(String usn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFrame = prefs.getString('profile_frame_$usn');
      final savedTag = prefs.getString('profile_tag_$usn');
      final savedHouse = prefs.getString('profile_house_$usn');
      if (mounted) {
        setState(() {
          if (savedFrame != null && savedFrame.isNotEmpty) {
            _selectedFrame = savedFrame;
          }
          if (savedTag != null && savedTag.isNotEmpty) {
            _serverTag = savedTag;
            _customTagController.text = savedTag;
          }
          if (savedHouse != null && savedHouse.isNotEmpty) {
            _selectedHouse = savedHouse;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile customizations: $e');
    }
  }

  Future<void> _saveCustomizations(String usn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_frame_$usn', _selectedFrame);
      await prefs.setString('profile_tag_$usn', _serverTag);
      await prefs.setString('profile_house_$usn', _selectedHouse);
    } catch (e) {
      debugPrint('Error saving profile customizations: $e');
    }
  }

  Widget _buildAvatarImageWidget(File? localFile, String? remoteUrl) {
    if (localFile != null) {
      return Image.file(
        localFile,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(),
      );
    }
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      if (remoteUrl.startsWith('data:image/')) {
        try {
          final base64String = remoteUrl.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(),
          );
        } catch (_) {
          return _avatarFallback();
        }
      }
      return Image.network(
        remoteUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return Container(
      width: 96,
      height: 96,
      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 48, color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildAnimatedAvatarFrame(Widget child, String frameType) {
    switch (frameType) {
      case 'flame':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut)
            .shimmer(duration: 1800.ms, color: Colors.amber.withValues(alpha: 0.5));
      case 'rgb':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.6))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.03, duration: 1500.ms);
      case 'diamond':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.7));
      case 'none':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 2),
          ),
          child: child,
        );
      case 'cyber':
      default:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.04, duration: 1400.ms, curve: Curves.easeInOut)
            .shimmer(duration: 2200.ms, color: Colors.white.withValues(alpha: 0.4));
    }
  }

  void _showFrameAndTagCustomizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Customize Profile Effects & Student Tag',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Frame Effect Selector ──
                    Text(
                      'Avatar Frame Animation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _frameChip('cyber', '⚡ Cyberpunk', isDark, setModalState),
                        _frameChip('flame', '🔥 Flame Pulse', isDark, setModalState),
                        _frameChip('rgb', '🌈 RGB Gamer', isDark, setModalState),
                        _frameChip('diamond', '💎 Diamond', isDark, setModalState),
                        _frameChip('none', '🛑 Classic', isDark, setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── House Selection Section ──
                    Text(
                      'STIMSYS House Badge',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        _houseSelectCard('vierrdy', 'HOUSE OF VIERRDY', '🐍', const [Color(0xFF052E16), Color(0xFF15803D)], setModalState),
                        const SizedBox(height: 6),
                        _houseSelectCard('giallio', 'HOUSE OF GIALLIO', '🦁', const [Color(0xFF422006), Color(0xFFA16207)], setModalState),
                        const SizedBox(height: 6),
                        _houseSelectCard('roxxo', 'HOUSE OF ROXXO', '🐉', const [Color(0xFF450A0A), Color(0xFFB91C1C)], setModalState),
                        const SizedBox(height: 6),
                        _houseSelectCard('azul', 'HOUSE OF AZUL', '🐺', const [Color(0xFF172554), Color(0xFF1D4ED8)], setModalState),
                        const SizedBox(height: 6),
                        _houseSelectCard('cahel', 'HOUSE OF CAHEL', '🦅', const [Color(0xFF451A03), Color(0xFFB45309)], setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Student Tag Selector ──
                    Text(
                      'Student Tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tagPresetChip('🎓 IT', isDark, setModalState),
                        _tagPresetChip('💻 CS', isDark, setModalState),
                        _tagPresetChip('🔥 TOP', isDark, setModalState),
                        _tagPresetChip('✨ PRO', isDark, setModalState),
                        _tagPresetChip('⚡ DEV', isDark, setModalState),
                        _tagPresetChip('🚀 ELITE', isDark, setModalState),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customTagController,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Or enter custom student tag',
                        hintText: 'e.g. 🚀 HERO',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                        filled: true,
                        fillColor: surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          _serverTag = val;
                        });
                        setState(() {
                          _serverTag = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          final student = context.read<StudentProvider>().currentStudent;
                          if (student != null) {
                            _saveCustomizations(student.usn);
                          }
                          Navigator.pop(context);
                          _showSnackBar('Profile effects & house badge updated successfully!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _frameChip(String key, String label, bool isDark, StateSetter setModalState) {
    final isSelected = _selectedFrame == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _selectedFrame = key);
          setState(() => _selectedFrame = key);
        }
      },
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
    );
  }

  Widget _tagPresetChip(String tag, bool isDark, StateSetter setModalState) {
    final isSelected = _serverTag == tag;
    return ChoiceChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _customTagController.text = tag;
          setModalState(() => _serverTag = tag);
          setState(() => _serverTag = tag);
        }
      },
      selectedColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildHouseBannerWidget(String houseKey) {
    late String title;
    late String iconStr;
    late List<Color> colors;
    late Color borderColor;

    switch (houseKey) {
      case 'vierrdy':
        title = 'HOUSE OF VIERRDY';
        iconStr = '🐍';
        colors = const [Color(0xFF052E16), Color(0xFF15803D), Color(0xFF22C55E)];
        borderColor = const Color(0xFF4ADE80);
        break;
      case 'giallio':
        title = 'HOUSE OF GIALLIO';
        iconStr = '🦁';
        colors = const [Color(0xFF422006), Color(0xFFA16207), Color(0xFFEAB308)];
        borderColor = const Color(0xFFFDE047);
        break;
      case 'roxxo':
        title = 'HOUSE OF ROXXO';
        iconStr = '🐉';
        colors = const [Color(0xFF450A0A), Color(0xFFB91C1C), Color(0xFFEF4444)];
        borderColor = const Color(0xFFFCA5A5);
        break;
      case 'cahel':
        title = 'HOUSE OF CAHEL';
        iconStr = '🦅';
        colors = const [Color(0xFF451A03), Color(0xFFB45309), Color(0xFFF59E0B)];
        borderColor = const Color(0xFFFCD34D);
        break;
      case 'azul':
      default:
        title = 'HOUSE OF AZUL';
        iconStr = '🐺';
        colors = const [Color(0xFF172554), Color(0xFF1D4ED8), Color(0xFF3B82F6)];
        borderColor = const Color(0xFF93C5FD);
        break;
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Text(iconStr, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _houseSelectCard(String key, String title, String iconStr, List<Color> colors, StateSetter setModalState) {
    final isSelected = _selectedHouse == key;
    return GestureDetector(
      onTap: () {
        setModalState(() => _selectedHouse = key);
        setState(() => _selectedHouse = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: colors.last.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)]
              : [],
        ),
        child: Row(
          children: [
            Text(iconStr, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}