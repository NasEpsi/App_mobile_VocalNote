import 'package:flutter/material.dart';

/// Large circular microphone button with a pulsing ring while recording.
class RecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;
  final double size;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onTap,
    this.size = 88,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isRecording
        ? const Color(0xFFE5484D)
        : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale =
              widget.isRecording ? 1 + (_controller.value * 0.12) : 1.0;
          return Container(
            width: widget.size + 28,
            height: widget.size + 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(
                alpha: widget.isRecording ? 0.18 * _controller.value : 0.12,
              ),
            ),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: widget.size * 0.42,
          ),
        ),
      ),
    );
  }
}
