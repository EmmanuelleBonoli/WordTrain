import 'package:flutter/material.dart';
import '../../gameplay/game_state.dart';
import '../../../core/game/word_train_game.dart';

class GameOverOverlay extends StatelessWidget {
  final WordTrainGame game;
  final GameState gameState;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              gameState.playerWon ? '🏆 Victoire !' : '💀 Défaite !',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: game.resetGame,
              child: const Text('Rejouer'),
            ),
          ],
        ),
      ),
    );
  }
}
