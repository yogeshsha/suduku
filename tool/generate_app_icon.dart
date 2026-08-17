// Generates assets/branding/app_icon.png (1024², Cubby on the brand
// gradient). Run from repo root: dart run tool/generate_app_icon.dart

import 'dart:io';

import 'package:image/image.dart';

import 'cubby_art.dart';

void main() {
  const size = 1024;
  final img = Image(width: size, height: size, numChannels: 3);

  // "Sunset Arcade" brand gradient — same vivid pair used for the in-app
  // hero card and Play button (see SudokuGameColors.heroGradient).
  fillDiagonalGradient(
    img,
    from: ColorRgb8(0xFF, 0x7A, 0x45),
    to: ColorRgb8(0xFF, 0x4D, 0x82),
  );

  // White backdrop circle for contrast, matching the in-app mascot avatar
  // treatment on the home screen's hero card.
  const circleRadius = 330;
  fillCircle(
    img,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: circleRadius,
    color: ColorRgb8(255, 255, 255),
  );

  const faceSize = 460.0;
  final scale = faceSize / 88;
  final origin = (size - faceSize) / 2 - 16 * scale;

  drawCubby(
    img,
    originX: origin,
    originY: origin,
    scale: scale,
    secondary: ColorRgb8(0x4B, 0x3F, 0x91),
    tertiary: ColorRgb8(0x12, 0x94, 0x6E),
    gold: ColorRgb8(0xFF, 0xB1, 0x00),
    ink: ColorRgb8(0x24, 0x1A, 0x3D),
  );

  final out = File('assets/branding/app_icon.png');
  out.writeAsBytesSync(encodePng(img));
  // ignore: avoid_print
  print('Wrote ${out.path} (${img.width}x${img.height})');
}
