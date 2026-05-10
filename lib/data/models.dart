class UserProfile {
  final int dbId;
  final String publicId;
  final String email;
  final String displayName;
  final int streakCount;
  final DateTime? lastCheckIn;

  const UserProfile({
    required this.dbId,
    required this.publicId,
    required this.email,
    required this.displayName,
    required this.streakCount,
    required this.lastCheckIn,
  });

  UserProfile copyWith({
    int? streakCount,
    DateTime? lastCheckIn,
    String? displayName,
    String? email,
  }) {
    return UserProfile(
      dbId: dbId,
      publicId: publicId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      streakCount: streakCount ?? this.streakCount,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    );
  }
}

class HomeworkItem {
  final int id;
  final String title;
  final String? notes;
  final DateTime? dueAt;
  final bool completed;
  final DateTime createdAt;

  const HomeworkItem({
    required this.id,
    required this.title,
    required this.notes,
    required this.dueAt,
    required this.completed,
    required this.createdAt,
  });
}
