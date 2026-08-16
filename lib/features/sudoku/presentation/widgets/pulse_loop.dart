import 'package:flutter/material.dart';

/// Continuously breathes [child] between scale 1 and 1 + [amplitude].
///
/// Used for subtle "alive" accents (hero icon, pause glyph, CTA icon); keep
/// amplitudes small so the loop reads as breathing, not wobbling.
class PulseLoop extends StatefulWidget {
  const PulseLoop({
    super.key,
    required this.child,
    this.amplitude = 0.06,
    this.halfPeriod = const Duration(milliseconds: 950),
  });

  final Widget child;
  final double amplitude;
  final Duration halfPeriod;

  @override
  State<PulseLoop> createState() => _PulseLoopState();
}

class _PulseLoopState extends State<PulseLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.halfPeriod,
  )..repeat(reverse: true);

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final scale = 1 + widget.amplitude * _curve.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
