import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'legacy_prefs.dart';
import 'models.dart';
import 'password_crypto.dart';
import 'session_vault.dart';
import 'study_pal_store.dart';
import 'study_topics.dart';

class AsyncLock {
  Future<void> _gate = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final previous = _gate;
    final latch = Completer<void>();
    _gate = latch.future;

    await previous;

    try {
      return await action();
    } finally {
      latch.complete(); // guarded by awaiting previous links
    }
  }
}

const _prefsKeyPayload = 'study_pal.persisted.shadow_db';

typedef _SerializedUserRow = ({
  int id,
  String publicId,
  String email,
  String displayName,
  String passwordHash,
  int streakCount,
  int? lastCheckinMs,
  int createdMs,
  int updatedMs,
});

typedef _SerializedTopicRow = ({
  int userId,
  String label,
  int order,
});

typedef _SerializedHomeworkRow = ({
  int id,
  int userId,
  String title,
  String? notes,
  int? dueMs,
  int completed,
  int createdMs,
});

class _PersistedEnvelope {
  _PersistedEnvelope({
    required this.users,
    required this.topics,
    required this.homework,
    required this.nextUserPk,
    required this.nextHomeworkPk,
  });

  factory _PersistedEnvelope.empty() => _PersistedEnvelope(
        users: [],
        topics: [],
        homework: [],
        nextUserPk: 1,
        nextHomeworkPk: 1,
      );

  factory _PersistedEnvelope.fromSnapshot(Map<String, Object?> decoded) => _PersistedEnvelope(
        users: _readUserRows(decoded['users']),
        topics: _readTopicRows(decoded['topics']),
        homework: _readHomeworkRows(decoded['homework']),
        nextUserPk: (decoded['nextUserPk'] as int?) ?? 1,
        nextHomeworkPk: (decoded['nextHomeworkPk'] as int?) ?? 1,
      );

  final List<_SerializedUserRow> users;
  final List<_SerializedTopicRow> topics;
  final List<_SerializedHomeworkRow> homework;
  int nextUserPk;
  int nextHomeworkPk;

  Map<String, Object?> toJson() => {
        'users': users
            .map(
              (u) => <String, Object?>{
                'id': u.id,
                'publicId': u.publicId,
                'email': u.email,
                'displayName': u.displayName,
                'passwordHash': u.passwordHash,
                'streakCount': u.streakCount,
                'lastCheckinMs': u.lastCheckinMs,
                'createdMs': u.createdMs,
                'updatedMs': u.updatedMs,
              },
            )
            .toList(growable: false),
        'topics': topics
            .map(
              (t) => <String, Object?>{
                'userId': t.userId,
                'label': t.label,
                'order': t.order,
              },
            )
            .toList(growable: false),
        'homework': homework
            .map(
              (h) => <String, Object?>{
                'id': h.id,
                'userId': h.userId,
                'title': h.title,
                'notes': h.notes,
                'dueMs': h.dueMs,
                'completed': h.completed,
                'createdMs': h.createdMs,
              },
            )
            .toList(growable: false),
        'nextUserPk': nextUserPk,
        'nextHomeworkPk': nextHomeworkPk,
      };

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(toJson());
    await prefs.setString(_prefsKeyPayload, payload);
  }

  static Future<_PersistedEnvelope> loadMutable() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyPayload);
    if (raw == null || raw.isEmpty) {
      final empty = _PersistedEnvelope.empty();
      await empty.save();
      return empty;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return _PersistedEnvelope.fromSnapshot(Map<String, Object?>.from(decoded));
  }

  static List<Map<String, Object?>> _asMapList(Object? slice) =>
      List<dynamic>.from((slice as List?) ?? const [])
          .map((item) => Map<String, Object?>.from(Map<String, dynamic>.from(item as Map)))
          .toList();

  static List<_SerializedUserRow> _readUserRows(Object? slice) =>
      _asMapList(slice).map(_mapUserRow).toList(growable: false);

  static List<_SerializedTopicRow> _readTopicRows(Object? slice) =>
      _asMapList(slice).map(_mapTopicRow).toList(growable: false);

  static List<_SerializedHomeworkRow> _readHomeworkRows(Object? slice) =>
      _asMapList(slice).map(_mapHomeworkRow).toList(growable: false);

  static _SerializedUserRow _mapUserRow(Map<String, Object?> row) =>
      (
        id: row['id'] as int,
        publicId: row['publicId'] as String,
        email: (row['email'] as String).toLowerCase(),
        displayName: row['displayName'] as String,
        passwordHash: row['passwordHash'] as String,
        streakCount: row['streakCount'] as int,
        lastCheckinMs: row['lastCheckinMs'] as int?,
        createdMs: row['createdMs'] as int,
        updatedMs: row['updatedMs'] as int,
      );

  static _SerializedTopicRow _mapTopicRow(Map<String, Object?> row) => (
        userId: row['userId'] as int,
        label: row['label'] as String,
        order: row['order'] as int,
      );

  static _SerializedHomeworkRow _mapHomeworkRow(Map<String, Object?> row) => (
        id: row['id'] as int,
        userId: row['userId'] as int,
        title: row['title'] as String,
        notes: row['notes'] as String?,
        dueMs: row['dueMs'] as int?,
        completed: row['completed'] as int,
        createdMs: row['createdMs'] as int,
      );

  UserProfile profileForUserRow(_SerializedUserRow row) => UserProfile(
        dbId: row.id,
        publicId: row.publicId,
        email: row.email,
        displayName: row.displayName,
        streakCount: row.streakCount,
        lastCheckIn: row.lastCheckinMs != null
            ? DateTime.fromMillisecondsSinceEpoch(row.lastCheckinMs!, isUtc: false)
            : null,
      );
}

