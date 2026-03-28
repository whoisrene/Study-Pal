import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';

class SignInPage extends StatefulWidget {
  final VoidCallback onSignIn;

  const SignInPage({super.key, required this.onSignIn});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        SizedBox(height: 12),

        // Forgot Password (just a placeholder now)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Could show a snackbar or dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password reset not available in local mode')),
              );
            },
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFFD4A574),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 28),

        // Sign In Button
        _buildSignInButton(),
        SizedBox(height: 24),

        // Divider
        _buildDivider(),
        SizedBox(height: 24),

        // Social Login (placeholders)
        _buildSocialLogin(),
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
                        _obscurePassword
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

  Widget _buildSignInButton() {
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
          onTap: _isLoading ? null : _handleSignIn,
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
                    'Sign In',
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFD4A574).withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Color(0xFF8B7355),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFD4A574).withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          onPressed: _handleGoogleSignIn,
        ),
        SizedBox(height: 12),
        _buildSocialButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
          onPressed: _handleAppleSignIn,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFD4A574).withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Color(0xFF6B4423),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Color(0xFF6B4423),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate a brief loading time
    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onSignIn();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    // Simulate loading
    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onSignIn();
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    // Simulate loading
    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onSignIn();
    }
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