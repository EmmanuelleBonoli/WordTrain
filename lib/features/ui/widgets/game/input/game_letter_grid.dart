import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/widgets/common/button/bouncing_scale_button.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_coin_letter.dart';

class GameLetterGrid extends StatelessWidget {
  final List<String> shuffledLetters;
  final Function(String) onLetterTap;

  const GameLetterGrid({
    super.key,
    required this.shuffledLetters,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    final int count = shuffledLetters.length;
    final double letterSize = 64.0; 
    final double totalWidth = MediaQuery.of(context).size.width;
    final double center = totalWidth / 2;
    
    final int cols = (count / 2.0).ceil(); 
    
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (index) {
           final bool isTop = index < cols;
           final int colIndex = index % cols; 
           
           final int rowCount = isTop ? cols : (count - cols);
           final double midIndex = (rowCount - 1) / 2.0;
           final double diff = colIndex - midIndex; 
           
           // Étalement horizontal
           final double xOffset = diff * (letterSize + 16); 
           
           // Calcul Y
           // Rangée du haut : 0. Rangée du bas : 74.
           final double yBase = isTop ? 0.0 : 74.0;
           
           // Courbure
           final double curveFactor = 1.5; 
           
           final double yCurve = isTop 
               ? (diff * diff) * curveFactor   
               : - (diff * diff) * curveFactor; 
           
           final letter = shuffledLetters[index];
           
           return Positioned(
             left: center + xOffset - (letterSize / 2),
             top: yBase + yCurve, 
             child: BouncingScaleButton(
               onTap: () => onLetterTap(letter),
               showShadow: false,
               child: GameCoinLetter(letter: letter, size: letterSize),
             ),
           );
        }),
      ),
    );
  }

}
