import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../models/note.dart';

/// A card in the "Récents" list showing a note's title, snippet and folder.
class NoteCard extends StatelessWidget {
  final Note note;
  final Folder? folder;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = folder?.color ?? const Color(0xFF9AA0AE);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  note.audioPath != null
                      ? Icons.graphic_eq_rounded
                      : Icons.notes_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1F2330),
                            ),
                          ),
                        ),
                        if (folder != null) _FolderTag(folder: folder!),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.transcript.isEmpty
                          ? '(Aucune transcription)'
                          : note.transcript,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF6B7180),
                      ),
                    ),
                    if (note.audioPath != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 16,
                            color: Color(0xFF9AA0AE),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            note.formattedDuration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA0AE),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTag extends StatelessWidget {
  final Folder folder;
  const _FolderTag({required this.folder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: folder.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        folder.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: folder.color,
        ),
      ),
    );
  }
}
