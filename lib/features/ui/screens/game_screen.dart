import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_riders/features/gameplay/controllers/game_controller.dart';
import 'package:word_riders/features/gameplay/controllers/physics_progress_controller.dart';
import 'package:word_riders/features/gameplay/services/player_preferences.dart';
import 'package:word_riders/features/gameplay/services/word_service.dart';
import 'package:word_riders/features/ui/widgets/game/game_header.dart';
import 'package:word_riders/features/ui/widgets/game/game_header_background.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_input_area.dart';
import 'package:word_riders/features/ui/widgets/game/game_race_area.dart';
import 'package:word_riders/features/ui/widgets/game/overlays/game_end_overlay.dart';
import 'package:word_riders/features/ui/widgets/game/overlays/game_pause_overlay.dart';
import 'package:word_riders/features/ui/widgets/game/overlays/no_lives_overlay.dart';
import 'package:word_riders/features/ui/widgets/game/game_timeline.dart';
import 'package:word_riders/features/ui/widgets/game/game_bonus_panel.dart';

import 'package:word_riders/features/ui/widgets/game/overlays/training_config_overlay.dart';

class GameScreen extends StatelessWidget {
  final bool isCampaign;

  const GameScreen({super.key, this.isCampaign = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(context.locale.languageCode),
      create: (ctx) => GameController(
        isCampaign: isCampaign,
        locale: context.locale.languageCode,
        wordService: ctx.read<WordService>(),
      ),
      child: const _GameScreenContent(),
    );
  }
}

class _GameScreenContent extends StatefulWidget {
  const _GameScreenContent();

  @override
  State<_GameScreenContent> createState() => _GameScreenContentState();
}

