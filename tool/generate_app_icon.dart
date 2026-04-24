// Generates assets/branding/app_icon.png (1024², square Sudoku grid).
// Run from repo root: dart run tool/generate_app_icon.dart

import 'dart:io';

import 'package:image/image.dart';

void main() {
  const size = 1024;
  const pad = 152;
  final bg = ColorRgb8(13, 90, 115);
  final lineSoft = ColorRgb8(100, 188, 210);
  final lineBright = ColorRgb8(230, 248, 255);
  final digitColor = ColorRgb8(255, 255, 255);

  final img = Image(width: size, height: size, numChannels: 3);
  fill(img, color: bg);

  final g0 = pad.toDouble();
  final g1 = (size - pad).toDouble();
  final cell = (g1 - g0) / 9.0;

  for (var i = 0; i <= 9; i++) {
    final major = i % 3 == 0;
    final pos = (g0 + i * cell).round();
    final thickness = major ? 6.0 : 2.5;
    final color = major ? lineBright : lineSoft;
    drawLine(
      img,
      x1: g0.round(),
      y1: pos,
      x2: g1.round(),
      y2: pos,
      color: color,
      thickness: thickness,
      antialias: true,
    );
    drawLine(
      img,
      x1: pos,
      y1: g0.round(),
      x2: pos,
      y2: g1.round(),
      color: color,
      thickness: thickness,
      antialias: true,
    );
  }

  void placeDigit(int row, int col, String d) {
    final cx = (g0 + (col + 0.5) * cell).round();
    final cy = (g0 + (row + 0.5) * cell).round();
    drawString(
      img,
      d,
      font: arial48,
      x: cx - 14,
      y: cy - 20,
      color: digitColor,
    );
  }

  placeDigit(0, 0, '5');
  placeDigit(0, 4, '3');
  placeDigit(1, 2, '7');
  placeDigit(3, 5, '2');
  placeDigit(4, 8, '9');
  placeDigit(7, 1, '8');
  placeDigit(8, 7, '4');

  final out = File('assets/branding/app_icon.png');
  out.writeAsBytesSync(encodePng(img));
  // ignore: avoid_print
  print('Wrote ${out.path} (${img.width}x${img.height})');
}
