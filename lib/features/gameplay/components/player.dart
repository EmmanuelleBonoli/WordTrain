import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';

class Player extends PositionComponent {
  Player() : super(size: Vector2.all(GameConstants.playerSize));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  /// Déplace le joueur vers l'avant (avec limite)
  void moveForward(double amount, double maxX) {
    position.x = (position.x + amount).clamp(0, maxX);
  }
}
