import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Result of a cloud transcription attempt.
class TranscriptionResult {
  final bool success;
  final String text;
  final String? error;

  const TranscriptionResult({
    required this.success,
    this.text = '',
    this.error,
  });
}

/// Transcribes audio via the Hugging Face Inference Providers API (Whisper).
///
/// Configure via `.env`:
/// - `HF_API_TOKEN` — token with **Inference Providers** permission
/// - `HF_STT_MODEL` — defaults to `openai/whisper-large-v3`
class TranscriptionService {
  static const _baseUrl = 'https://router.huggingface.co/hf-inference';
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 8);

  String get _token => dotenv.maybeGet('HF_API_TOKEN') ?? '';
  String get _model =>
      dotenv.maybeGet('HF_STT_MODEL') ?? 'openai/whisper-large-v3';

  bool get isConfigured => _token.trim().isNotEmpty;

  /// Transcribes raw audio [bytes]. Pass [fileName] to send the correct MIME type.
  Future<TranscriptionResult> transcribeBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (!isConfigured) {
      return const TranscriptionResult(
        success: false,
        error:
            "Aucun token Hugging Face configuré. Renseignez HF_API_TOKEN dans le fichier .env.",
      );
    }

    if (bytes.isEmpty) {
      return const TranscriptionResult(
        success: false,
        error: 'Fichier audio vide ou introuvable.',
      );
    }

    final uri = Uri.parse('$_baseUrl/models/$_model');
    final contentType = _mimeType(fileName);

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer $_token',
                'Content-Type': contentType,
                'Accept': 'application/json',
              },
              body: bytes,
            )
            .timeout(const Duration(seconds: 120));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final text = _extractText(decoded).trim();
          if (text.isEmpty) {
            return TranscriptionResult(
              success: false,
              error: _parseApiError(response.body) ??
                  'La transcription est vide. Réessayez avec un autre fichier.',
            );
          }
          return TranscriptionResult(success: true, text: text);
        }

        if (response.statusCode == 503 && attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
          continue;
        }

        return TranscriptionResult(
          success: false,
          error: _parseApiError(response.body) ??
              'Erreur API (${response.statusCode})',
        );
      } on Exception catch (e) {
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
          continue;
        }
        return TranscriptionResult(
          success: false,
          error: 'Échec de la transcription: $e',
        );
      }
    }

    return const TranscriptionResult(
      success: false,
      error:
          "Le modèle est en cours de chargement sur Hugging Face. Réessayez dans quelques instants.",
    );
  }

  String _mimeType(String? fileName) {
    if (fileName == null) return 'audio/mpeg';
    switch (p.extension(fileName).toLowerCase()) {
      case '.wav':
        return 'audio/wav';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.mp3':
      default:
        return 'audio/mpeg';
    }
  }

  String? _parseApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return null;
  }

  String _extractText(dynamic decoded) {
    if (decoded is Map && decoded['text'] != null) {
      return decoded['text'].toString();
    }
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map && first['text'] != null) {
        return first['text'].toString();
      }
    }
    return '';
  }
}
