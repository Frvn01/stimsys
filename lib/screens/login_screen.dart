import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_provider.dart';
import '../widgets/common/custom_text_field.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const LoginScreen({super.key, required this.themeProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usnController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_usnController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }else{

      // if (student_login(_usnController, _passwordController) == 'TRUE') {
        
      // }else{
            //To add error dialog
      // }
      ///- to transfer to different logical validation
      setState(() => _isLoading = true);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                email: _usnController.text,
                themeProvider: widget.themeProvider,
              ),
            ),
          );
        }
      });
    ///- to transfer to different logical validation
    }
  }

  void student_login(usn, password) async{
    Uri uri = Uri.parse('http://150.0.0.24/STIMSYS-API/stimsys-reg-api.php');
    //Change IP Address
    Map<String, dynamic> data = {
      'usn' : usn,
      'password' : password,
    };

    http.Response response = await http.post(uri, body: data);

    if (response.statusCode == 200) {
      if(response.body == 'REGSUCC'){

      }else{
        // show error dialog
      }
    }else{
      // _showErrorDialog('No Connection to the server/db status code: ${response.statusCode}.');
      // show error dialog
    }
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(isDark),
                const SizedBox(height: 40),
                _buildHeader(isDark),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'USN',
                  hint: 'Enter your USN (numbers only)',
                  icon: Icons.badge_rounded,
                  controller: _usnController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_rounded,
                  controller: _passwordController,
                  isPassword: true,
                  isPasswordVisible: _passwordVisible,
                  onPasswordToggle: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildSignUpLink(isDark),
                const SizedBox(height: 24),
                _buildFooter(isDark),
              ],
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
          'Welcome Back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                'Sign In',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
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
                      SignUpScreen(themeProvider: widget.themeProvider),
                ),
              );
            },
            child: const Text(
              'Sign up',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
        ),
      ),
    );
  }
}