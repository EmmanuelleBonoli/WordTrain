import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/styles/app_theme.dart';
import 'package:word_riders/features/ui/widgets/common/button/bouncing_scale_button.dart';
import 'package:word_riders/features/ui/widgets/common/button/premium_round_button.dart';
import 'package:word_riders/features/ui/widgets/game/game_timeline.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_coin_letter.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_input_cartridge.dart';

// Données de démo pour l'étape 1 : mot et tuiles par langue.
class _DemoData {
  final String word;
  final List<String> tiles; // 6 lettres affichées (2 rangées × 3)
  final List<int> tapIndices; // indices dans tiles à taper pour former le mot

  const _DemoData({
    required this.word,
    required this.tiles,
    required this.tapIndices,
  });
}

// Overlay tutoriel en 2 étapes — présente les mécaniques du jeu.
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({super.key, required this.onComplete});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  static const int _totalSteps = 2;

  // Animation étape 2 : course lapin vs renard
  late AnimationController _animController;
  late Animation<double> _rabbitProgress;
  late Animation<double> _foxProgress;

  // Animation démo main (étape 1, en boucle)
  late AnimationController _demoAnimController;
  late _DemoData _demoData;

  String _demoInput = '';
  bool _demoValidated = false;
  int _lastTapIndex = 0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _rabbitProgress = const AlwaysStoppedAnimation(0.0);
    _foxProgress = const AlwaysStoppedAnimation(0.0);

    // Durée 6500ms : séquence de taps (0→0.62) + affichage validé ~2s (0.62→0.93) + fade
    _demoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )
      ..addListener(_onDemoTick)
      ..repeat();

    _demoData = _getDemoData('en');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _demoData = _getDemoData(context.locale.languageCode);
  }

  /// Met à jour la saisie démo à chaque tick.
  /// La séquence est compressée dans 0–0.62 ; 0.62–0.93 affiche l'état validé (~2s).
  void _onDemoTick() {
    if (!mounted) return;
    final v = _demoAnimController.value;

    // Phase reset : début de cycle
    if (v < 0.03) {
      if (_demoInput.isNotEmpty || _demoValidated) {
        setState(() {
          _lastTapIndex = 0;
          _demoInput = '';
          _demoValidated = false;
        });
      }
      return;
    }

    int newTapIndex;
    bool newValidated = false;

    if (v >= 0.62) {
      newTapIndex = 4;
      newValidated = true; // déclenche l'avancée du lapin
    } else if (v >= 0.50) {
      newTapIndex = 4;
    } else if (v >= 0.37) {
      newTapIndex = 3;
    } else if (v >= 0.25) {
      newTapIndex = 2;
    } else if (v >= 0.12) {
      newTapIndex = 1;
    } else {
      newTapIndex = 0;
    }

    if (newTapIndex != _lastTapIndex || newValidated != _demoValidated) {
      setState(() {
        _lastTapIndex = newTapIndex;
        _demoInput = _demoData.word.substring(
          0,
          newTapIndex.clamp(0, _demoData.word.length),
        );
        _demoValidated = newValidated;
      });
    }
  }

  void _setupRaceAnimation() {
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(milliseconds: 2200);
    _rabbitProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _foxProgress = Tween<double>(begin: 0.0, end: 0.58).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
  }

  void _goNext() {
    if (_currentStep < _totalSteps - 1) {
      _setupRaceAnimation();
      setState(() => _currentStep = _currentStep + 1);
      _animController.forward();
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _demoAnimController.dispose();
    super.dispose();
  }

  // --- Données de démo par langue ---

  static _DemoData _getDemoData(String locale) {
    switch (locale) {
      case 'fr':
        return const _DemoData(
          word: 'BRAS',
          tiles: ['T', 'B', 'R', 'N', 'A', 'S'],
          tapIndices: [1, 2, 4, 5],
        );
      case 'es':
        return const _DemoData(
          word: 'META',
          tiles: ['R', 'M', 'E', 'S', 'T', 'A'],
          tapIndices: [1, 2, 4, 5],
        );
      case 'it':
        return const _DemoData(
          word: 'VELA',
          tiles: ['N', 'V', 'E', 'I', 'L', 'A'],
          tapIndices: [1, 2, 4, 5],
        );
      case 'de':
        return const _DemoData(
          word: 'LAUF',
          tiles: ['R', 'L', 'A', 'T', 'U', 'F'],
          tapIndices: [1, 2, 4, 5],
        );
      default: // 'en'
        return const _DemoData(
          word: 'WORD',
          tiles: ['S', 'W', 'O', 'E', 'R', 'D'],
          tapIndices: [1, 2, 4, 5],
        );
    }
  }

  // --- Build principal ---

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/game_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.50)),
          ),

          SafeArea(
            child: Column(
              children: [
                // Contenu centré verticalement (dots + titre + étape)
                Flexible(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStepDots(),
                                const SizedBox(height: 18),
                                _buildStepSubtitle(context),
                                const SizedBox(height: 28),
                                _buildStepContent(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bouton collé en bas
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: _buildNextButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Indicateur de progression ---

  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (i) {
        final isActive = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.btnValidate
                : AppTheme.tileFace.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // --- Sous-titre de l'étape courante ---

  Widget _buildStepSubtitle(BuildContext context) {
    const keys = ['tutorial.step1_title', 'tutorial.step2_title'];
    return Text(
      context.tr(keys[_currentStep]),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Round',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
    );
  }

  // --- Contenu par étape ---

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Merged();
      default:
        return _buildRaceStep();
    }
  }

  // --- Étape 0 : timeline + cartouche+bouton + lettres (layout identique au vrai jeu) ---
  Widget _buildStep0Merged() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // --- Dimensions calquées sur GameTimeline + GameInputArea + GameLetterGrid ---
          const double timelineH = 64.0;
          const double gap1 = 8.0;
          const double rowH = 80.0;
          const double gap2 = 8.0;
          const double gridY = timelineH + gap1 + rowH + gap2; // 160
          const double gridH = 140.0; // identique à GameLetterGrid SizedBox
          const double totalH = gridY + gridH; // 300
          const double btnSize = 64.0;
          const double cartGap = 8.0;
          const double flagSize = 40.0;

          // Positions Y précalculées (PremiumRoundButton 64px, cartouche 60px)
          const double cartTopY = timelineH + gap1 + (rowH - 60) / 2; // 82
          const double btnTopY = timelineH + gap1 + (rowH - btnSize) / 2; // 80

          // --- Lettres circulaires (même disposition courbe que GameLetterGrid) ---
          const double letterSize = 64.0;
          const double spacing = 80.0; // letterSize + 16 (identique au jeu)
          const double curveFactor = 1.5;

          // Centres des 6 lettres pour le calcul des waypoints de la main
          final tileCenters = List.generate(6, (i) {
            final bool isTop = i < 3;
            final double diff = (i % 3).toDouble() - 1.0; // -1, 0, 1
            final double yCurve = diff * diff * curveFactor;
            return Offset(
              w / 2 + diff * spacing,
              isTop
                  ? gridY + yCurve + letterSize / 2
                  : gridY + 74 - yCurve + letterSize / 2,
            );
          });

          // Waypoints : lettres tapées + bouton valider
          final validateCenter = Offset(
            w - btnSize / 2,
            timelineH + gap1 + rowH / 2,
          );
          final waypoints = [
            ..._demoData.tapIndices.map((i) => tileCenters[i]),
            validateCenter,
          ];

          // Départ de la main (hors zone, au-dessus du premier waypoint)
          final startPos = Offset(tileCenters[_demoData.tapIndices[0]].dx, gridY - 40);

          // Lapin sur la timeline
          final double maxPos = (w - flagSize).clamp(0.0, double.infinity);
          final double rabbitLeft = _demoValidated ? maxPos * 0.55 : 0.0;

          return SizedBox(
            height: totalH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // --- Timeline (identique à GameTimeline) ---
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: timelineH,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Align(
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
                        right: 0, top: 0, bottom: 0,
                        child: Center(
                          child: Image.asset(
                            'assets/images/characters/finish_flag2.png',
                            width: flagSize, height: flagSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        left: rabbitLeft,
                        top: 0, bottom: 0,
                        child: Center(
                          child: Image.asset(
                            'assets/images/characters/rabbit_head2.png',
                            width: flagSize, height: flagSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Cartouche de saisie ---
                Positioned(
                  top: cartTopY,
                  left: 0,
                  right: btnSize + cartGap,
                  height: 60,
                  child: GameInputCartridge(
                    currentInput: _demoInput,
                    onBackspace: () {},
                    isSuccessFlash: _demoValidated,
                  ),
                ),

                // --- Bouton Valider (PremiumRoundButton vert — identique au vrai jeu) ---
                Positioned(
                  top: btnTopY,
                  right: 0,
                  width: btnSize,
                  height: btnSize,
                  child: PremiumRoundButton(
                    icon: Icons.check_rounded,
                    size: btnSize,
                    showHole: false,
                    faceGradient: const [
                      AppTheme.btnValidateHighlight,
                      AppTheme.btnValidate,
                    ],
                    iconGradient: const [
                      AppTheme.coinBorderDark,
                      AppTheme.coinBorderDark,
                    ],
                  ),
                ),

                // --- Lettres circulaires (même style que GameLetterGrid) ---
                ...List.generate(6, (i) {
                  final bool isTop = i < 3;
                  final double diff = (i % 3).toDouble() - 1.0;
                  final double yCurve = diff * diff * curveFactor;
                  final double tileLeft = w / 2 + diff * spacing - letterSize / 2;
                  final double tileTop =
                      isTop ? gridY + yCurve : gridY + 74 - yCurve;
                  return Positioned(
                    left: tileLeft,
                    top: tileTop,
                    child: GameCoinLetter(
                      letter: _demoData.tiles[i],
                      size: letterSize,
                    ),
                  );
                }),

                // --- Main animée ---
                AnimatedBuilder(
                  animation: _demoAnimController,
                  builder: (context, _) {
                    final v = _demoAnimController.value;
                    final pos = _computeHandPosition(v, waypoints, startPos);
                    final scale = _computeHandScale(v);
                    final opacity = _computeHandOpacity(v);
                    return Positioned(
                      left: pos.dx - 18,
                      top: pos.dy - 18,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: _buildGhostHand(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildGhostHand() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.90),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.touch_app_rounded,
        color: AppTheme.darkBrown,
        size: 22,
      ),
    );
  }

  // --- Calculs d'animation de la main ---
  // Séquence compressée dans 0→0.62 (durée totale 6500ms) :
  //   0.00–0.03 : reset
  //   0.03–0.065 : apparition, déplacement vers lettre 1
  //   0.065–0.12 : survol lettre 1
  //   0.12–0.19 : déplacement vers lettre 2
  //   0.19–0.25 : survol lettre 2
  //   0.25–0.32 : déplacement vers lettre 3
  //   0.32–0.37 : survol lettre 3
  //   0.37–0.45 : déplacement vers lettre 4
  //   0.45–0.50 : survol lettre 4
  //   0.50–0.57 : déplacement vers bouton valider
  //   0.57–0.62 : survol + tap bouton valider
  //   0.62–0.93 : état validé affiché (~2s, lapin visible sur timeline)
  //   0.93–1.00 : fondu disparition
  Offset _computeHandPosition(
    double v,
    List<Offset> waypoints,
    Offset startPos,
  ) {
    if (v < 0.065) {
      return Offset.lerp(startPos, waypoints[0], (v - 0.03).clamp(0, 0.035) / 0.035)!;
    }
    if (v < 0.12) return waypoints[0];
    if (v < 0.19) {
      return Offset.lerp(waypoints[0], waypoints[1], (v - 0.12) / 0.07)!;
    }
    if (v < 0.25) return waypoints[1];
    if (v < 0.32) {
      return Offset.lerp(waypoints[1], waypoints[2], (v - 0.25) / 0.07)!;
    }
    if (v < 0.37) return waypoints[2];
    if (v < 0.45) {
      return Offset.lerp(waypoints[2], waypoints[3], (v - 0.37) / 0.08)!;
    }
    if (v < 0.50) return waypoints[3];
    if (v < 0.57) {
      return Offset.lerp(waypoints[3], waypoints[4], (v - 0.50) / 0.07)!;
    }
    return waypoints[4]; // reste sur le bouton valider jusqu'au fade
  }

  /// Rétrécit brièvement la main au moment de chaque tap.
  double _computeHandScale(double v) {
    final bool tapping = (v >= 0.09 && v < 0.12) ||
        (v >= 0.22 && v < 0.25) ||
        (v >= 0.35 && v < 0.37) ||
        (v >= 0.48 && v < 0.50) ||
        (v >= 0.59 && v < 0.62);
    return tapping ? 0.65 : 1.0;
  }

  /// Fondu d'apparition et de disparition de la main.
  double _computeHandOpacity(double v) {
    if (v < 0.03) return 0.0;
    if (v < 0.065) return (v - 0.03) / 0.035;
    if (v > 0.93) return (1.0 - v) / 0.07;
    return 1.0;
  }

  // --- Étape 1 : course lapin vs renard ---

  Widget _buildRaceStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) => GameTimeline(
          rabbitProgress: _rabbitProgress.value,
          foxProgress: _foxProgress.value,
          showFox: true,
          separateTracks: true,
        ),
      ),
    );
  }

  // --- Bouton suivant ---

  Widget _buildNextButton(BuildContext context) {
    final isLast = _currentStep == _totalSteps - 1;
    return BouncingScaleButton(
      onTap: _goNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.btnValidateHighlight, AppTheme.btnValidate],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(color: AppTheme.tileShadow, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          isLast
              ? context.tr('tutorial.start')
              : context.tr('tutorial.next'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Round',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.darkBrown,
          ),
        ),
      ),
    );
  }
}
