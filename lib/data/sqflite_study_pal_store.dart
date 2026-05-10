import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'legacy_prefs.dart';
import 'models.dart';
import 'password_crypto.dart';
import 'session_vault.dart';
import 'sqlite_init.dart';
import 'study_pal_store.dart';
import 'study_topics.dart';

Future<Database> _openStudyPalDatabase() async {
  configureSqfliteFactoriesForDesktop();
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'study_pal.db');

  return openDatabase(
    dbPath,
    version: 1,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      await db.execute('''
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  public_id TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  display_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  streak_count INTEGER NOT NULL DEFAULT 0,
  last_checkin_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);''');

      await db.execute('''
CREATE TABLE user_topics (
  user_id INTEGER NOT NULL,
  topic_label TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  PRIMARY KEY (user_id, topic_label),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);''');

      await db.execute('''
CREATE TABLE homework (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  notes TEXT,
  due_at INTEGER,
  completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);''');

      await db.execute('CREATE INDEX idx_homework_user ON homework(user_id);');
    },
  );
}

UserProfile _userFromRow(Map<String, Object?> row) {
  final lastMs = row['last_checkin_at'] as int?;
  return UserProfile(
    dbId: row['id'] as int,
    publicId: row['public_id'] as String,
    email: row['email'] as String,
    displayName: row['display_name'] as String,
    streakCount: row['streak_count'] as int,
    lastCheckIn: lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: false) : null,
  );
}

class SqfliteStudyPalStore extends StudyPalStore {
  SqfliteStudyPalStore._(this._db, super.session);

  final Database _db;

  static Future<SqfliteStudyPalStore> open(SessionVault vault) async {
    final db = await _openStudyPalDatabase();
    return SqfliteStudyPalStore._(db, vault);
  }

  @override
  Future<void> close() => _db.close();

  @override
  Future<UserProfile?> bootstrapSession() async {
    final pid = await session.activePublicUserId();
    if (pid == null) return null;
    return userByPublicId(pid);
  }

  @override
  Future<UserProfile?> userByPublicId(String publicId) async {
    final rows = await _db.query(
      'users',
      where: 'public_id = ?',
      whereArgs: [publicId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  @override
  Future<UserProfile?> userByEmail(String normalizedEmail) async {
    final email = normalizedEmail.trim().toLowerCase();
    final rows = await _db.query(
      'users',
      where: 'LOWER(TRIM(email)) = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  @override
  Future<UserProfile> createEmailUser({
    required String normalizedEmail,
    required String displayName,
    required String bcryptHash,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final publicId = const Uuid().v4();
    final email = normalizedEmail.trim().toLowerCase();

    await _db.insert(
      'users',
      {
        'public_id': publicId,
        'email': email,
        'display_name': displayName.trim(),
        'password_hash': bcryptHash,
        'streak_count': 0,
        'last_checkin_at': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    final created = await userByPublicId(publicId);
    final profile = created!;

    await applyLegacySharedPreferences(profile);

    final topicsAfterLegacy = await topicLabels(profile.dbId);
    if (topicsAfterLegacy.isEmpty) {
      await replaceTopicLabels(profile.dbId, List<String>.from(kDefaultStudyTopics));
    }

    await session.rememberUser(publicId);
    final refreshed = await refreshProfile(profile);
    return refreshed;
  }

  @override
  Future<UserProfile> refreshProfile(UserProfile basis) async {
    final rows = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [basis.dbId],
      limit: 1,
    );
    if (rows.isEmpty) return basis;
    return _userFromRow(rows.first);
  }

  @override
  Future<List<String>> topicLabels(int userDbId) async {
    final rows = await _db.query(
      'user_topics',
      columns: ['topic_label'],
      where: 'user_id = ?',
      whereArgs: [userDbId],
      orderBy: 'sort_order ASC',
    );
    return rows.map((row) => row['topic_label'] as String).toList(growable: false);
  }

  @override
  Future<void> replaceTopicLabels(int userDbId, List<String> labels) async {
    await _db.transaction((txn) async {
      await txn.delete('user_topics', where: 'user_id = ?', whereArgs: [userDbId]);
      var order = 0;
      for (final label in labels) {
        await txn.insert('user_topics', {
          'user_id': userDbId,
          'topic_label': label,
          'sort_order': order++,
        });
      }
    });
  }

  @override
  Future<(int streak, DateTime? last)> readStreak(int userDbId) async {
    final rows = await _db.query(
      'users',
      columns: ['streak_count', 'last_checkin_at'],
      where: 'id = ?',
      whereArgs: [userDbId],
      limit: 1,
    );
    if (rows.isEmpty) return (0, null);

    final lastMs = rows.first['last_checkin_at'] as int?;
    return (
      rows.first['streak_count'] as int,
      lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: false) : null,
    );
  }

  @override
  Future<void> writeStreak(int userDbId, int streak, DateTime? last) async {
    await _db.update(
      'users',
      {
        'streak_count': streak,
        'last_checkin_at': last?.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [userDbId],
    );
  }

  @override
  Future<List<HomeworkItem>> listHomework(int userDbId) async {
    final rows = await _db.query(
      'homework',
      where: 'user_id = ?',
      whereArgs: [userDbId],
      orderBy: 'created_at DESC',
    );

    return rows
        .map(
          (row) => HomeworkItem(
            id: row['id'] as int,
            title: row['title'] as String,
            notes: row['notes'] as String?,
            dueAt: (row['due_at'] as int?) != null
                ? DateTime.fromMillisecondsSinceEpoch(row['due_at'] as int, isUtc: false)
                : null,
            completed: (row['completed'] as int) != 0,
            createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int, isUtc: false),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<HomeworkItem> addHomework(
    int userDbId, {
    required String title,
    String? notes,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final trimmedNotes = notes?.trim();

    final id = await _db.insert(
      'homework',
      {
        'user_id': userDbId,
        'title': title.trim(),
        'notes': (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'completed': 0,
        'created_at': now,
      },
    );

    return HomeworkItem(
      id: id,
      title: title.trim(),
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
      dueAt: dueAt,
      completed: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: false),
    );
  }

  @override
  Future<void> setHomeworkCompleted(int homeworkId, bool completed) async {
    await _db.update(
      'homework',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [homeworkId],
    );
  }

  @override
  Future<bool> emailPasswordMatches({required String normalizedEmail, required String plainPassword}) async {
    final rows = await _db.rawQuery(
      'SELECT password_hash FROM users WHERE LOWER(TRIM(email)) = ? LIMIT 1',
      [normalizedEmail.trim().toLowerCase()],
    );
    if (rows.isEmpty) return false;

    try {
      final hash = rows.first['password_hash'] as String;
      return PasswordCrypto.verifySecret(plainPassword, hash);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> applyLegacySharedPreferences(UserProfile profile) async {
    Future<void> applyTopics(List<String> topics) async {
      final topicsNow = await topicLabels(profile.dbId);
      if (topicsNow.isNotEmpty || topics.isEmpty) return;
      await replaceTopicLabels(profile.dbId, topics);
    }

    Future<void> applyStreak(int streak, DateTime? last) async {
      final current = await readStreak(profile.dbId);
      final incoming = streak > 0 || last != null;
      final empty = current.$1 == 0 && current.$2 == null;
      if (!incoming || !empty) return;
      await writeStreak(profile.dbId, streak, last);
    }

    await migrateTopicsFromLegacyPrefs(applyTopics);
    await migrateStreakFromLegacyPrefs(applyStreak);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('is_signed_up');
  }
}
