import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wraps the `record` plugin to capture microphone audio.
///
/// On native platforms the audio is written to a file in the app documents
/// directory. On web the plugin records to an in-memory blob and `stop()`
/// returns a blob URL.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording and returns the target path (native) or empty (web).
  Future<String> start() async {
    String path = 'recording.m4a';
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      path = p.join(dir.path, fileName);
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    return path;
  }

  /// Stops recording. Returns a filesystem path (native) or blob URL (web).
  Future<String?> stop() => _recorder.stop();

  Future<void> cancel() => _recorder.cancel();

  Future<bool> isRecording() => _recorder.isRecording();

  Stream<Amplitude> amplitudeStream() => _recorder.onAmplitudeChanged(
        const Duration(milliseconds: 200),
      );

  Future<void> dispose() => _recorder.dispose();
}
