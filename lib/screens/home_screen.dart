import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../services/audio_import_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
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
  final AudioImportService _audioImport = AudioImportService();

  String? _selectedFileName;
  bool _isImporting = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final picked = await _audioImport.pickAudioFile();
    if (picked == null) return;

    setState(() {
      _selectedFileName = picked.fileName;
      _isImporting = true;
    });

    if (!_audioImport.isTranscriptionConfigured) {
      _showMessage(
        "Transcription cloud non configurée. Ajoutez HF_API_TOKEN dans le fichier .env pour transcrire les fichiers importés.",
      );
    }

    String storedRef = '';
    try {
      storedRef = await _audioImport.storeAudio(picked.fileName, picked.bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _isImporting = false);
        _showMessage("Impossible d'enregistrer le fichier audio.");
      }
      return;
    }

    String transcript = '';
    if (_audioImport.isTranscriptionConfigured) {
      final result = await _audioImport.transcribe(
        picked.bytes,
        picked.fileName,
      );
      if (result.success) {
        transcript = result.text;
      } else if (result.error != null) {
        _showMessage(result.error!);
      }
    }

    if (!mounted) return;
    setState(() => _isImporting = false);
    await _saveImportedNote(picked.fileName, storedRef, transcript);
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
      folderId: context.read<NotesProvider>().selectedFolderId,
      durationMs: 0,
      createdAt: DateTime.now(),
    );
    if (!mounted) return;
    await context.read<NotesProvider>().addNote(note);
    if (mounted) {
      setState(() => _selectedFileName = null);
      _openNote(note);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final foldersProvider = context.watch<FoldersProvider>();
    final notes = notesProvider.notes;
    final selectedFolder =
        foldersProvider.byId(notesProvider.selectedFolderId);
    final currentLabel = selectedFolder?.name ?? 'Tous';

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notesProvider.load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildRecordArea()),
              SliverToBoxAdapter(
                child: _buildRecentsHeader(currentLabel, notes.length),
              ),
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
                      folder: foldersProvider.byId(notes[index].folderId),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: const Color(0xFF1F2330),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
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
              onPressed: _isImporting ? null : _importAudio,
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _isImporting ? 'Import en cours...' : 'Importer un audio',
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE3E6EF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_selectedFileName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.audio_file_rounded,
                  size: 18,
                  color: Color(0xFF6C8EF5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7180),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentsHeader(String folderLabel, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Récents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2330),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• $folderLabel',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9AA0AE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
