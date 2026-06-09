import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'file_storage.dart';

FileStorage createFileStorage() => IoFileStorage();

class IoFileStorage implements FileStorage {
  @override
  Future<Uint8List> readBytes(String reference) {
    return File(reference).readAsBytes();
  }

  @override
  Future<String> saveAudio(String filename, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, filename);
    await File(path).writeAsBytes(bytes);
    return path;
  }

  @override
  Future<void> delete(String reference) async {
    final file = File(reference);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists(String reference) => File(reference).exists();

  @override
  Future<void> exportText(String filename, String content) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, filename);
    await File(path).writeAsString(content);
    await Share.shareXFiles([XFile(path)]);
  }
}
