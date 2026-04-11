import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_player.dart';
import 'game_rival.dart';

class GameRaceArea extends StatefulWidget {
  final bool isCampaign;
  final double rabbitProgress;
  final double foxProgress;
  final bool isGameOver;
  /// Offset de défilement déjà lissé, fourni par le parent (_GameScreenContentState).
  final double smoothScrollOffset;

  const GameRaceArea({
    super.key,
    required this.isCampaign,
    required this.rabbitProgress,
    required this.foxProgress,
    required this.isGameOver,
    required this.smoothScrollOffset,
  });

  @override
  State<GameRaceArea> createState() => _GameRaceAreaState();
}

class _GameRaceAreaState extends State<GameRaceArea> {
  late final RaceGame _game;

  @override
  void initState() {
    super.initState();
    _game = RaceGame(isCampaign: widget.isCampaign);
  }

  @override
  void didUpdateWidget(GameRaceArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pousser les nouvelles valeurs dans Flame à chaque changement
    if (oldWidget.rabbitProgress != widget.rabbitProgress ||
        oldWidget.foxProgress != widget.foxProgress ||
        oldWidget.isGameOver != widget.isGameOver ||
        oldWidget.smoothScrollOffset != widget.smoothScrollOffset) {
      _game.updateProgress(
        widget.rabbitProgress,
        widget.foxProgress,
        widget.isGameOver,
        widget.smoothScrollOffset,
        MediaQuery.of(context).size.width,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le fond est géré au niveau de game_screen.dart (plein écran).
    // GameRaceArea affiche uniquement les personnages Flame sur fond transparent.
    return GameWidget(game: _game);
  }
}

class RaceGame extends FlameGame {
  final bool isCampaign;

  late Player _player;
  Rival? _rival;

  double _rabbitProgress = 0.0;
  double _foxProgress = 0.0;
  double _prevRabbitProgress = 0.0;
  bool _isGameOver = false;
  double _scrollOffset = 0.0;
  double _screenWidth = 0.0;

  double _playerY = 0.0;

  // Durée d'animation run après qu'il a physiquement cessé de bouger
  // (Le ressort s'occupe de la durée de progression)
  static const double _runDurationAfterWord = 0.4;
  double _runTimer = 0.0;

  static const double _spriteSize = 120.0 * 0.9;

  RaceGame({required this.isCampaign});

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (isCampaign) {
      _rival = Rival()..position = Vector2(-1000, -1000);
      _rival!.scale = Vector2.all(0.9);
      add(_rival!);
    }

    _player = Player()..position = Vector2(-1000, -1000);
    _player.scale = Vector2.all(0.9);
    add(_player);

    _updatePositions(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _updatePositions(size);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // La position X est directement modifiée dans _updatePositions car le lissage 
    // physique avec inertie est géré par la progression animée (GameScreen).

    // --- Timer run → idle ---
    if (_runTimer > 0) {
      _runTimer -= dt;
      if (_runTimer <= 0 && !_isGameOver) {
        _player.isPlaying = false;
      }
    }
  }

  /// Appelé depuis Flutter à chaque changement de progression ou de scroll lissé.
  void updateProgress(
    double rabbit,
    double fox,
    bool isGameOver,
    double scrollOffset,
    double screenWidth,
  ) {
    _prevRabbitProgress = _rabbitProgress;
    _rabbitProgress = rabbit;
    _foxProgress = fox;
    _isGameOver = isGameOver;
    _scrollOffset = scrollOffset;
    _screenWidth = screenWidth;

    // Déclencher l'animation run si le joueur a avancé (mot validé)
    if (_rabbitProgress > _prevRabbitProgress) {
      _player.isPlaying = true;
      _runTimer = _runDurationAfterWord;
    }

    if (_isGameOver) {
      _player.isPlaying = true;
      _rival?.isPlaying = false;
    }

    _updatePositions(size);
  }

  void _updatePositions(Vector2 gameSize) {
    if (gameSize.x == 0 || gameSize.y == 0) return;

    final double screenW = _screenWidth > 0 ? _screenWidth : gameSize.x;
    final double centerX = screenW / 2 - _spriteSize / 2;
    // La const 0.04 (était 0.13) défini que 4% du niveau représente le centre de l'écran. 
    // La course sera donc >3x plus longue et >3x plus rapide visuellement en pixels.
    final double worldScale = centerX / 0.04;

    // Position d'arrivée à 78% de la largeur pour éviter que le joueur soit
    // collé au bord droit de l'écran quand il franchit la ligne.
    final double finishX = gameSize.x * 0.78 - _spriteSize / 2;
    final double playerWorldX = _rabbitProgress * worldScale;
    
    // Positionnement immédiat de la vue (le mouvement de la variable _rabbitProgress est déjà animé avec inertie)
    _player.position.x = (playerWorldX - _scrollOffset).clamp(0.0, finishX);

    _playerY = gameSize.y * 0.72 - _spriteSize;
    _player.position.y = _playerY;

    // --- Rival (positionné directement via le scroll lissé) ---
    if (_rival != null && isCampaign) {
      _rival!.isPlaying = true;

      final double rivalWorldX = _foxProgress * worldScale;
      final double rivalScreenX = rivalWorldX - _scrollOffset;
      final double rivalY = gameSize.y * 0.22 - _spriteSize / 2;

      if (rivalScreenX < -_spriteSize || rivalScreenX > gameSize.x) {
        _rival!.position = Vector2(-_spriteSize * 2, rivalY);
      } else {
        _rival!.position = Vector2(rivalScreenX, rivalY);
      }
    }
  }
}
