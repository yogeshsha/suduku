import 'package:flutter/material.dart';

/// Fades and slides [child] in after a short delay based on [index].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.index,
    required this.child,
    this.delayPerIndexMs = 52,
    this.durationMs = 340,
  });

  final int index;
  final Widget child;
  final int delayPerIndexMs;
  final int durationMs;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.durationMs),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      Duration(milliseconds: widget.index * widget.delayPerIndexMs),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
