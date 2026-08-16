import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen one-shot confetti burst that replays whenever [signal]
/// changes. Place inside a [Stack] with [Positioned.fill].
///
/// Particles live in normalized coordinates (fractions of the canvas) so the
/// burst scales to any screen; physics: initial spray velocity + gravity +
/// sinusoidal flutter + tumbling rectangles.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.signal,
    this.particleCount = 110,
    this.duration = const Duration(milliseconds: 3000),
  });

  final int signal;
  final int particleCount;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  List<_ConfettiParticle> _particles = const <_ConfettiParticle>[];

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.signal != oldWidget.signal && widget.signal > 0) {
      _particles = _buildParticles();
      _controller.forward(from: 0);
    }
  }

  List<_ConfettiParticle> _buildParticles() {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = <Color>[
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      const Color(0xFFFFB300),
      const Color(0xFFFF5C8A),
      const Color(0xFF26C6DA),
    ];
    final random = math.Random();
    return List.generate(widget.particleCount, (_) {
      return _ConfettiParticle(
        color: palette[random.nextInt(palette.length)],
        x0: 0.5 + random.nextDouble() * 0.08 - 0.04,
        y0: -0.04,
        vx: random.nextDouble() * 0.9 - 0.45,
        vy: 0.25 + random.nextDouble() * 0.55,
        gravity: 1.45 + random.nextDouble() * 0.4,
        flutterAmplitude: 0.005 + random.nextDouble() * 0.025,
        flutterFrequency: 2 + random.nextDouble() * 5,
        flutterPhase: random.nextDouble() * math.pi * 2,
        rot0: random.nextDouble() * math.pi * 2,
        rotSpeed: (random.nextDouble() * 7 + 2) * (random.nextBool() ? 1 : -1),
        flipFrequency: 3 + random.nextDouble() * 6,
        width: 5 + random.nextDouble() * 5,
        height: 8 + random.nextDouble() * 6,
        circle: random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            animation: _controller,
            durationSec: widget.duration.inMilliseconds / 1000,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.animation,
    required this.durationSec,
  }) : super(repaint: animation);

  final List<_ConfettiParticle> particles;
  final Animation<double> animation;
  final double durationSec;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    final elapsed = animation.value * durationSec;
    final fadeStart = durationSec * 0.72;
    final alpha = elapsed <= fadeStart
        ? 1.0
        : (1 - ((elapsed - fadeStart) / (durationSec - fadeStart)))
              .clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final paint = Paint();
    for (final p in particles) {
      final x =
          (p.x0 + p.vx * elapsed + p.flutterAmplitude *
              math.sin(elapsed * p.flutterFrequency + p.flutterPhase)) *
          size.width;
      final y =
          (p.y0 + p.vy * elapsed + 0.5 * p.gravity * elapsed * elapsed) *
          size.height;
      if (y > size.height * 1.15) continue;

      paint.color = p.color.withValues(alpha: alpha);
      if (p.circle) {
        canvas.drawCircle(
          Offset(x, y),
          p.width * 0.5,
          paint,
        );
        continue;
      }
      final tumble = 0.35 +
          0.65 * math.sin(elapsed * p.flipFrequency + p.flutterPhase).abs();
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot0 + p.rotSpeed * elapsed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.width,
            height: p.height * tumble,
          ),
          const Radius.circular(1.6),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.particles != particles;
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.color,
    required this.x0,
    required this.y0,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.flutterAmplitude,
    required this.flutterFrequency,
    required this.flutterPhase,
    required this.rot0,
    required this.rotSpeed,
    required this.flipFrequency,
    required this.width,
    required this.height,
    required this.circle,
  });

  final Color color;
  final double x0;
  final double y0;
  final double vx; // fractions of width per second
  final double vy; // fractions of height per second
  final double gravity;
  final double flutterAmplitude;
  final double flutterFrequency;
  final double flutterPhase;
  final double rot0;
  final double rotSpeed;
  final double flipFrequency;
  final double width;
  final double height;
  final bool circle;
}