class PrefsStudyPalStore extends StudyPalStore {
  PrefsStudyPalStore._(SessionVault session, {required AsyncLock mutex})
      : _mutex = mutex,
        super(session);

  final AsyncLock _mutex;

  static Future<PrefsStudyPalStore> open(SessionVault session) async =>
      PrefsStudyPalStore._(session, mutex: AsyncLock());

  Future<T> _withEnvelope<T>(Future<T> Function(_PersistedEnvelope env) mutate) async {
    return _mutex.synchronized(() async {
      final env = await _PersistedEnvelope.loadMutable();
      final result = await mutate(env);
      await env.save();
      return result;
    });
  }

  Future<T> _reads<T>(T Function(_PersistedEnvelope env) read) async {
    final env = await _PersistedEnvelope.loadMutable();
    return read(env);
  }

  UserProfile _userFromRow(_SerializedUserRow row) => UserProfile(
        dbId: row.id,
        publicId: row.publicId,
        email: row.email,
        displayName: row.displayName,
        streakCount: row.streakCount,
        lastCheckIn:
            row.lastCheckinMs != null ? DateTime.fromMillisecondsSinceEpoch(row.lastCheckinMs!, isUtc: false) : null,
      );

  _SerializedUserRow? _matchEmail(_PersistedEnvelope env, String normalizedEmail) {
    final needle = normalizedEmail.trim().toLowerCase();
    for (final candidate in env.users) {
      if (candidate.email == needle) return candidate;
    }
    return null;
  }

  @override
  Future<void> close() async {}

  @override
  Future<UserProfile?> bootstrapSession() async {
    final pid = await session.activePublicUserId();
    if (pid == null) return null;

    final env = await _PersistedEnvelope.loadMutable();
    for (final user in env.users) {
      if (user.publicId == pid) {
        return env.profileForUserRow(user);
      }
    }

    await session.clearSession();
    return null;
  }

  @override
  Future<UserProfile?> userByPublicId(String publicId) async {
    return _reads((env) {
      for (final candidate in env.users) {
        if (candidate.publicId == publicId) {
          return _userFromRow(candidate);
        }
      }
      return null;
    });
  }

