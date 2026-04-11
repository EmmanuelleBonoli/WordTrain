import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/styles/app_theme.dart';

class GameInputCartridge extends StatelessWidget {
  final String currentInput;
  final VoidCallback onBackspace;
  final bool isSuccessFlash;

  const GameInputCartridge({
    super.key,
    required this.currentInput,
    required this.onBackspace,
    this.isSuccessFlash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.coinBorderDark, 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.coinRimTop, AppTheme.coinRimBottom],
            begin: Alignment.topCenter, end: Alignment.bottomCenter
          ),
          borderRadius: BorderRadius.circular(28.5),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Container(
           decoration: BoxDecoration(
            color: isSuccessFlash 
                ? AppTheme.btnValidate.withValues(alpha: 0.6) 
                : AppTheme.coinBorderDark, 
            borderRadius: BorderRadius.circular(24.5),
           ),
           padding: const EdgeInsets.all(1.5),
           child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             decoration: BoxDecoration(
               color: AppTheme.inputCartridgeFill, 
               borderRadius: BorderRadius.circular(23),
             ),
             child: Row(
               children: [
                 // Zone de texte
                 Expanded(
                   child: FittedBox(
                     fit: BoxFit.scaleDown,
                     alignment: Alignment.center,
                     child: Text(
                       currentInput,
                       style: TextStyle(
                         fontFamily: AppTheme.fontFamily,
                         fontSize: 28,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                         letterSpacing: 2.0,
                         shadows: const [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1,1))],
                       ),
                     ),
                   ),
                 ),
                 
                 // Retour Arrière (Intérieur Droite)
                 if (currentInput.isNotEmpty)
                   GestureDetector(
                     onTap: onBackspace,
                     child: Padding(
                       padding: const EdgeInsets.only(left: 8),
                       child: Icon(Icons.backspace_rounded, color: Colors.white.withValues(alpha: 0.8), size: 28),
                     ),
                   ),
               ],
             ),
           ),
        ),
      ),
    );
  }
}
