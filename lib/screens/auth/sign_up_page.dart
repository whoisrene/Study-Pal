import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  final void Function(UserProfile profile) onRegistered;

  const SignUpPage({super.key, required this.onRegistered});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name Field
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'John Doe',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 20),

        // Email Field
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'your.email@example.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 20),

        // Password Field
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onVisibilityToggle: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        SizedBox(height: 20),

        // Confirm Password Field
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onVisibilityToggle: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        SizedBox(height: 28),

        // Sign Up Button
        _buildSignUpButton(),
        SizedBox(height: 24),

        // Terms and Conditions
        _buildTermsText(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B4423),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4A574).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Color(0xFFB8956A).withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                icon,
                color: Color(0xFFD4A574),
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword && controller == _passwordController ||
                                _obscureConfirmPassword && controller == _confirmPasswordController
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Color(0xFFD4A574),
                        size: 20,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD4A574),
            Color(0xFFC19A6B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4A574).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleSignUp,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By creating an account, you agree to our Terms of Service and Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF8B7355),
        fontSize: 12,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    final outcome = await AuthService.signUpWithEmail(
      email: email,
      password: password,
      name: name,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (outcome.isSuccess && outcome.profile != null) {
      widget.onRegistered(outcome.profile!);
      return;
    }

    _showErrorSnackBar(outcome.message ?? 'Failed to create account. Please try again.');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }
}