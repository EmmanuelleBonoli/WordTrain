import 'package:flame/game.dart';
import '../../features/gameplay/components/enemy.dart';
import '../../features/gameplay/components/finish_line.dart';
import '../../features/gameplay/components/player.dart';
import '../../features/gameplay/game_state.dart';
import '../../utils/dictionary.dart';
import '../constants/game_constants.dart';

class WordTrainGame extends FlameGame {
  final Dictionary dictionary;
  final GameState gameState;

  Player? player;
  Enemy? enemy;
  FinishLine? finishLine;
  late double finishLineX;

  WordTrainGame({required this.dictionary, required this.gameState});

  @override
  Future<void> onLoad() async {
    /// Initialise les composants
    player = Player();
    enemy = Enemy();
    finishLine = FinishLine();

    /// Ajoute les composants au jeu
    await addAll([player!, enemy!, finishLine!]);

    /// Calcule la position de la ligne d'arrivée
    finishLineX = size.x * GameConstants.finishLineXRatio;

    /// Positionne les éléments
    if (player != null && enemy != null && finishLine != null) {
      _initialPositionGameElements(size);
    }
  }

  void _initialPositionGameElements(Vector2 size) {
    /// Position du joueur
    player!.position = Vector2(
      GameConstants.playerStartX,
      size.y * GameConstants.playerYRatio,
    );

    /// Position de l'ennemi
    enemy!.position = Vector2(
      GameConstants.playerStartX,
      size.y * GameConstants.enemyYRatio,
    );

    /// Position de la ligne d'arrivée
    finishLine!.position = Vector2(finishLineX, 0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState.isGameOver) return;

    /// L'ennemi avance automatiquement
    final enemySpeed = size.x * GameConstants.enemySpeedRatio;
    enemy!.autoMove(dt, enemySpeed, finishLineX);

    _checkWinConditions();
  }

  void _checkWinConditions() {
    if (player!.position.x >= finishLineX) {
      gameState.setGameOver(playerWon: true);
      overlays.add('GameOver');
    } else if (enemy!.position.x >= finishLineX) {
      gameState.setGameOver(playerWon: false);
      overlays.add('GameOver');
    }
  }

  /// Valide le mot actuel et fait avancer le joueur si valide
  void validateWord() {
    if (gameState.isGameOver) return;

    final word = gameState.consumeWord();

    if (dictionary.isValid(word)) {
      final advance = size.x * GameConstants.playerAdvanceRatio;
      player!.moveForward(advance, finishLineX);
    }
  }

  /// Réinitialise le jeu
  void resetGame() {
    gameState.reset();
    overlays.remove('GameOver');
    _initialPositionGameElements(size);
  }
}
