import 'package:flutter/foundation.dart';

import 'prefs_study_pal_store.dart';
import 'session_vault.dart';
import 'sqflite_study_pal_store.dart';
import 'study_pal_store.dart';

/// Native platforms use SQLite (same DDL you would mirror in Postgres/MySQL later).
/// Web builds keep a transactional JSON envelope in SharedPreferences instead.
Future<StudyPalStore> createStudyPalStore(SessionVault vault) async {
  if (kIsWeb) {
    return PrefsStudyPalStore.open(vault);
  }

  return SqfliteStudyPalStore.open(vault);
}
