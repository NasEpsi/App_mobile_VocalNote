import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import 'database_service.dart';

/// Outcome of an authentication attempt.
class AuthResult {
  final AppUser? user;
  final String? error;

  const AuthResult.success(this.user) : error = null;
  const AuthResult.failure(this.error) : user = null;

  bool get isSuccess => user != null;
}

/// Local username/password authentication backed by SQLite.
///
/// Passwords are stored as a salted SHA-256 hash (never in clear text).
class AuthService {
  final DatabaseService _db = DatabaseService.instance;
  final Random _random = Random.secure();

  String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }

  Future<AuthResult> register(String username, String password) async {
    final name = username.trim();
    if (name.length < 3) {
      return const AuthResult.failure(
        'Le pseudo doit contenir au moins 3 caractères.',
      );
    }
    if (password.length < 4) {
      return const AuthResult.failure(
        'Le mot de passe doit contenir au moins 4 caractères.',
      );
    }
    final existing = await _db.getUserByUsername(name);
    if (existing != null) {
      return const AuthResult.failure('Ce pseudo est déjà utilisé.');
    }
    final salt = _generateSalt();
    final user = AppUser(
      id: const Uuid().v4(),
      username: name,
      passwordHash: _hash(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
    await _db.insertUser(user);
    return AuthResult.success(user);
  }

  Future<AuthResult> login(String username, String password) async {
    final user = await _db.getUserByUsername(username.trim());
    if (user == null) {
      return const AuthResult.failure('Pseudo ou mot de passe incorrect.');
    }
    final hash = _hash(password, user.salt);
    if (hash != user.passwordHash) {
      return const AuthResult.failure('Pseudo ou mot de passe incorrect.');
    }
    return AuthResult.success(user);
  }

  Future<AppUser?> getUserByUsername(String username) {
    return _db.getUserByUsername(username);
  }
}
