import 'package:flutter_test/flutter_test.dart';

import 'package:voice_notes/models/note.dart';

void main() {
  test('Note serializes to and from a map', () {
    final note = Note(
      id: 'abc',
      title: 'Réunion',
      transcript: 'Notes de la réunion',
      audioPath: '/tmp/a.m4a',
      folderId: 'folder-1',
      durationMs: 65000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final restored = Note.fromMap(note.toMap());

    expect(restored.id, note.id);
    expect(restored.title, note.title);
    expect(restored.transcript, note.transcript);
    expect(restored.folderId, 'folder-1');
    expect(restored.durationMs, 65000);
    expect(restored.formattedDuration, '01:05');
  });

  test('copyWith clearFolder detaches the note from its folder', () {
    final note = Note(
      id: 'abc',
      title: 'x',
      transcript: '',
      audioPath: null,
      folderId: 'folder-1',
      durationMs: 0,
      createdAt: DateTime.now(),
    );
    expect(note.copyWith(clearFolder: true).folderId, isNull);
  });
}
