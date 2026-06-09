import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'file_storage.dart';
import 'transcription_service.dart';

/// Result of picking an audio file from the device.
class PickedAudioFile {
  final String fileName;
  final Uint8List bytes;

  const PickedAudioFile({required this.fileName, required this.bytes});
}

/// Picks, stores and transcribes audio files imported from the device.
class AudioImportService {
  static const allowedExtensions = ['mp3', 'wav', 'm4a', 'aac'];

  final FileStorage _storage = FileStorage();
  final TranscriptionService _transcription = TranscriptionService();

  bool get isTranscriptionConfigured => _transcription.isConfigured;

  /// Opens the file picker restricted to [allowedExtensions].
  Future<PickedAudioFile?> pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    return PickedAudioFile(fileName: picked.name, bytes: bytes);
  }

  /// Copies [bytes] into app storage and returns the stable audio reference.
  Future<String> storeAudio(String originalName, Uint8List bytes) async {
    final fileName =
        'import_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalName)}';
    return _storage.saveAudio(fileName, bytes);
  }

  /// Transcribes [bytes] via the cloud service when configured.
  Future<TranscriptionResult> transcribe(Uint8List bytes) {
    return _transcription.transcribeBytes(bytes);
  }
}
