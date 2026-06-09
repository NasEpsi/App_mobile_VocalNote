import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/database_service.dart';
import '../services/file_storage.dart';

/// Holds the list of notes, the active folder filter, and CRUD operations.
class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final FileStorage _storage = FileStorage();

  List<Note> _notes = [];
  String? _selectedFolderId; // null == "Tous"
  bool _loading = false;

  List<Note> get allNotes => _notes;
  String? get selectedFolderId => _selectedFolderId;
  bool get isLoading => _loading;

  List<Note> get notes {
    if (_selectedFolderId == null) return _notes;
    return _notes.where((n) => n.folderId == _selectedFolderId).toList();
  }

  int get totalCount => _notes.length;

  int countForFolder(String folderId) {
    return _notes.where((n) => n.folderId == folderId).length;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _notes = await _db.getNotes();
    _loading = false;
    notifyListeners();
  }

  void setFolderFilter(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  /// Clears the filter if the selected folder no longer exists.
  void onFolderRemoved(String folderId) {
    for (final note in _notes) {
      if (note.folderId == folderId) {
        final index = _notes.indexOf(note);
        _notes[index] = note.copyWith(clearFolder: true);
      }
    }
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    await _db.insertNote(note);
    _notes = [note, ..._notes];
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    await _db.updateNote(note);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      notifyListeners();
    }
  }

  Future<void> deleteNote(Note note) async {
    await _db.deleteNote(note.id);
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();

    final path = note.audioPath;
    if (path != null) {
      await _storage.delete(path);
    }
  }
}
