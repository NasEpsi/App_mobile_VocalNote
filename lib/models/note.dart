import 'package:flutter/material.dart';

/// Categories used to tag notes, mirroring the Voxnote reference UI.
enum NoteCategory {
  travail,
  idees,
  perso;

  String get label {
    switch (this) {
      case NoteCategory.travail:
        return 'Travail';
      case NoteCategory.idees:
        return 'Idées';
      case NoteCategory.perso:
        return 'Perso';
    }
  }

  Color get color {
    switch (this) {
      case NoteCategory.travail:
        return const Color(0xFF6C8EF5);
      case NoteCategory.idees:
        return const Color(0xFFB57BEE);
      case NoteCategory.perso:
        return const Color(0xFF4FB39A);
    }
  }

  static NoteCategory fromName(String? name) {
    return NoteCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => NoteCategory.perso,
    );
  }
}

/// A single voice note persisted in SQLite.
class Note {
  final String id;
  final String title;
  final String transcript;
  final String? audioPath;
  final NoteCategory category;
  final int durationMs;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.transcript,
    required this.audioPath,
    required this.category,
    required this.durationMs,
    required this.createdAt,
  });

  Note copyWith({
    String? title,
    String? transcript,
    String? audioPath,
    NoteCategory? category,
    int? durationMs,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      audioPath: audioPath ?? this.audioPath,
      category: category ?? this.category,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'transcript': transcript,
      'audioPath': audioPath,
      'category': category.name,
      'durationMs': durationMs,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      transcript: (map['transcript'] as String?) ?? '',
      audioPath: map['audioPath'] as String?,
      category: NoteCategory.fromName(map['category'] as String?),
      durationMs: (map['durationMs'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  String get formattedDuration {
    final seconds = (durationMs / 1000).round();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