  @override
  Future<UserProfile?> userByEmail(String normalizedEmail) async {
    return _reads((env) {
      final row = _matchEmail(env, normalizedEmail);
      return row != null ? _userFromRow(row) : null;
    });
  }

  @override
  Future<bool> emailPasswordMatches({required String normalizedEmail, required String plainPassword}) async {
    final env = await _PersistedEnvelope.loadMutable();
    final row = _matchEmail(env, normalizedEmail);
    if (row == null) return false;
    try {
      return PasswordCrypto.verifySecret(plainPassword, row.passwordHash);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserProfile> createEmailUser({
    required String normalizedEmail,
    required String displayName,
    required String bcryptHash,
  }) async {
    final emailKey = normalizedEmail.trim().toLowerCase();

    return _withEnvelope((env) async {
      final exists = env.users.any((u) => u.email == emailKey);
      if (exists) {
        throw StateError('User already exists');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final id = env.nextUserPk++;
      final publicId = const Uuid().v4();

      env.users.add(
        (
          id: id,
          publicId: publicId,
          email: emailKey,
          displayName: displayName.trim(),
          passwordHash: bcryptHash,
          streakCount: 0,
          lastCheckinMs: null,
          createdMs: now,
          updatedMs: now,
        ),
      );

      await session.rememberUser(publicId);

      final profileBase = env.profileForUserRow(env.users.lastWhere((u) => u.id == id));
      await _applyLegacyNoSave(env, profileBase);

      if (_topicSlice(env, id).isEmpty) {
        env.topics.removeWhere((topic) => topic.userId == id);
        final seed = List<String>.from(kDefaultStudyTopics);
        for (var i = 0; i < seed.length; i++) {
          env.topics.add((userId: id, label: seed[i], order: i));
        }
      }

      return env.profileForUserRow(env.users.lastWhere((u) => u.id == id));
    });
  }

  Future<void> _applyLegacyNoSave(_PersistedEnvelope env, UserProfile profile) async {
    Future<void> applyTopics(List<String> topics) async {
      final current = _topicSlice(env, profile.dbId).map((e) => e.label).toList();
      if (current.isNotEmpty || topics.isEmpty) return;
      env.topics.removeWhere((t) => t.userId == profile.dbId);
      for (var i = 0; i < topics.length; i++) {
        env.topics.add((userId: profile.dbId, label: topics[i], order: i));
      }
    }

    Future<void> applyStreak(int streak, DateTime? last) async {
      final rowIdx = env.users.indexWhere((u) => u.id == profile.dbId);
      if (rowIdx == -1) return;
      final current = env.users[rowIdx];
      final empty = current.streakCount == 0 && current.lastCheckinMs == null;
      final incoming = streak > 0 || last != null;
      if (!incoming || !empty) return;

      env.users[rowIdx] = (
        id: current.id,
        publicId: current.publicId,
        email: current.email,
        displayName: current.displayName,
        passwordHash: current.passwordHash,
        streakCount: streak,
        lastCheckinMs: last?.millisecondsSinceEpoch,
        createdMs: current.createdMs,
        updatedMs: DateTime.now().millisecondsSinceEpoch,
      );
    }

    await migrateTopicsFromLegacyPrefs(applyTopics);
    await migrateStreakFromLegacyPrefs(applyStreak);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('is_signed_up');
  }

  List<_SerializedTopicRow> _topicSlice(_PersistedEnvelope env, int userId) =>
      [...env.topics.where((t) => t.userId == userId)]..sort((a, b) => a.order.compareTo(b.order));

  @override
  Future<UserProfile> refreshProfile(UserProfile basis) async {
    final env = await _PersistedEnvelope.loadMutable();
    final rowIdx = env.users.indexWhere((u) => u.id == basis.dbId);
    if (rowIdx == -1) return basis;

    final row = env.users[rowIdx];
    return env.profileForUserRow(row);
  }

  @override
  Future<List<String>> topicLabels(int userDbId) async => _reads((env) => _topicSlice(env, userDbId).map((e) => e.label).toList());

  @override
  Future<void> replaceTopicLabels(int userDbId, List<String> labels) async {
    await _withEnvelope((env) async {
      env.topics.removeWhere((t) => t.userId == userDbId);
      for (var i = 0; i < labels.length; i++) {
        env.topics.add((userId: userDbId, label: labels[i], order: i));
      }
    });
  }

  @override
  Future<(int streak, DateTime? last)> readStreak(int userDbId) async {
    return _reads((env) {
      final rowIdx = env.users.indexWhere((u) => u.id == userDbId);
      if (rowIdx == -1) return (0, null);

      final row = env.users[rowIdx];
      final last = row.lastCheckinMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastCheckinMs!, isUtc: false)
          : null;
      return (row.streakCount, last);
    });
  }

  @override
  Future<void> writeStreak(int userDbId, int streak, DateTime? last) async {
    await _withEnvelope((env) async {
      final rowIdx = env.users.indexWhere((u) => u.id == userDbId);
      if (rowIdx == -1) return;
      final current = env.users[rowIdx];

      env.users[rowIdx] = (
        id: current.id,
        publicId: current.publicId,
        email: current.email,
        displayName: current.displayName,
        passwordHash: current.passwordHash,
        streakCount: streak,
        lastCheckinMs: last?.millisecondsSinceEpoch,
        createdMs: current.createdMs,
        updatedMs: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<List<HomeworkItem>> listHomework(int userDbId) async => _reads((env) {
        final hw = [...env.homework.where((h) => h.userId == userDbId)];
        hw.sort((a, b) => b.createdMs.compareTo(a.createdMs));
        return hw
            .map(
              (row) => HomeworkItem(
                id: row.id,
                title: row.title,
                notes: row.notes,
                dueAt:
                    row.dueMs != null ? DateTime.fromMillisecondsSinceEpoch(row.dueMs!, isUtc: false) : null,
                completed: row.completed != 0,
                createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdMs, isUtc: false),
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<HomeworkItem> addHomework(
    int userDbId, {
    required String title,
    String? notes,
    DateTime? dueAt,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedNotes = notes?.trim();

    return _withEnvelope((env) async {
      final homeworkId = env.nextHomeworkPk++;
      final now = DateTime.now().millisecondsSinceEpoch;

      env.homework.add(
        (
          id: homeworkId,
          userId: userDbId,
          title: trimmedTitle,
          notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
          dueMs: dueAt?.millisecondsSinceEpoch,
          completed: 0,
          createdMs: now,
        ),
      );

      return HomeworkItem(
        id: homeworkId,
        title: trimmedTitle,
        notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
        dueAt: dueAt,
        completed: false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: false),
      );
    });
  }

  @override
  Future<void> setHomeworkCompleted(int homeworkId, bool completed) async {
    await _withEnvelope((env) async {
      final idx = env.homework.indexWhere((element) => element.id == homeworkId);
      if (idx == -1) return;

      final current = env.homework[idx];

      env.homework[idx] = (
        id: current.id,
        userId: current.userId,
        title: current.title,
        notes: current.notes,
        dueMs: current.dueMs,
        completed: completed ? 1 : 0,
        createdMs: current.createdMs,
      );
    });
  }

  @override
  Future<void> applyLegacySharedPreferences(UserProfile profile) async {
    await _withEnvelope((env) async {
      await _applyLegacyNoSave(env, profile);
      if (_topicSlice(env, profile.dbId).isEmpty) {
        env.topics.removeWhere((element) => element.userId == profile.dbId);
        final seed = List<String>.from(kDefaultStudyTopics);
        for (var i = 0; i < seed.length; i++) {
          env.topics.add((userId: profile.dbId, label: seed[i], order: i));
        }
      }
    });
  }
}
