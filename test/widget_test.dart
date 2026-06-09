import 'package:flutter_test/flutter_test.dart';

import 'package:voice_notes/models/note.dart';

void main() {
  test('Note serializes to and from a map', () {
    final note = Note(
      id: 'abc',
      title: 'Réunion',
      transcript: 'Notes de la réunion',
      audioPath: '/tmp/a.m4a',
      category: NoteCategory.travail,
      durationMs: 65000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final restored = Note.fromMap(note.toMap());

    expect(restored.id, note.id);
    expect(restored.title, note.title);
    expect(restored.transcript, note.transcript);
    expect(restored.category, NoteCategory.travail);
    expect(restored.durationMs, 65000);
    expect(restored.formattedDuration, '01:05');
  });
}
