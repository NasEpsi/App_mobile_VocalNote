import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/folder.dart';
import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../screens/note_detail_screen.dart';

/// Options offered when deleting a folder that may contain notes.
enum _FolderDeleteChoice { cancel, keepNotes, deleteNotes }

/// Sidebar reproducing the Voxnote mockup: header, user folders ("Dossiers")
/// with note counts and a "Nouveau dossier" action, then the full notes list.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final foldersProvider = context.watch<FoldersProvider>();
    final folders = foldersProvider.folders;
    final selected = notesProvider.selectedFolderId;

    return Drawer(
      backgroundColor: const Color(0xFFF6F7FB),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionLabel('DOSSIERS'),
                  _folderTile(
                    context,
                    icon: Icons.folder_open_rounded,
                    label: 'Tous',
                    count: notesProvider.totalCount,
                    color: Theme.of(context).colorScheme.primary,
                    selected: selected == null,
                    onTap: () {
                      notesProvider.setFolderFilter(null);
                      Navigator.pop(context);
                    },
                  ),
                  for (final folder in folders)
                    _folderTile(
                      context,
                      icon: Icons.folder_rounded,
                      label: folder.name,
                      count: notesProvider.countForFolder(folder.id),
                      color: folder.color,
                      selected: selected == folder.id,
                      onTap: () {
                        notesProvider.setFolderFilter(folder.id);
                        Navigator.pop(context);
                      },
                      onDelete: () => _confirmDeleteFolder(context, folder),
                    ),
                  _newFolderTile(context),
                  const Divider(height: 28, indent: 16, endIndent: 16),
                  _sectionLabel('TOUTES LES NOTES'),
                  if (notesProvider.allNotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aucune note',
                        style: TextStyle(color: Color(0xFF9AA0AE)),
                      ),
                    )
                  else
                    for (final note in notesProvider.allNotes)
                      _noteTile(context, note),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            _buildUserFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserFooter(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.currentUser?.username ?? '';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE3E6EF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6C8EF5),
            child: Text(
              username.isEmpty ? '?' : username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connecté en tant que',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9AA0AE)),
                ),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2330),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: const Color(0xFF6B7180),
            tooltip: 'Se déconnecter',
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final notes = context.read<NotesProvider>();
    final folders = context.read<FoldersProvider>();
    Navigator.pop(context);
    await notes.setUser(null);
    await folders.setUser(null);
    await auth.logout();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOXNOTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF9AA0AE),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Mes notes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2330),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF6B7180),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFF9AA0AE),
        ),
      ),
    );
  }

  Widget _folderTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              top: 4,
              bottom: 4,
              right: onDelete == null ? 12 : 4,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF1F2330),
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9AA0AE),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: const Color(0xFF9AA0AE),
                    tooltip: 'Supprimer le dossier',
                    onPressed: onDelete,
                  )
                else
                  const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newFolderTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () => _showNewFolderDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 20, color: Color(0xFF6B7180)),
              SizedBox(width: 12),
              Text(
                'Nouveau dossier',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteTile(BuildContext context, Note note) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: const Icon(
        Icons.description_outlined,
        color: Color(0xFF9AA0AE),
        size: 22,
      ),
      title: Text(
        note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1F2330),
        ),
      ),
      subtitle: note.transcript.isEmpty
          ? null
          : Text(
              note.transcript,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0AE)),
            ),
      onTap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
        );
      },
    );
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    Folder folder,
  ) async {
    final notesProvider = context.read<NotesProvider>();
    final foldersProvider = context.read<FoldersProvider>();
    final noteCount = notesProvider.countForFolder(folder.id);
    final choice = await showDialog<_FolderDeleteChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer "${folder.name}" ?'),
        content: Text(
          noteCount == 0
              ? 'Le dossier sera supprimé.'
              : 'Ce dossier contient $noteCount note${noteCount > 1 ? 's' : ''}. '
                  'Voulez-vous conserver les notes (elles n\'auront plus de dossier) '
                  'ou supprimer le dossier et toutes ses notes ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _FolderDeleteChoice.cancel),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _FolderDeleteChoice.keepNotes),
            child: const Text('Garder les notes'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, _FolderDeleteChoice.deleteNotes),
            child: const Text('Supprimer les notes'),
          ),
        ],
      ),
    );

    switch (choice) {
      case _FolderDeleteChoice.keepNotes:
        await foldersProvider.deleteFolder(folder.id);
        notesProvider.onFolderRemoved(folder.id);
        break;
      case _FolderDeleteChoice.deleteNotes:
        await notesProvider.deleteNotesInFolder(folder.id);
        await foldersProvider.deleteFolder(folder.id);
        break;
      case _FolderDeleteChoice.cancel:
      case null:
        break;
    }
  }

  Future<void> _showNewFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    int selectedColor = Folder.palette.first;
    final foldersProvider = context.read<FoldersProvider>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Nouveau dossier'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Nom du dossier',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in Folder.palette)
                        GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == c
                                    ? const Color(0xFF1F2330)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    await foldersProvider.addFolder(name, selectedColor);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
