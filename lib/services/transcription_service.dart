import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

/// Transcribes audio via the (free-tier) Hugging Face Inference API using a
/// Whisper model. The provider is configurable through `.env`
/// (`HF_STT_MODEL`); Hugging Face is the free default.
class TranscriptionService {
  String get _token => dotenv.maybeGet('HF_API_TOKEN') ?? '';
  String get _model =>
      dotenv.maybeGet('HF_STT_MODEL') ?? 'openai/whisper-large-v3';

  bool get isConfigured => _token.trim().isNotEmpty;

  /// Transcribes raw audio [bytes].
  Future<TranscriptionResult> transcribeBytes(Uint8List bytes) async {
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

    final uri =
        Uri.parse('https://api-inference.huggingface.co/models/$_model');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'audio/mpeg',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text = _extractText(decoded);
        return TranscriptionResult(success: true, text: text.trim());
      }

      if (response.statusCode == 503) {
        return const TranscriptionResult(
          success: false,
          error:
              "Le modèle est en cours de chargement sur Hugging Face. Réessayez dans quelques instants.",
        );
      }

      return TranscriptionResult(
        success: false,
        error: 'Erreur API (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      return TranscriptionResult(
        success: false,
        error: 'Échec de la transcription: $e',
      );
    }
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
