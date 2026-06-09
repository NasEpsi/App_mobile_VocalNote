import 'package:flutter/material.dart';

/// A user-created folder used to organize notes. No folders exist by default;
/// the user creates them from the sidebar.
class Folder {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  const Folder({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Folder.fromMap(Map<String, Object?> map) {
    return Folder(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      colorValue: (map['colorValue'] as int?) ?? 0xFF6C8EF5,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
    );
  }

  /// Suggested colors offered when creating a folder.
  static const List<int> palette = [
    0xFF6C8EF5,
    0xFFB57BEE,
    0xFF4FB39A,
    0xFFE5884D,
    0xFFE5648C,
    0xFF5AB0E5,
    0xFFD9A441,
    0xFF7E8AA2,
  ];
}
