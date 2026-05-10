import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/study_pal_store.dart';
import '../../widgets/main_layout.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store});

  final StudyPalStore store;

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
                      SignInPage(onSignedIn: _routeToHome)
                    else
                      SignUpPage(onRegistered: _routeToHome),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(0xFFD4A574).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school,
            size: 40,
            color: Color(0xFFD4A574),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Study Pal',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4423),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Your Study Companion',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF8B7355),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4A574).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignIn = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isSignIn ? Color(0xFFD4A574) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSignIn ? Colors.white : Color(0xFF6B4423),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSignIn = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isSignIn ? Color(0xFFD4A574) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isSignIn ? Colors.white : Color(0xFF6B4423),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _routeToHome(UserProfile profile) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainLayout(store: widget.store, profile: profile)),
    );
  }
}