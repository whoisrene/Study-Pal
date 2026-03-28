import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'forgot_password_page.dart';

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

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    final error = await AuthService.signInWithEmail(email: email, password: password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error == null) {
      widget.onSignIn();
    } else {
      _showErrorSnackBar(error);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B4423))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: const Color(0xFFD4A574).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFB8956A)),
              prefixIcon: Icon(icon, color: const Color(0xFFD4A574), size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFD4A574), size: 20),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(color: Color(0xFF6B4423), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSignIn,
      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign In'),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Or continue with')),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.g_mobiledata)),
        const SizedBox(width: 16),
        IconButton(onPressed: () {}, icon: const Icon(Icons.apple)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'your.email@example.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
            },
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 28),
        _buildSignInButton(),
        const SizedBox(height: 24),
        _buildDivider(),
        const SizedBox(height: 24),
        _buildSocialLogin(),
      ],
    );
  }
}
