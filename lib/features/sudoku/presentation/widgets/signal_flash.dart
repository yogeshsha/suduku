import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One-shot edge vignette in [color] that flashes whenever [signal] changes.
///
/// Used for the "game over" beat: a red glow breathes in from the screen
/// edges, peaks, and fades while the board reacts beneath it.
class SignalFlash extends StatefulWidget {
  const SignalFlash({
    super.key,
    required this.signal,
    required this.color,
    this.duration = const Duration(milliseconds: 800),
    this.maxOpacity = 0.45,
  });

  final int signal;
  final Color color;
  final Duration duration;
  final double maxOpacity;

  @override
  State<SignalFlash> createState() => _SignalFlashState();
}

class _SignalFlashState extends State<SignalFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(SignalFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.signal != oldWidget.signal && widget.signal > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        if (t == 0) return const SizedBox.shrink();
        final alpha = widget.maxOpacity * math.sin(math.pi * t);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.15,
              colors: [
                widget.color.withValues(alpha: 0),
                widget.color.withValues(alpha: alpha),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
