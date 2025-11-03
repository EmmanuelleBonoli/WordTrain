import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';

class FinishLine extends PositionComponent with HasGameRef {
  FinishLine();

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = GameConstants.finishLineStrokeWidth;

    canvas.drawLine(Offset(0, 0), Offset(0, gameRef.size.y), paint);
  }
}
