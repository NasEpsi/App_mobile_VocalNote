import 'package:flutter/material.dart';

/// Friendly placeholder shown when there are no notes yet.
class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({
    super.key,
    this.message = "Aucune note pour l'instant.\nAppuyez sur le micro pour commencer.",
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF0FA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              size: 34,
              color: Color(0xFF9AA0AE),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9AA0AE),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
