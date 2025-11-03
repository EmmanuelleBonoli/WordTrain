import 'package:flutter/material.dart';
import '../../gameplay/game_state.dart';
import '../../../core/game/word_train_game.dart';
import '../../../core/constants/game_constants.dart';

class LetterInputWidget extends StatelessWidget {
  final WordTrainGame game;
  final GameState gameState;

  // TODO: Générer dynamiquement ces lettres
  final List<String> letters = const ['A', 'R', 'T', 'O', 'N', 'E', 'S', 'I'];

  const LetterInputWidget({
    super.key,
    required this.game,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(GameConstants.uiPadding),
        color: Colors.black.withOpacity(0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrentWord(),
            const SizedBox(height: GameConstants.buttonSpacing),
            _buildLetterButtons(),
            const SizedBox(height: GameConstants.buttonSpacing),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWord() {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, child) {
        return Text(
          gameState.currentWord,
          style: const TextStyle(
            color: Colors.white,
            fontSize: GameConstants.wordFontSize,
            letterSpacing: GameConstants.letterSpacing,
          ),
        );
      },
    );
  }

  Widget _buildLetterButtons() {
    return Wrap(
      spacing: GameConstants.buttonSpacing,
      children: letters.map((letter) {
        return ElevatedButton(
          onPressed: () => gameState.addLetter(letter),
          child: Text(letter),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: gameState.clearWord,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          child: const Text('Effacer'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: game.validateWord,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
