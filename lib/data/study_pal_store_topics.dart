import 'models.dart';
import 'study_pal_store.dart';
import 'study_topics.dart';

extension StudyPalTopicSafety on StudyPalStore {
  /// Guarantees onboarding always has curated chips on the dashboard.
  Future<UserProfile> ensureTopicDefaults(UserProfile profile) async {
    final topics = await topicLabels(profile.dbId);

    if (topics.isEmpty) {
      await replaceTopicLabels(profile.dbId, List<String>.from(kDefaultStudyTopics));
    }

    return refreshProfile(profile);
  }
}
