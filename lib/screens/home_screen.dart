import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/file_storage.dart';
import '../services/transcription_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/note_card.dart';
import '../widgets/record_button.dart';
import 'note_detail_screen.dart';
import 'record_screen.dart';

/// Main screen reproducing the Voxnote layout.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TranscriptionService _transcription = TranscriptionService();
  final FileStorage _storage = FileStorage();

  void _openRecorder() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecordScreen()),
    );
  }

  void _openNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
  }

  Future<void> _importAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    final originalName = picked.name;
    if (bytes == null) {
      _showMessage("Impossible de lire le fichier audio sélectionné.");
      return;
    }

    if (!_transcription.isConfigured) {
      _showMessage(
        "Transcription cloud non configurée. Ajoutez HF_API_TOKEN dans le fichier .env pour transcrire les fichiers importés.",
      );
    }

    _showLoading('Transcription du fichier...');

    String storedRef;
    try {
      final fileName =
          'import_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalName)}';
      storedRef = await _storage.saveAudio(fileName, bytes);
    } catch (_) {
      storedRef = '';
    }

    String transcript = '';
    if (_transcription.isConfigured) {
      final r = await _transcription.transcribeBytes(bytes);
      if (r.success) {
        transcript = r.text;
      } else if (r.error != null) {
        _dismissLoading();
        _showMessage(r.error!);
        await _saveImportedNote(originalName, storedRef, transcript);
        return;
      }
    }

    _dismissLoading();
    await _saveImportedNote(originalName, storedRef, transcript);
  }

  Future<void> _saveImportedNote(
    String originalName,
    String reference,
    String transcript,
  ) async {
    final title = p.basenameWithoutExtension(originalName);
    final note = Note(
      id: const Uuid().v4(),
      title: title.isEmpty ? 'Fichier importé' : title,
      transcript: transcript,
      audioPath: reference.isEmpty ? null : reference,
      category: NoteCategory.perso,
      durationMs: 0,
      createdAt: DateTime.now(),
    );
    if (!mounted) return;
    await context.read<NotesProvider>().addNote(note);
    if (mounted) _openNote(note);
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _dismissLoading() {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notes;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notesProvider.load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: FilterChips(
                    selected: notesProvider.filter,
                    onSelected: notesProvider.setFilter,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildRecordArea()),
              SliverToBoxAdapter(child: _buildRecentsHeader(notes.length)),
              if (notesProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (notes.isEmpty)
                const SliverToBoxAdapter(child: EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) => NoteCard(
                      note: notes[index],
                      onTap: () => _openNote(notes[index]),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C8EF5), Color(0xFFB57BEE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Voxnote',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2330),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Prêt à écouter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2330),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Appuyez pour enregistrer votre voix',
            style: TextStyle(color: Color(0xFF6B7180), fontSize: 13),
          ),
          const SizedBox(height: 20),
          RecordButton(isRecording: false, onTap: _openRecorder),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importAudio,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Importer un fichier audio'),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE3E6EF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Récents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2330),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF9AA0AE),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
