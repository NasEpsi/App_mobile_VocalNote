import 'package:speech_to_text/speech_to_text.dart';

/// Live, on-device speech recognition using the `speech_to_text` plugin.
///
/// Used while recording to show a real-time transcript. Note that on some
/// Android devices the system recognizer and a file recorder cannot hold the
/// microphone at the same time; callers should treat live results as best
/// effort and fall back to file transcription when needed.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    _available = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _available;
  }

  /// Begins listening and streams recognized words to [onResult].
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'fr_FR',
  }) async {
    if (!_available) {
      _available = await init();
    }
    if (!_available) return;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        localeId: localeId,
        pauseFor: const Duration(seconds: 30),
        listenFor: const Duration(minutes: 5),
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
