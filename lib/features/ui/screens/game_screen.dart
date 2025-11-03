import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../core/game/word_train_game.dart';
import '../../../utils/dictionary.dart';
import '../../gameplay/game_state.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/letter_input_widget.dart';

class GameScreen extends StatefulWidget {
  final Dictionary dictionary;

  const GameScreen({super.key, required this.dictionary});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState gameState;
  late final WordTrainGame game;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    game = WordTrainGame(dictionary: widget.dictionary, gameState: gameState);
  }

  @override
  void dispose() {
    gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'letterUI': (context, _) =>
              LetterInputWidget(game: game, gameState: gameState),
          'GameOver': (context, _) =>
              GameOverOverlay(game: game, gameState: gameState),
        },
        initialActiveOverlays: const ['letterUI'],
      ),
    );
  }
}
