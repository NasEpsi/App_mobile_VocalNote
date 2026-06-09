/// A single voice note persisted in SQLite.
class Note {
  final String id;
  final String title;
  final String transcript;
  final String? audioPath;

  /// Id of the user-created folder this note belongs to, or null for none.
  final String? folderId;
  final int durationMs;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.transcript,
    required this.audioPath,
    required this.folderId,
    required this.durationMs,
    required this.createdAt,
  });

  Note copyWith({
    String? title,
    String? transcript,
    String? audioPath,
    String? folderId,
    bool clearFolder = false,
    int? durationMs,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      audioPath: audioPath ?? this.audioPath,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
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
      'folderId': folderId,
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
      folderId: map['folderId'] as String?,
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
