import 'dart:typed_data';

import 'file_storage_io.dart'
    if (dart.library.js_interop) 'file_storage_web.dart';

/// Platform-agnostic file operations.
///
/// On native platforms paths are real filesystem paths. On web, "paths" are
/// in-memory blob object URLs and exports trigger a browser download.
abstract class FileStorage {
  factory FileStorage() => createFileStorage();

  /// Reads the bytes for a previously stored audio reference.
  Future<Uint8List> readBytes(String reference);

  /// Persists [bytes] as an audio file/blob and returns a stable reference
  /// (a filesystem path on native, a blob URL on web).
  Future<String> saveAudio(String filename, Uint8List bytes);

  /// Removes a stored audio reference (no-op if missing).
  Future<void> delete(String reference);

  /// Whether the reference can currently be read back.
  Future<bool> exists(String reference);

  /// Exports plain text either by sharing (native) or downloading (web).
  Future<void> exportText(String filename, String content);
}
