import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../theme/theme_provider.dart';
import '../models/student_model.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/custom_dropdown.dart';
import '../screens/welcome_screen.dart';
import '../providers/student_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 

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

  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _lastNameController = TextEditingController();
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _usnController = TextEditingController();
    _phoneController = TextEditingController();

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
      }
      setState(() => _isLoaded = true);
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _usnController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

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
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image', isError: true);
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
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isEditing = false;
      _isSaving = false;
    });
    _showSnackBar('Profile updated successfully!');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentProvider>();
    final student = provider.currentStudent;

    if (!_isLoaded || student == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildProfileImage(isDark, student),
          const SizedBox(height: 32),
          _buildPersonalInfoSection(isDark, student),
          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 20),
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEditing ? 'Edit your information' : 'Your personal information',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (_isEditing)
              GestureDetector(
                onTap: _cancelEdit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: _isSaving ? null : _toggleEdit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      )
                    else
                      Icon(
                        _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                        size: 16,
                        color: const Color(0xFF6366F1),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _isEditing ? 'Save' : 'Edit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileImage(bool isDark, Student student) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color:
                                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            student.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${student.course} | Year ${student.yearLevel}-${student.section}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(bool isDark, Student student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        if (_isEditing) ...[
          CustomTextField(
            label: 'Last Name',
            hint: 'Enter last name',
            icon: Icons.person_outline_rounded,
            controller: _lastNameController,
            enabled: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'First Name',
            hint: 'Enter first name',
            icon: Icons.person_outline_rounded,
            controller: _firstNameController,
            enabled: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Middle Name',
            hint: 'Enter middle name',
            icon: Icons.person_outline_rounded,
            controller: _middleNameController,
            enabled: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'USN',
            hint: 'Enter USN',
            icon: Icons.badge_rounded,
            controller: _usnController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: true,
          ),
          const SizedBox(height: 16),
          CustomDropdown<String>(
            label: 'Course',
            hint: 'Select course',
            icon: Icons.school_rounded,
            value: _selectedCourse,
            items: StudentConstants.courses,
            onChanged: (v) => setState(() => _selectedCourse = v),
            enabled: true,
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Phone',
            hint: 'Enter phone number',
            icon: Icons.phone_rounded,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: true,
          ),
        ] else ...[
          _buildReadOnlyField(isDark, 'USN', student.usn),
          const SizedBox(height: 12),
          _buildReadOnlyField(isDark, 'Full Name', student.fullName),
          const SizedBox(height: 12),
          _buildReadOnlyField(isDark, 'Program', student.course),
          const SizedBox(height: 12),
          _buildReadOnlyField(isDark, 'Year & Section', student.yearSection),
          const SizedBox(height: 12),
          _buildReadOnlyField(isDark, 'Phone', student.phone ?? 'Not set'),
          const SizedBox(height: 12),
          _buildReadOnlyField(
            isDark,
            'Registered',
            student.createdAt != null
                ? DateFormat('MMMM d, yyyy').format(student.createdAt!)
                : 'N/A',
          ),
        ],
      ],
    );
  }

  Widget _buildReadOnlyField(bool isDark, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
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
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Center(
      child: Text(
        'Powered by Corvexis and Rensusama',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}