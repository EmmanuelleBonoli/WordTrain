/// Constantes du jeu centralisées
class GameConstants {
  /// Dimensions
  static const double playerSize = 30.0;
  static const double enemySize = 30.0;
  static const double finishLineStrokeWidth = 4.0;

  /// Positions initiales (en pourcentage de l'écran)
  static const double playerStartX = 50.0;
  static const double playerYRatio = 0.5;
  static const double enemyYRatio = 0.6;
  static const double finishLineXRatio = 0.9;

  /// Vitesses
  static const double enemySpeedRatio =
      0.01; // pourcentage de la largeur par seconde
  static const double playerAdvanceRatio = 0.05; // pourcentage par mot validé

  /// UI
  static const double uiPadding = 12.0;
  static const double letterSpacing = 4.0;
  static const double buttonSpacing = 8.0;
  static const double wordFontSize = 24.0;

  GameConstants._(); // Empêche l'instanciation
}
