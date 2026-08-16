import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Plays a one-shot decaying horizontal shake whenever [signal] changes.
///
/// The signal is an ever-increasing counter, so each new trigger replays the
/// animation even when nothing else about the child changed.
class ShakeOnSignal extends StatefulWidget {
  const ShakeOnSignal({
    super.key,
    required this.signal,
    required this.child,
    this.intensity = 8,
    this.duration = const Duration(milliseconds: 520),
  });

  final int signal;
  final Widget child;
  final double intensity;
  final Duration duration;

  @override
  State<ShakeOnSignal> createState() => _ShakeOnSignalState();
}

class _ShakeOnSignalState extends State<ShakeOnSignal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(ShakeOnSignal oldWidget) {
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
      builder: (context, child) {
        final t = _controller.value;
        if (t == 0) return child!;
        final dx = math.sin(t * math.pi * 4) * widget.intensity * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
