class AuthService {
  // Return null on success, or error string on failure.
  static Future<String?> signInWithEmail({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  static Future<String?> signUpWithEmail({required String email, required String password, required String name}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  static Future<String?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  static Future<String?> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  static Future<String?> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }
}