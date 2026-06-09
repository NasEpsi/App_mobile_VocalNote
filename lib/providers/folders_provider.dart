import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/folder.dart';
import '../services/database_service.dart';

/// Manages the user-created folders. There are no default folders.
class FoldersProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Folder> _folders = [];
  String? _userId;

  List<Folder> get folders => _folders;

  /// Sets the active user and (re)loads their folders. Pass null to clear.
  Future<void> setUser(String? userId) async {
    _userId = userId;
    if (userId == null) {
      _folders = [];
      notifyListeners();
      return;
    }
    await load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    _folders = await _db.getFolders(_userId!);
    notifyListeners();
  }

  Folder? byId(String? id) {
    if (id == null) return null;
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  Future<Folder?> addFolder(String name, int colorValue) async {
    if (_userId == null) return null;
    final folder = Folder(
      id: const Uuid().v4(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _db.insertFolder(folder, _userId!);
    _folders = [..._folders, folder];
    notifyListeners();
    return folder;
  }

  Future<void> deleteFolder(String id) async {
    await _db.deleteFolder(id);
    _folders.removeWhere((f) => f.id == id);
    notifyListeners();
  }
}
