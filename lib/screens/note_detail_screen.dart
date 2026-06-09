import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../services/audio_player_service.dart';
import '../services/export_service.dart';

/// Displays a single note with playback, inline editing and export options.
class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final AudioPlayerService _player = AudioPlayerService();
  final ExportService _export = ExportService();

  late TextEditingController _titleController;
  late TextEditingController _transcriptController;
  String? _folderId;

  bool _editing = false;
  bool _audioReady = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _transcriptController =
        TextEditingController(text: widget.note.transcript);
    _folderId = widget.note.folderId;
    _initAudio();
  }

  Future<void> _initAudio() async {
    final path = widget.note.audioPath;
    if (path != null && path.isNotEmpty) {
      try {
        await _player.setFile(path);
        if (mounted) setState(() => _audioReady = true);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _titleController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _saveEdits() async {
    final updated = widget.note.copyWith(
      title: _titleController.text.trim(),
      transcript: _transcriptController.text.trim(),
      folderId: _folderId,
      clearFolder: _folderId == null,
    );
    await context.read<NotesProvider>().updateNote(updated);
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<NotesProvider>().deleteNote(widget.note);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _exportNote(bool pdf) async {
    final note = widget.note.copyWith(
      title: _titleController.text.trim(),
      transcript: _transcriptController.text.trim(),
      folderId: _folderId,
      clearFolder: _folderId == null,
    );
    final folder = context.read<FoldersProvider>().byId(_folderId);
    try {
      if (pdf) {
        await _export.exportAndSharePdf(
          note,
          folderName: folder?.name,
          folderColorValue: folder?.colorValue,
        );
      } else {
        await _export.exportAndShareTxt(note, folderName: folder?.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'export: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier' : 'Note'),
        actions: [
          if (_editing)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _saveEdits,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _editing = true),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_editing)
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Titre',
                  ),
                )
              else
                Text(
                  _titleController.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2330),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFolderTag(),
                  Text(
                    _safeDate(dateFormat),
                    style: const TextStyle(
                      color: Color(0xFF9AA0AE),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (_editing) ...[
                const SizedBox(height: 16),
                _buildFolderChips(),
              ],
              const SizedBox(height: 20),
              if (_audioReady) _buildPlayer(),
              const SizedBox(height: 20),
              if (_editing)
                TextField(
                  controller: _transcriptController,
                  maxLines: null,
                  minLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Transcription...',
                  ),
                )
              else
                Text(
                  _transcriptController.text.isEmpty
                      ? '(Aucune transcription)'
                      : _transcriptController.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Color(0xFF333947),
                  ),
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportNote(true),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Export PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportNote(false),
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('Export TXT'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _safeDate(DateFormat format) {
    try {
      return format.format(widget.note.createdAt);
    } catch (_) {
      return DateFormat('dd/MM/yyyy HH:mm').format(widget.note.createdAt);
    }
  }

  Widget _buildPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: StreamBuilder<Duration>(
        stream: _player.positionStream,
        builder: (context, posSnapshot) {
          final position = posSnapshot.data ?? Duration.zero;
          return StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, durSnapshot) {
              final total = durSnapshot.data ?? Duration.zero;
              final maxMs = total.inMilliseconds.toDouble();
              final value = maxMs == 0
                  ? 0.0
                  : position.inMilliseconds.clamp(0, total.inMilliseconds)
                      .toDouble();
              return Row(
                children: [
                  StreamBuilder<bool>(
                    stream: _player.playerStateStream
                        .map((s) => s.playing),
                    initialData: false,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return IconButton(
                        iconSize: 40,
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                        ),
                        onPressed: () {
                          if (playing) {
                            _player.pause();
                          } else {
                            _player.play();
                          }
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: value,
                            max: maxMs == 0 ? 1 : maxMs,
                            onChanged: (v) =>
                                _player.seek(Duration(milliseconds: v.round())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(position), style: _timeStyle),
                              Text(_fmt(total), style: _timeStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static const _timeStyle =
      TextStyle(fontSize: 11, color: Color(0xFF9AA0AE));

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildFolderTag() {
    final folder = context.watch<FoldersProvider>().byId(_folderId);
    if (folder == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: _tag(folder.name, folder.color),
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

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
