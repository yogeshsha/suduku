import 'package:flutter/material.dart';

import '../../../../theme/sudoku_game_colors.dart';

/// Cubby's mood — picked by the caller to match what just happened in-game.
enum MascotMood { idle, cheer, oops, thinking }

/// Cubby: the game's mascot, built from the exact material the game is
/// about — a 2×2 Sudoku box with a face. Kept to simple shapes (rounded
/// rects, circles, short arcs) so it's cheap to paint at any size.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.mood = MascotMood.idle, this.size = 64});

  final MascotMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gameColors = context.gameColors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(
          mood: mood,
          secondary: scheme.secondary,
          tertiary: scheme.tertiary,
          gold: gameColors.gold,
          ink: scheme.onSurface,
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({
    required this.mood,
    required this.secondary,
    required this.tertiary,
    required this.gold,
    required this.ink,
  });

  final MascotMood mood;
  final Color secondary;
  final Color tertiary;
  final Color gold;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    canvas.save();
    canvas.scale(s, s);

    final quadrant = Paint();
    final quadRadius = const Radius.circular(12);

    quadrant.color = secondary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(16, 16, 40, 40), quadRadius),
      quadrant,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(64, 16, 40, 40), quadRadius),
      quadrant,
    );
    quadrant.color = tertiary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(16, 64, 40, 40), quadRadius),
      quadrant,
    );
    quadrant.color = gold;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(64, 64, 40, 40), quadRadius),
      quadrant,
    );

    final face = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = ink;

    switch (mood) {
      case MascotMood.idle:
        canvas.drawCircle(const Offset(34, 36), 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(34, 36), 2.4, fill);
        canvas.drawCircle(const Offset(82, 36), 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(82, 36), 2.4, fill);
        _smile(canvas, face, const Offset(46, 76), const Offset(60, 92), const Offset(74, 76));
      case MascotMood.cheer:
        _arcUp(canvas, face, const Offset(34, 40));
        _arcUp(canvas, face, const Offset(82, 40));
        _smile(canvas, face, const Offset(36, 74), const Offset(60, 102), const Offset(84, 74));
        final sparkle = Paint()
          ..color = gold
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(8, 18), const Offset(14, 24), sparkle);
        canvas.drawLine(const Offset(112, 18), const Offset(106, 24), sparkle);
        canvas.drawLine(const Offset(12, 102), const Offset(16, 96), sparkle);
      case MascotMood.oops:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(34, 38), width: 8, height: 12),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(82, 38), width: 8, height: 12),
          fill,
        );
        canvas.drawLine(const Offset(22, 26), const Offset(38, 30), face);
        canvas.drawLine(const Offset(98, 26), const Offset(82, 30), face);
        _smile(canvas, face, const Offset(52, 82), const Offset(60, 78), const Offset(68, 82));
        canvas.drawCircle(const Offset(98, 20), 4, Paint()..color = tertiary.withValues(alpha: 0.7));
      case MascotMood.thinking:
        canvas.drawCircle(const Offset(34, 36), 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(34, 36), 2.4, fill);
        canvas.drawLine(const Offset(76, 36), const Offset(88, 36), face);
        canvas.drawLine(const Offset(50, 78), const Offset(70, 78), face);
        final dot = Paint()..color = secondary;
        canvas.drawCircle(const Offset(100, 14), 3, dot);
        canvas.drawCircle(const Offset(106, 6), 2, dot);
    }

    canvas.restore();
  }

  void _smile(Canvas canvas, Paint paint, Offset start, Offset control, Offset end) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  void _arcUp(Canvas canvas, Paint paint, Offset center) {
    final path = Path()
      ..moveTo(center.dx - 6, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - 8, center.dx + 6, center.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.secondary != secondary ||
        oldDelegate.tertiary != tertiary ||
        oldDelegate.gold != gold ||
        oldDelegate.ink != ink;
  }
}
