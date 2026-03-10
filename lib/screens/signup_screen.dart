import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/theme_provider.dart';
import '../models/student_model.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/custom_dropdown.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SignUpScreen({super.key, required this.themeProvider});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _usnController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedCourse;
  String? _selectedYear;
  String? _selectedSection;

  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _usnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourse == null ||
        _selectedYear == null ||
        _selectedSection == null) {
      _showSnackBar('Please select Course, Year, and Section', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSignUpQRCode();
      }
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

  void _showSignUpQRCode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final student = Student(
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      usn: _usnController.text.trim(),
      course: _selectedCourse!,
      year: _selectedYear!,
      section: _selectedSection!,
    );

    var date = DateTime.now();
    var dateFormatter = DateFormat('yyyy-MM-dd');
    String formattedDate = dateFormatter.format(date);

    final qrData =
        'STIMSYSREG|${student.usn}|${_passwordController.text}|${student.lastName}|${student.firstName}|${student.middleName}|${student.course}|${student.yearSection}|$formattedDate';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
                width: isDark ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: isDark ? 20 : 15,
                  offset: Offset(0, isDark ? 10 : 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Account Created!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Student QR Code',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStudentInfoCard(student, isDark),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginScreen(themeProvider: widget.themeProvider),
                        ),
                      );
                    },
                    child: const Text('Continue to Login'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentInfoCard(Student student, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Information',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          _infoRow('Name', student.fullName, isDark),
          const SizedBox(height: 6),
          _infoRow('USN', student.usn, isDark),
          const SizedBox(height: 6),
          _infoRow('Course', student.course, isDark),
          const SizedBox(height: 6),
          _infoRow('Year/Section', student.yearSection, isDark),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackButton(isDark),
                  const SizedBox(height: 30),
                  _buildHeader(isDark),
                  const SizedBox(height: 32),
                  _buildFormFields(isDark),
                  const SizedBox(height: 24),
                  _buildSignUpButton(),
                  const SizedBox(height: 24),
                  _buildSignInLink(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                WelcomeScreen(themeProvider: widget.themeProvider),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: const Icon(Icons.arrow_back_ios_rounded, size: 18),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up as a new student',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        CustomTextField(
          label: 'Last Name *',
          hint: 'Enter your last name',
          icon: Icons.person_outline_rounded,
          controller: _lastNameController,
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'First Name *',
          hint: 'Enter your first name',
          icon: Icons.person_outline_rounded,
          controller: _firstNameController,
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Middle Name (Optional)',
          hint: 'Enter your middle name',
          icon: Icons.person_outline_rounded,
          controller: _middleNameController,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'USN *',
          hint: 'Enter your USN (numbers only)',
          icon: Icons.badge_rounded,
          controller: _usnController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        CustomDropdown<String>(
          label: 'Course *',
          hint: 'Select your course',
          icon: Icons.school_rounded,
          value: _selectedCourse,
          items: StudentConstants.courses,
          onChanged: (v) => setState(() => _selectedCourse = v),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: 'Year *',
                hint: 'Year',
                icon: Icons.calendar_today_rounded,
                value: _selectedYear,
                items: StudentConstants.years,
                onChanged: (v) => setState(() => _selectedYear = v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropdown<String>(
                label: 'Section *',
                hint: 'Section',
                icon: Icons.class_rounded,
                value: _selectedSection,
                items: StudentConstants.sections,
                onChanged: (v) => setState(() => _selectedSection = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Password *',
          hint: '••••••••',
          icon: Icons.lock_rounded,
          controller: _passwordController,
          isPassword: true,
          isPasswordVisible: _passwordVisible,
          onPasswordToggle: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v!.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildSignInLink(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      LoginScreen(themeProvider: widget.themeProvider),
                ),
              );
            },
            child: const Text(
              'Sign in',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}