import 'package:flutter/material.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5E6D3), // Warm cream
              Color(0xFFE8D4C4), // Soft tan
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Header
                    _buildHeader(),
                    SizedBox(height: 48),
                    
                    // Tab Switcher
                    _buildTabSwitcher(),
                    SizedBox(height: 32),
                    
                    // Content based on selected tab
                    if (_isSignIn)
                      SignInPage()
                    else
                      SignUpPage(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4A574).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.school,
            size: 48,
            color: Color(0xFFD4A574),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Homework Tracker',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4423),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Stay organized and on top of your studies',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8B6F47),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4A574).withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Sign In',
              isSelected: _isSignIn,
              onTap: () => setState(() => _isSignIn = true),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Create Account',
              isSelected: !_isSignIn,
              onTap: () => setState(() => _isSignIn = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFD4A574).withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Color(0xFF6B4423) : Color(0xFF8B6F47),
            ),
          ),
        ),
      ),
    );
  }
}
