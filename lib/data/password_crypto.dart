import 'package:bcrypt/bcrypt.dart';

abstract final class PasswordCrypto {
  /// BCrypt salted hash suitable for SQLite / future Postgres `TEXT` columns.
  static String hashSecret(String plain) {
    final salt = BCrypt.gensalt();
    return BCrypt.hashpw(plain, salt);
  }

  static bool verifySecret(String plain, String bcryptHash) {
    return BCrypt.checkpw(plain, bcryptHash);
  }
}
