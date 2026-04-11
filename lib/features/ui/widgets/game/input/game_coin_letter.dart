import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/styles/app_theme.dart';

class GameCoinLetter extends StatelessWidget {
  final String letter;
  final double size;
  final bool highlight;
  final bool showHalo;

  const GameCoinLetter({
    super.key,
    required this.letter,
    this.size = 64.0,
    this.highlight = false,
    this.showHalo = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Bordure Extérieure Sombre
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.coinBorderDark,
              boxShadow: [
                if (highlight)
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.7),
                    blurRadius: size * 0.25,
                    spreadRadius: size * 0.05,
                  )
                else if (showHalo)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.75),
                    blurRadius: size * 0.25,
                    spreadRadius: size * 0.06,
                  ),
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(size * 0.025),
            child: Container(
              // 2. Bord (Dégradé)
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.coinRimTop, AppTheme.coinRimBottom],
                ),
              ),
              padding: EdgeInsets.all(size * 0.045),
              child: Container(
                // 3. Bordure Intérieure Sombre
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: highlight
                      ? Colors.orange.withValues(alpha: 0.3)
                      : AppTheme.coinBorderDark,
                ),
                padding: EdgeInsets.all(size * 0.02),
                child: Container(
                  // 4. Face
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.levelSignFace,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w900,
                      color: highlight ? Colors.deepOrange : AppTheme.coinBorderDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
