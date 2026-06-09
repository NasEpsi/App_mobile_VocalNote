import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/database_service.dart';
import '../services/file_storage.dart';

/// Holds the list of notes, the active category filter, and CRUD operations.
class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final FileStorage _storage = FileStorage();

  List<Note> _notes = [];
  NoteCategory? _filter; // null == "Tous"
  bool _loading = false;

  List<Note> get allNotes => _notes;
  NoteCategory? get filter => _filter;
  bool get isLoading => _loading;

  List<Note> get notes {
    if (_filter == null) return _notes;
    return _notes.where((n) => n.category == _filter).toList();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _notes = await _db.getNotes();
    _loading = false;
    notifyListeners();
  }

  void setFilter(NoteCategory? category) {
    _filter = category;
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
