import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/folder.dart';
import '../models/note.dart';

/// Thin wrapper around sqflite that persists users, folders and notes.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'voice_notes.db';
  static const String _notes = 'notes';
  static const String _folders = 'folders';
  static const String _users = 'users';
  static const int _version = 3;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await _createUsers(db);
        await _createFolders(db);
        await db.execute('''
          CREATE TABLE $_notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            transcript TEXT NOT NULL,
            audioPath TEXT,
            folderId TEXT,
            userId TEXT,
            durationMs INTEGER NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFolders(db);
          await _tryAddColumn(db, _notes, 'folderId TEXT');
        }
        if (oldVersion < 3) {
          await _createUsers(db);
          await _tryAddColumn(db, _notes, 'userId TEXT');
          await _tryAddColumn(db, _folders, 'userId TEXT');
        }
      },
    );
  }

  Future<void> _tryAddColumn(Database db, String table, String column) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column');
    } catch (_) {
      // Column likely already exists.
    }
  }

  Future<void> _createUsers(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        salt TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createFolders(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        userId TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  // --- Users ---

  Future<AppUser?> getUserByUsername(String username) async {
    final db = await database;
    final rows = await db.query(
      _users,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<void> insertUser(AppUser user) async {
    final db = await database;
    await db.insert(_users, user.toMap());
  }

  // --- Notes ---

  Future<List<Note>> getNotes(String userId) async {
    final db = await database;
    final rows = await db.query(
      _notes,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> insertNote(Note note, String userId) async {
    final db = await database;
    final map = note.toMap()..['userId'] = userId;
    await db.insert(
      _notes,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      _notes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(_notes, where: 'id = ?', whereArgs: [id]);
  }

  // --- Folders ---

  Future<List<Folder>> getFolders(String userId) async {
    final db = await database;
    final rows = await db.query(
      _folders,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(Folder.fromMap).toList();
  }

  Future<void> insertFolder(Folder folder, String userId) async {
    final db = await database;
    final map = folder.toMap()..['userId'] = userId;
    await db.insert(
      _folders,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a folder and detaches its notes (their folderId becomes null).
  Future<void> deleteFolder(String id) async {
    final db = await database;
    await db.update(
      _notes,
      {'folderId': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    await db.delete(_folders, where: 'id = ?', whereArgs: [id]);
  }
}
