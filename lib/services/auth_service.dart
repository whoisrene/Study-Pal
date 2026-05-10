import '../data/models.dart';
import '../data/password_crypto.dart';
import '../data/study_pal_store.dart';
import '../data/study_pal_store_topics.dart';

class AuthResult {
  const AuthResult.success(this.profile) : message = null;
  const AuthResult.failure(this.message) : profile = null;

  final String? message;
  final UserProfile? profile;

  bool get isSuccess => profile != null;
}

/// Local-first credential flows that mirror SaaS backends you can bolt on later.
abstract final class AuthService {
  static StudyPalStore? _store;

  static void configure({required StudyPalStore store}) {
    _store = store;
  }

  static StudyPalStore get _scoped {
    final store = _store;
    assert(store != null, 'Call AuthService.configure() during app bootstrap.');
    return store!;
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static Future<void> _credentialMaskingDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalized = _normalizeEmail(email);
    final store = _scoped;

    final matched = await store.emailPasswordMatches(
      normalizedEmail: normalized,
      plainPassword: password,
    );

    if (!matched) {
      await _credentialMaskingDelay();
      return const AuthResult.failure('That email/password combination looks off.');
    }

    final profile = await store.userByEmail(normalized);
    if (profile == null) {
      await _credentialMaskingDelay();
      return const AuthResult.failure('That email/password combination looks off.');
    }

    await store.session.rememberUser(profile.publicId);
    await store.applyLegacySharedPreferences(profile);
    final hydrated = await store.ensureTopicDefaults(profile);

    return AuthResult.success(hydrated);
  }

  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final store = _scoped;
    final normalized = _normalizeEmail(email);

    if (await store.userByEmail(normalized) != null) {
      return const AuthResult.failure('An account already exists for that email.');
    }

    final hash = PasswordCrypto.hashSecret(password);

    try {
      final created = await store.createEmailUser(
        normalizedEmail: normalized,
        displayName: name,
        bcryptHash: hash,
      );

      final hydrated = await store.ensureTopicDefaults(created);
      return AuthResult.success(hydrated);
    } catch (error) {
      if (_isLikelyUniqueViolation(error)) {
        return const AuthResult.failure('An account already exists for that email.');
      }
      return AuthResult.failure('Could not finish sign up (${error.runtimeType}).');
    }
  }

  static bool _isLikelyUniqueViolation(Object error) {
    final normalized = error.toString().toUpperCase();
    if (normalized.contains('UNIQUE')) return true;
    if (normalized.contains('2067')) return true;
    return error is StateError;
  }

  static Future<AuthResult> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const AuthResult.failure('Google sign-in is not wired yet.');
  }

  static Future<AuthResult> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const AuthResult.failure('Apple sign-in is not wired yet.');
  }

  /// Local MVP: behaves like SaaS resets (quiet success regardless of lookup).
  static Future<String?> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final normalized = _normalizeEmail(email);
    await _scoped.userByEmail(normalized); // Validates structure; hides membership.
    return null;
  }

  static Future<void> signOutCurrentUser() async => _scoped.session.clearSession();
}
