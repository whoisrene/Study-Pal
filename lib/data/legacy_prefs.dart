import 'package:shared_preferences/shared_preferences.dart';

Future<void> migrateTopicsFromLegacyPrefs(
  Future<void> Function(List<String> topics) applyTopics,
) async {
  final prefs = await SharedPreferences.getInstance();
  final legacy = prefs.getStringList('selected_topics');
  if (legacy == null || legacy.isEmpty) return;

  await applyTopics(legacy.toList());
  await prefs.remove('selected_topics');
}

Future<void> migrateStreakFromLegacyPrefs(
  Future<void> Function(int streak, DateTime? last) applyStreak,
) async {
  final prefs = await SharedPreferences.getInstance();
  final streak = prefs.getInt('streak_count');
  final lastIso = prefs.getString('last_checkin');

  if (streak == null && lastIso == null) return;

  final parsedLast = lastIso != null ? DateTime.tryParse(lastIso) : null;
  await applyStreak(streak ?? 0, parsedLast);

  await prefs.remove('streak_count');
  await prefs.remove('last_checkin');
}
