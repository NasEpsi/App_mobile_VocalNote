import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/recording_provider.dart';
import '../widgets/record_button.dart';

/// Records audio with a live transcript, then lets the user review and save.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _titleController = TextEditingController();
  final _transcriptController = TextEditingController();
  String? _folderId;

  bool _reviewing = false;
  RecordingResult? _result;

  @override
  void initState() {
    super.initState();
    _folderId = context.read<NotesProvider>().selectedFolderId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleRecording(RecordingProvider provider) async {
    if (provider.isRecording) {
      final result = await provider.stop();
      if (result == null) {
        if (mounted && provider.error != null) {
          _showError(provider.error!);
        }
        return;
      }
      final words = result.transcript.trim().split(RegExp(r'\s+'));
      final suggestedTitle = words.take(5).join(' ');
      _titleController.text =
          suggestedTitle.isEmpty ? 'Nouvelle note' : suggestedTitle;
      _transcriptController.text = result.transcript;
      setState(() {
        _result = result;
        _reviewing = true;
      });
    } else {
      await provider.start();
      if (provider.error != null && mounted) {
        _showError(provider.error!);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    final result = _result;
    final note = Note(
      id: const Uuid().v4(),
      title: _titleController.text.trim().isEmpty
          ? 'Nouvelle note'
          : _titleController.text.trim(),
      transcript: _transcriptController.text.trim(),
      audioPath: result?.audioPath,
      folderId: _folderId,
      durationMs: result?.duration.inMilliseconds ?? 0,
      createdAt: DateTime.now(),
    );
    await context.read<NotesProvider>().addNote(note);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_reviewing ? 'Enregistrer la note' : 'Enregistrement'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (provider.isRecording) {
              await provider.cancel();
            }
            navigator.pop();
          },
        ),
      ),
      body: SafeArea(
        child: _reviewing
            ? _buildReview()
            : _buildRecording(provider),
      ),
    );
  }

  Widget _buildRecording(RecordingProvider provider) {
    final isProcessing = provider.status == RecordingStatus.processing;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            _formatDuration(provider.elapsed),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2330),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.isRecording
                ? 'Enregistrement en cours...'
                : 'Appuyez pour enregistrer votre voix',
            style: const TextStyle(color: Color(0xFF6B7180)),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Text(
                  provider.liveTranscript.isEmpty
                      ? 'La transcription en direct apparaîtra ici...'
                      : provider.liveTranscript,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: provider.liveTranscript.isEmpty
                        ? const Color(0xFFB4B9C6)
                        : const Color(0xFF1F2330),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Transcription...'),
                ],
              ),
            )
          else
            RecordButton(
              isRecording: provider.isRecording,
              onTap: () => _toggleRecording(provider),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Titre',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration('Titre de la note'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dossier',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildFolderChips(),
          const SizedBox(height: 20),
          const Text(
            'Transcription',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _transcriptController,
            maxLines: 8,
            minLines: 4,
            decoration: _inputDecoration('Transcription...'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Enregistrer la note'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderChips() {
    final folders = context.watch<FoldersProvider>().folders;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Aucun'),
          selected: _folderId == null,
          onSelected: (_) => setState(() => _folderId = null),
        ),
        for (final folder in folders)
          ChoiceChip(
            label: Text(folder.name),
            selected: _folderId == folder.id,
            selectedColor: folder.color.withValues(alpha: 0.2),
            onSelected: (_) => setState(() => _folderId = folder.id),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3E6EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3E6EF)),
      ),
    );
  }
}
