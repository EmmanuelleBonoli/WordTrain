import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/styles/app_theme.dart';
import 'package:word_riders/features/ui/widgets/game/game_timeline_track.dart';

class GameTimeline extends StatelessWidget {
  final double rabbitProgress;
  final double foxProgress;
  final bool showFox;
  final bool separateTracks;

  const GameTimeline({
    super.key, 
    required this.rabbitProgress,
    required this.foxProgress,
    this.showFox = true,
    this.separateTracks = false,
  });

  @override
  Widget build(BuildContext context) {
    if (separateTracks) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showFox)
              GameTimelineTrack(
                progress: foxProgress,
                imagePath: 'assets/images/characters/fox_head2.png',
                animationDuration: const Duration(milliseconds: 1000),
              ),
            
            if (showFox) const SizedBox(height: 8),

            GameTimelineTrack(
              progress: rabbitProgress,
              imagePath: 'assets/images/characters/rabbit_head2.png',
              animationDuration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          
          if (!width.isFinite || width <= 40) {
             return const SizedBox();
          }

          final maxPos = (width - 40).clamp(0.0, double.infinity);
          
          double rabbitPos = (maxPos * rabbitProgress);
          if (rabbitPos.isNaN || rabbitPos.isInfinite) rabbitPos = 0.0;
          rabbitPos = rabbitPos.clamp(0.0, maxPos);

          double foxPos = (maxPos * foxProgress);
          if (foxPos.isNaN || foxPos.isInfinite) foxPos = 0.0;
          foxPos = foxPos.clamp(0.0, maxPos);
          
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 48,
                alignment: Alignment.center,
                child: Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.tileFace,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.brown, width: 2),
                  ),
                ),
              ),
              
              Positioned(
                right: 0,
                top: 0, bottom: 0, 
                child: Center(
                    child: Image.asset(
                      'assets/images/characters/finish_flag2.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                ), 
              ),

              if (showFox)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.linear,
                  left: foxPos, 
                  top: 0, bottom: 0, 
                  child: Center(
                      child: Image.asset(
                        'assets/images/characters/fox_head2.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                  ),
                ),
              
               AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                left: rabbitPos, 
                top: 0, bottom: 0, 
                child: Center(
                    child: Image.asset(
                      'assets/images/characters/rabbit_head2.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                ),
              )
            ],
          );
        }
      ),
    );
  }
}
