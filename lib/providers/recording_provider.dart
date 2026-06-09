import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/audio_recorder_service.dart';
import '../services/file_storage.dart';
import '../services/speech_service.dart';
import '../services/transcription_service.dart';

enum RecordingStatus { idle, recording, processing }

/// Coordinates the audio recorder and the live speech recognizer.
///
/// While recording it tries to surface a live transcript via on-device speech
/// recognition. If the device cannot run the recognizer and the file recorder
/// at once (so the live transcript stays empty), it falls back to transcribing
/// the saved file through the cloud [TranscriptionService] after stopping.
class RecordingProvider extends ChangeNotifier {
  final AudioRecorderService _recorder = AudioRecorderService();
  final SpeechService _speech = SpeechService();
  final TranscriptionService _transcription = TranscriptionService();
  final FileStorage _storage = FileStorage();

  RecordingStatus _status = RecordingStatus.idle;
  String _liveTranscript = '';
  Duration _elapsed = Duration.zero;
  String? _error;

  Timer? _timer;

  RecordingStatus get status => _status;
  String get liveTranscript => _liveTranscript;
  Duration get elapsed => _elapsed;
  String? get error => _error;
  bool get isRecording => _status == RecordingStatus.recording;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    _error = null;
    _liveTranscript = '';
    _elapsed = Duration.zero;

    if (!await _recorder.hasPermission()) {
      _error = "Permission micro refusée.";
      notifyListeners();
      return;
    }

    await _recorder.start();
    _status = RecordingStatus.recording;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });

    // Best-effort live transcription; may be unavailable while the file
    // recorder holds the microphone.
    try {
      final available = await _speech.init();
      if (available) {
        await _speech.start(
          onResult: (text, isFinal) {
            _liveTranscript = text;
            notifyListeners();
          },
        );
      }
    } catch (_) {
      // Ignore; we fall back to file transcription on stop.
    }
  }

  /// Stops recording and returns the result. If the live transcript is empty
  /// and cloud transcription is configured, transcribes the saved file.
  Future<RecordingResult?> stop() async {
    _timer?.cancel();
    _timer = null;

    try {
      await _speech.stop();
    } catch (_) {}

    _status = RecordingStatus.processing;
    notifyListeners();

    final path = await _recorder.stop();
    final duration = _elapsed;
    var transcript = _liveTranscript.trim();

    if (transcript.isEmpty &&
        path != null &&
        _transcription.isConfigured) {
      try {
        final bytes = await _storage.readBytes(path);
        final result = await _transcription.transcribeBytes(bytes);
        if (result.success) {
          transcript = result.text;
        } else {
          _error = result.error;
        }
      } catch (e) {
        _error = 'Échec de la transcription: $e';
      }
    }

    _status = RecordingStatus.idle;
    notifyListeners();

    if (path == null) return null;
    return RecordingResult(
      audioPath: path,
      transcript: transcript,
      duration: duration,
    );
  }

  Future<void> cancel() async {
    _timer?.cancel();
    _timer = null;
    try {
      await _speech.cancel();
    } catch (_) {}
    await _recorder.cancel();
    _reset();
    notifyListeners();
  }

  void _reset() {
    _status = RecordingStatus.idle;
    _liveTranscript = '';
    _elapsed = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

class RecordingResult {
  final String audioPath;
  final String transcript;
  final Duration duration;

  const RecordingResult({
    required this.audioPath,
    required this.transcript,
    required this.duration,
  });
}
