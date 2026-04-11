import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/styles/app_theme.dart';

class GameTimelineTrack extends StatelessWidget {
  final double progress; 
  final String imagePath;
  final Duration animationDuration;
  final Curve curve;
  final bool highlighted;
  final double frozenOpacity;
  final String? badgeText;

  const GameTimelineTrack({
    super.key,
    required this.progress,
    required this.imagePath,
    this.animationDuration = Duration.zero,
    this.curve = Curves.linear,
    this.highlighted = false,
    this.frozenOpacity = 0.0,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    const double flagSize = 40.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= flagSize) {
           return const SizedBox();
        }

        final maxPos = (width - flagSize).clamp(0.0, double.infinity);
        double pos = (maxPos * progress);
        if (pos.isNaN || pos.isInfinite) pos = 0.0;
        pos = pos.clamp(0.0, maxPos);

        return SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: frozenOpacity > 0.1
                        ? Color.lerp(AppTheme.tileFace, Colors.cyan.shade100, frozenOpacity)!
                        : AppTheme.tileFace,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: highlighted ? Colors.blueAccent : AppTheme.brown,
                      width: highlighted ? 2.5 : 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0, top: 0, bottom: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/characters/finish_flag2.png',
                    width: flagSize, height: flagSize, fit: BoxFit.contain,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: animationDuration,
                curve: curve,
                left: pos,
                top: 0, bottom: 0,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Personnage
                      Opacity(
                        opacity: 1.0 - frozenOpacity * 0.3,
                        child: Image.asset(
                          imagePath,
                          width: flagSize, height: flagSize, fit: BoxFit.contain,
                        ),
                      ),
                      // Overlay Cyan pour le gel
                      if (frozenOpacity > 0.01)
                        Opacity(
                          opacity: frozenOpacity * 0.5,
                          child: Container(
                            width: flagSize, height: flagSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.cyan.shade200,
                            ),
                          ),
                        ),
                      // Icône flocon
                      if (frozenOpacity > 0.05)
                        Positioned(
                          top: -4, right: -4,
                          child: Opacity(
                            opacity: frozenOpacity,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.cyan,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      // Badge Texte (ex: x2)
                      if (badgeText != null)
                        Positioned(
                          top: 0, right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              badgeText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Round',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
