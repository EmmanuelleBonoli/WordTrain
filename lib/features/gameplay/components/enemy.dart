import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';

class Enemy extends PositionComponent {
  Enemy() : super(size: Vector2.all(GameConstants.enemySize));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.red;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  /// Déplace l'ennemi automatiquement (avec limite)
  void autoMove(double dt, double speed, double maxX) {
    position.x = (position.x + speed * dt).clamp(0, maxX);
  }
}
