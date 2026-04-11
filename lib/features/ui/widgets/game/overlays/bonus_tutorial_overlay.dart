import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:word_riders/features/ui/styles/app_theme.dart';
import 'package:word_riders/features/ui/widgets/common/button/bouncing_scale_button.dart';
import 'package:word_riders/features/ui/widgets/common/button/premium_round_button.dart';
import 'package:word_riders/features/ui/widgets/game/game_timeline_track.dart';
import 'package:word_riders/features/ui/widgets/game/input/game_coin_letter.dart';

/// Types de bonus disponibles dans le jeu.
enum BonusType { extraLetter, doubleDistance, freezeRival }

/// Données statiques associées à chaque type de bonus.
class _BonusData {
  final IconData icon;
  final List<Color> colors;
  final String nameKey;
  final String descKey;

  const _BonusData({
    required this.icon,
    required this.colors,
    required this.nameKey,
    required this.descKey,
  });
}

const _kBonusData = {
  BonusType.extraLetter: _BonusData(
    icon: Icons.text_increase_rounded,
    colors: [Colors.orange, Colors.deepOrange],
    nameKey: 'tutorial.bonus_extra_letter_name',
    descKey: 'tutorial.bonus_extra_letter_desc',
  ),
  BonusType.doubleDistance: _BonusData(
    icon: Icons.double_arrow_rounded,
    colors: [Colors.blue, Colors.indigo],
    nameKey: 'tutorial.bonus_double_distance_name',
    descKey: 'tutorial.bonus_double_distance_desc',
  ),
  BonusType.freezeRival: _BonusData(
    icon: Icons.ac_unit_rounded,
    colors: [Colors.cyan, Colors.blueAccent],
    nameKey: 'tutorial.bonus_freeze_rival_name',
    descKey: 'tutorial.bonus_freeze_rival_desc',
  ),
};

/// Overlay tutoriel pour un bonus donné.
/// Affiche une animation en boucle illustrant l'effet du bonus.
class BonusTutorialOverlay extends StatefulWidget {
  final BonusType bonusType;
  final VoidCallback onComplete;

  const BonusTutorialOverlay({
    super.key,
    required this.bonusType,
    required this.onComplete,
  });

  @override
  State<BonusTutorialOverlay> createState() => _BonusTutorialOverlayState();
}

