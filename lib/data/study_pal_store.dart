import 'models.dart';
import 'session_vault.dart';

abstract class StudyPalStore {
  StudyPalStore(this.session);

  final SessionVault session;

  Future<void> close();

  /// Restores signed-in session from persisted credentials.
  Future<UserProfile?> bootstrapSession();

  Future<UserProfile?> userByPublicId(String publicId);
  Future<UserProfile?> userByEmail(String normalizedEmail);

  /// Constant-time-ish failure surface: callers should mask "unknown email" vs "bad password".
  Future<bool> emailPasswordMatches({required String normalizedEmail, required String plainPassword});

  Future<UserProfile> createEmailUser({
    required String normalizedEmail,
    required String displayName,
    required String bcryptHash,
  });

  Future<UserProfile> refreshProfile(UserProfile basis);

  Future<List<String>> topicLabels(int userDbId);
  Future<void> replaceTopicLabels(int userDbId, List<String> labels);

  Future<(int streak, DateTime? last)> readStreak(int userDbId);
  Future<void> writeStreak(int userDbId, int streak, DateTime? last);

  Future<List<HomeworkItem>> listHomework(int userDbId);
  Future<HomeworkItem> addHomework(
    int userDbId, {
    required String title,
    String? notes,
    DateTime? dueAt,
  });

  Future<void> setHomeworkCompleted(int homeworkId, bool completed);

  /// Pulls streak/topic prefs created before SQLite/prefs-backend existed.
  Future<void> applyLegacySharedPreferences(UserProfile profile);
}
