import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/folder.dart';
import '../models/note.dart';

/// Thin wrapper around sqflite that persists [Note] and [Folder] records.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'voice_notes.db';
  static const String _notes = 'notes';
  static const String _folders = 'folders';
  static const int _version = 2;

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
        await _createFolders(db);
        await db.execute('''
          CREATE TABLE $_notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            transcript TEXT NOT NULL,
            audioPath TEXT,
            folderId TEXT,
            durationMs INTEGER NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFolders(db);
          try {
            await db.execute('ALTER TABLE $_notes ADD COLUMN folderId TEXT');
          } catch (_) {
            // Column may already exist.
          }
        }
      },
    );
  }

  Future<void> _createFolders(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  // --- Notes ---

  Future<List<Note>> getNotes() async {
    final db = await database;
    final rows = await db.query(_notes, orderBy: 'createdAt DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      _notes,
      note.toMap(),
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

  Future<List<Folder>> getFolders() async {
    final db = await database;
    final rows = await db.query(_folders, orderBy: 'createdAt ASC');
    return rows.map(Folder.fromMap).toList();
  }

  Future<void> insertFolder(Folder folder) async {
    final db = await database;
    await db.insert(
      _folders,
      folder.toMap(),
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
