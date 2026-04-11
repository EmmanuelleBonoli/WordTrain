import 'package:flutter/material.dart';

import 'package:word_riders/features/ui/styles/app_theme.dart';
import 'package:word_riders/features/ui/widgets/common/button/premium_round_button.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_input_cartridge.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_letter_grid.dart';

class GameInputArea extends StatelessWidget {
  final String? feedbackMessage;
  final String currentInput;
  final List<String> shuffledLetters;
  final VoidCallback onBackspace;
  final VoidCallback onValidate;
  final VoidCallback onShuffle;
  final Function(String) onLetterTap;
  final bool isSuccessFlash;

  const GameInputArea({
    super.key,
    required this.feedbackMessage,
    required this.currentInput,
    required this.shuffledLetters,
    required this.onBackspace,
    required this.onValidate,
    required this.onShuffle,
    required this.onLetterTap,
    this.isSuccessFlash = false,
  });

  @override
  Widget build(BuildContext context) {
    final inputRowHeight = 80.0;
    final halfRow = inputRowHeight / 2;

    return Stack(
       clipBehavior: Clip.none, // Permet au fond de s'étendre infiniment
       children: [
         // 1. Fond de la zone inférieure (Sous la ligne) - Hauteur infinie simulée
         Positioned(
           top: halfRow, 
           left: -50, // Marges de sécurité pour assurer une couverture totale en largeur
           right: -50, 
           height: 3000, // Hauteur massive pour remplir le bas de l'écran
           child: Container(color: AppTheme.levelSignFace),
         ),

         // 2. Ligne Dorée (Milieu de la ligne de saisie)
         Positioned(
           top: halfRow - 3.5, 
           left: 0, right: 0,
           height: 7, 
           child: Container(
             decoration: const BoxDecoration(
               border: Border.symmetric(horizontal: BorderSide(color: AppTheme.coinBorderDark, width: 1.5)),
               gradient: LinearGradient(
                 colors: [AppTheme.coinRimTop, AppTheme.coinRimBottom],
                 begin: Alignment.topCenter, end: Alignment.bottomCenter
               ),
               boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
             ),
           ),
         ),

         // 3. Message de Feedback (Flottant au-dessus)
         if (feedbackMessage != null && feedbackMessage!.isNotEmpty)
           Positioned(
             top: -40,
             left: 0,
             right: 0,
             child: Center(
               child: Text(
                 feedbackMessage!,
                 style: TextStyle(
                   fontFamily: AppTheme.fontFamily,
                   color: Colors.white,
                   fontWeight: FontWeight.bold,
                   fontSize: 18,
                   shadows: const [
                     Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
                     Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 4)),
                   ],
                 ),
               ),
             ),
           ),

         // 4. Contenu
         Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             // Ligne de saisie
             SizedBox(
               height: inputRowHeight,
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Row(
                   children: [
                     // Mélanger (Gauche)
                     PremiumRoundButton(
                       icon: Icons.shuffle_rounded,
                       onTap: onShuffle,
                       size: 64,
                       showHole: false,
                       iconGradient: const [AppTheme.coinRimTop, AppTheme.coinRimBottom],
                     ),
                     
                     const SizedBox(width: 8),

                     // Cartouche (Centre étendu)
                     Expanded(
                       child: GameInputCartridge(
                         currentInput: currentInput,
                         onBackspace: onBackspace,
                         isSuccessFlash: isSuccessFlash,
                       ),
                     ),

                     const SizedBox(width: 8),

                     // Valider (Droite)
                     PremiumRoundButton(
                       icon: Icons.check_rounded,
                       onTap: onValidate,
                       size: 64,
                       showHole: false,
                       faceGradient: const [AppTheme.btnValidateHighlight, AppTheme.btnValidate],
                       iconGradient: const [AppTheme.coinBorderDark, AppTheme.coinBorderDark], 
                     ),
                   ],
                 ),
               ),
             ),
             
             const SizedBox(height: 8),

             // Zone des lettres
             GameLetterGrid(
                shuffledLetters: shuffledLetters,
                onLetterTap: onLetterTap,
             ),
             
             const SizedBox(height: 16), 
           ],
         ),
       ],
    );
  }
}