class _GameScreenContentState extends State<_GameScreenContent>
    with SingleTickerProviderStateMixin {
  late final PhysicsProgressController _physicsController;

  static const double _spriteSize = 120.0 * 0.9;

  @override
  void initState() {
    super.initState();
    _physicsController = PhysicsProgressController(this);
    _physicsController.addListener(_onPhysicsUpdate);
  }

  @override
  void dispose() {
    _physicsController.removeListener(_onPhysicsUpdate);
    _physicsController.dispose();
    super.dispose();
  }

  void _onPhysicsUpdate() {
    setState(() {});
  }

  /// Calcule l'offset cible depuis la progression du joueur.
  double _computeTargetOffset(double rabbitProgress, double screenWidth, bool isOver) {
    final double centerX = screenWidth / 2 - _spriteSize / 2;
    // En baissant cette valeur (ex: 0.03 au lieu de 0.13), on multiplie la distance virtuelle totale.
    // Les personnages devront courir beaucoup plus de pixels pour faire 1% de progression,
    // ce qui donne l'impression d'une vitesse et d'une distance de course plus longue !
    final double worldScale = centerX / 0.04; 
    final double maxScroll = (worldScale - screenWidth).clamp(0.0, double.infinity);
    if (isOver && rabbitProgress >= 1.0) return maxScroll;
    final double playerWorldX = rabbitProgress * worldScale;
    return (playerWorldX - centerX).clamp(0.0, maxScroll);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (controller.status == GameStatus.waitingForConfig) {
      return TrainingConfigOverlay(
        onSelectLength: (length) => controller.startTraining(length),
        onBack: () => context.pop(),
      );
    }

    // Mise à jour de l'offset cible à chaque rebuild du controller
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isOver = controller.status == GameStatus.won ||
        controller.status == GameStatus.lost;
        
    // Mise à jour des cibles pour le contrôleur de physique
    _physicsController.updateTargets(controller.rabbitProgress, controller.foxProgress);

    // On calcule l'offset directement depuis la progression lissée du joueur.
    // Ainsi la caméra suit naturellement et fluidement le joueur avec la même inertie.
    final double smoothScrollOffset = _computeTargetOffset(
      _physicsController.smoothRabbitProgress,
      screenWidth,
      isOver,
    );

    final double bgShift = smoothScrollOffset % screenWidth;

    void onValidate() {
      controller.validate();
    }

    void onSettingsTap() async {
      controller.pauseGame();
      await context.push('/settings');

      // Si on change de langue dans les réglages, cet écran est détruit (nouvelle ValueKey).
      // On s'assure donc que le contexte est toujours monté avant d'utiliser le controller.
      if (!context.mounted) return;

      controller.resumeGame();
    }

    void onBackTap() {
      controller.pauseGame();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GamePauseOverlay(
          title: context.tr('game.pause_title'),
          isCampaign: controller.isCampaign,
          onResume: () {
            Navigator.pop(ctx);
            controller.resumeGame();
          },
          onRestart: () async {
            Navigator.pop(ctx);

            // En campagne, recommencer en cours de jeu coûte une vie (abandon)
            if (controller.isCampaign) {
              final success = await controller.consumeLifeForRestart();
              if (!success) {
                // Si plus de vie : afficher la modale pour recharger
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (dialogCtx) => NoLivesOverlay(
                      fromGame: true,
                      onLivesReplenished: () {
                        controller.restartGame();
                      },
                    ),
                  );

                  if (context.mounted) {
                    final currentLives = await PlayerPreferences.getLives();
                    if (currentLives <= 0) {
                      if (context.mounted) {
                        context.go('/campaign');
                      }
                    }
                  }
                }
                return;
              }
            }

            controller.restartGame();
          },
          onQuit: () async {
            Navigator.pop(ctx);
            await controller.quitGame();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fond défilant plein écran — offset lissé pour éviter les bonds.
          // Timeline et zone de course défilent sur le même arrière-plan en continu.
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -bgShift,
                    width: screenWidth,
                    top: 0,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/background/game_bg.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: screenWidth - bgShift,
                    width: screenWidth,
                    top: 0,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/background/game_bg.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Header Background Decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top + 55,
            child: const GameHeaderBackground(),
          ),

          // 3. Contenu Principal
          SafeArea(
            child: Column(
              children: [
                GameHeader(
                  onBack: onBackTap,
                  onSettings: onSettingsTap,
                  isCampaign: controller.isCampaign,
                  currentStage: controller.currentStage,
                ),

                GameTimeline(
                  rabbitProgress: _physicsController.smoothRabbitProgress,
                  foxProgress: _physicsController.smoothFoxProgress,
                  showFox: controller.isCampaign,
                ),

                // Zone de Course — reçoit la progression et l'offset lissés par la physique.
                Expanded(
                  child: GameRaceArea(
                    isCampaign: controller.isCampaign,
                    rabbitProgress: _physicsController.smoothRabbitProgress,
                    foxProgress: _physicsController.smoothFoxProgress,
                    isGameOver: isOver,
                    smoothScrollOffset: smoothScrollOffset,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GameInputArea(
                    feedbackMessage: controller.feedbackMessage,
                    currentInput: controller.currentInput,
                    shuffledLetters: controller.shuffledLetters,
                    onBackspace: controller.onBackspace,
                    onValidate: onValidate,
                    onShuffle: controller.onShuffle,
                    onLetterTap: controller.onLetterTap,
                    isSuccessFlash: controller.isSuccessFlash,
                  ),
                ),

                if (controller.isCampaign)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GameBonusPanel(controller: controller),
                  ),
              ],
            ),
          ),

          // 4. Overlays (Pause & Fin)
          if (isOver)
            GameEndOverlay(
              currentLevel: controller.currentStage,
              isWon: controller.status == GameStatus.won,
              isCampaign: controller.isCampaign,
              onQuit: () async {
                if (controller.isCampaign && controller.status == GameStatus.lost) {
                  await controller.concedeGame();
                }
                if (context.mounted) Navigator.pop(context);
              },
              onRestart: () => controller.restartGame(),
              onContinue: () => Navigator.pop(context),
              onRevive: () => controller.revive(),
            ),
        ],
      ),
    );
  }
}