class _BonusTutorialOverlayState extends State<BonusTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  _BonusData get _data => _kBonusData[widget.bonusType]!;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fond identique à l'écran de jeu
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/game_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),

          SafeArea(
            child: Column(
              children: [
                // Contenu centré verticalement
                Flexible(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 32,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icône du bonus (pulsation)
                                _buildPulsingIcon(),
                                const SizedBox(height: 16),
                                // Nom du bonus
                                Text(
                                  context.tr(_data.nameKey),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Round',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(0, 2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Description
                                Text(
                                  context.tr(_data.descKey),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Round',
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Animation de l'effet
                                _buildDemo(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bouton fermeture
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: _buildCloseButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Icône du bonus avec pulsation lente ---

  Widget _buildPulsingIcon() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Pulsation douce : scale entre 0.92 et 1.08
        final pulse =
            0.92 + 0.16 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi * 1.2));
        return Transform.scale(
          scale: pulse,
          child: PremiumRoundButton(
            icon: _data.icon,
            size: 72,
            showHole: false,
            faceGradient: _data.colors,
            iconGradient: const [Colors.white, Colors.white70],
          ),
        );
      },
    );
  }

  // --- Dispatch vers la bonne démo animée ---

  Widget _buildDemo() {
    switch (widget.bonusType) {
      case BonusType.extraLetter:
        return _buildExtraLetterDemo();
      case BonusType.doubleDistance:
        return _buildDoubleDistanceDemo();
      case BonusType.freezeRival:
        return _buildFreezeRivalDemo();
    }
  }

  // ---------------------------------------------------------------------------
  // DÉMO 1 : Lettre supplémentaire
  // Montre les lettres sur 2 rangées avec une voyelle supplémentaire qui slide
  // in depuis le bas après le tap du bonus. Pas d'avancement du lapin car
  // la lettre n'est ajoutée qu'aux tuiles disponibles, pas au mot validé.
  // ---------------------------------------------------------------------------

  Widget _buildExtraLetterDemo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;

        // Phase bouton tap (0.05–0.20) : bouton scale down
        // Phase lettre slide in (0.20–0.45)
        // Phase hold (0.45–0.90)
        // Phase fade out (0.90–1.0)

        final bool buttonTapped = v >= 0.05 && v < 0.20;
        final double btnScale = buttonTapped
            ? (v < 0.12 ? 1.0 - (v - 0.05) / 0.07 * 0.3 : 0.7 + (v - 0.12) / 0.08 * 0.3)
            : 1.0;

        // Voyelle supplémentaire : slide depuis le bas (1.0 = en dessous, 0.0 = en place)
        final double letterSlide = v < 0.20
            ? 1.0
            : v < 0.40
                ? 1.0 - ((v - 0.20) / 0.20)
                : 0.0;
        final double letterOpacity =
            v < 0.18 ? 0.0 : v < 0.30 ? (v - 0.18) / 0.12 : v > 0.92 ? (1 - v) / 0.08 : 1.0;

        final double globalOpacity = v > 0.92 ? (1 - v) / 0.08 : 1.0;

        return Opacity(
          opacity: globalOpacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panneau bonus : bouton Extra Letter mis en avant
              _buildBonusRow(
                activeType: widget.bonusType,
                activeScale: btnScale,
              ),
              const SizedBox(height: 20),
              // Ligne 1 : 3 lettres fixes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in ['W', 'O', 'R'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GameCoinLetter(letter: l, size: 44.0, highlight: false, showHalo: false),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Ligne 2 : 3 lettres fixes + 1 voyelle animée
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in ['D', 'S', 'E'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GameCoinLetter(letter: l, size: 44.0, highlight: false, showHalo: false),
                    ),
                  // Voyelle supplémentaire (slide in depuis le bas)
                  Transform.translate(
                    offset: Offset(0, letterSlide * 56),
                    child: Opacity(
                      opacity: letterOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GameCoinLetter(letter: 'U', size: 44.0, highlight: true, showHalo: false),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DÉMO 2 : Distance × 2
  // Montre deux timelines côte à côte : une sans bonus (avancée normale) et
  // une avec bonus ×2 (avancée doublée).
  // ---------------------------------------------------------------------------

  Widget _buildDoubleDistanceDemo() {
    const double labelW = 36.0;

    return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final v = _controller.value;

            final bool buttonTapped = v >= 0.05 && v < 0.20;
            final double btnScale = buttonTapped
                ? (v < 0.12 ? 1.0 - (v - 0.05) / 0.07 * 0.3 : 0.7 + (v - 0.12) / 0.08 * 0.3)
                : 1.0;

            // Lapin "normal" (track du haut) : v=0.20–0.55 → avance sur 25%
            final double normalPos = v >= 0.20 && v < 0.55
                ? ((v - 0.20) / 0.35).clamp(0.0, 1.0) * 0.25
                : v >= 0.55
                    ? 0.25
                    : 0.0;

            // Lapin "×2" (track du bas) : v=0.20–0.55 → avance sur 75%
            final double boostedPos = v >= 0.20 && v < 0.55
                ? ((v - 0.20) / 0.35).clamp(0.0, 1.0) * 0.75
                : v >= 0.55
                    ? 0.75
                    : 0.0;

            final bool showBadge = v >= 0.20;
            final double globalOpacity = v > 0.92 ? (1 - v) / 0.08 : 1.0;

            return Opacity(
              opacity: globalOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Panneau bonus
                  _buildBonusRow(
                    activeType: widget.bonusType,
                    activeScale: btnScale,
                  ),
                  const SizedBox(height: 20),
                  // Track ×1 (sans bonus)
                  Row(
                    children: [
                      SizedBox(
                        width: labelW,
                        child: Center(
                          child: _buildTrackLabel('×1', active: false),
                        ),
                      ),
                      Expanded(
                        child: GameTimelineTrack(
                          progress: normalPos,
                          imagePath: 'assets/images/characters/rabbit_head2.png',
                          highlighted: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Track ×2 (avec bonus)
                  Row(
                    children: [
                      SizedBox(
                        width: labelW,
                        child: Center(
                          child: _buildTrackLabel('×2', active: true),
                        ),
                      ),
                      Expanded(
                        child: GameTimelineTrack(
                          progress: boostedPos,
                          imagePath: 'assets/images/characters/rabbit_head2.png',
                          highlighted: true,
                          badgeText: showBadge ? '×2' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
  }

  // ---------------------------------------------------------------------------
  // DÉMO 3 : Gel du rival
  // Les deux personnages avancent ensemble, puis le bouton est tapé et le renard
  // se gèle (overlay cyan + icône ❄) tandis que le lapin continue.
  // ---------------------------------------------------------------------------

  Widget _buildFreezeRivalDemo() {
    return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final v = _controller.value;

            final bool buttonTapped = v >= 0.05 && v < 0.20;
            final double btnScale = buttonTapped
                ? (v < 0.12 ? 1.0 - (v - 0.05) / 0.07 * 0.3 : 0.7 + (v - 0.12) / 0.08 * 0.3)
                : 1.0;

            // Phase pré-gel (0.05–0.35) : les deux avancent ensemble
            // Phase gel (0.35–0.90) : fox s'arrête, lapin continue
            double rabbitLeft = 0.0;
            double foxLeft = 0.0;
            double frozenOpacity = 0.0;

            if (v >= 0.05 && v < 0.35) {
              final t = (v - 0.05) / 0.30;
              rabbitLeft = t * 0.28;
              foxLeft = t * 0.26;
            } else if (v >= 0.35 && v < 0.90) {
              // Fox figé à sa position au moment du gel
              foxLeft = 0.26;
              frozenOpacity = ((v - 0.35) / 0.12).clamp(0.0, 1.0);
              // Lapin continue jusqu'à 85%
              rabbitLeft = 0.28 + ((v - 0.35) / 0.55) * 0.57;
            } else if (v >= 0.90) {
              foxLeft = 0.26;
              frozenOpacity = 1.0;
              rabbitLeft = 0.85;
            }

            final double globalOpacity = v > 0.92 ? (1 - v) / 0.08 : 1.0;

            return Opacity(
              opacity: globalOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Panneau bonus
                  _buildBonusRow(
                    activeType: widget.bonusType,
                    activeScale: btnScale,
                  ),
                  const SizedBox(height: 20),
                  // Track lapin
                  GameTimelineTrack(
                    progress: rabbitLeft,
                    imagePath: 'assets/images/characters/rabbit_head2.png',
                  ),
                  const SizedBox(height: 12),
                  // Track renard (avec effet gel)
                  GameTimelineTrack(
                    progress: foxLeft,
                    imagePath: 'assets/images/characters/fox_head2.png',
                    frozenOpacity: frozenOpacity,
                  ),
                ],
              ),
            );
          },
        );
  }

  // ---------------------------------------------------------------------------
  // Widgets helpers partagés
  // ---------------------------------------------------------------------------

  /// Rangée de 3 boutons bonus : celui du bonus actif est mis en avant,
  /// les autres sont grisés. Le bouton actif est animé via [activeScale].
  Widget _buildBonusRow({
    required BonusType activeType,
    required double activeScale,
  }) {
    final types = [
      BonusType.extraLetter,
      BonusType.doubleDistance,
      BonusType.freezeRival,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: types.map((type) {
        final data = _kBonusData[type]!;
        final isActive = type == activeType;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Transform.scale(
            scale: isActive ? activeScale : 1.0,
            child: PremiumRoundButton(
              icon: data.icon,
              size: 56,
              showHole: false,
              faceGradient: isActive
                  ? data.colors
                  : const [Colors.grey, Colors.blueGrey],
              iconGradient: isActive
                  ? const [Colors.white, Colors.white70]
                  : const [Colors.white54, Colors.white30],
            ),
          ),
        );
      }).toList(),
    );
  }



  /// Label ×1 / ×2 stylisé à gauche de la track Double Distance.
  Widget _buildTrackLabel(String text, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.white24,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Round',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: active ? Colors.white : Colors.white60,
        ),
      ),
    );
  }

  // --- Bouton de fermeture ---

  Widget _buildCloseButton(BuildContext context) {
    return BouncingScaleButton(
      onTap: widget.onComplete,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _data.colors,
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
          context.tr('tutorial.start'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Round',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black38,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
