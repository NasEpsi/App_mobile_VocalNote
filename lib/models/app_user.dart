/// A locally-stored user account (pseudo + hashed password).
class AppUser {
  final String id;
  final String username;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'salt': salt,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '',
      passwordHash: (map['passwordHash'] as String?) ?? '',
      salt: (map['salt'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }
}
