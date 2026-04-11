import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// Classe utilitaire gérant la simulation physique d'un modèle masse-ressort.
/// Elle reçoit des "cibles" (targets) et intègre une vélocité à chaque tick
/// pour produire des positions lissées (smoothProgress).
class PhysicsProgressController extends ChangeNotifier {
  double _smoothRabbitProgress = 0.0;
  double _rabbitVelocity = 0.0;

  double _smoothFoxProgress = 0.0;
  double _foxVelocity = 0.0;

  // Paramètres physiques du ressort 
  // Des valeurs plus hautes = mouvement plus rapide et nerveux
  static const double _springK = 8.0; 
  static const double _springC = 6.0;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  double _targetRabbit = 0.0;
  double _targetFox = 0.0;

  double get smoothRabbitProgress => _smoothRabbitProgress;
  double get smoothFoxProgress => _smoothFoxProgress;

  PhysicsProgressController(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick)..start();
  }

  void updateTargets(double newRabbit, double newFox) {
    _targetRabbit = newRabbit;
    _targetFox = newFox;
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }
    final double dt = (elapsed - _lastElapsed!).inMicroseconds / 1e6;
    _lastElapsed = elapsed;

    bool needsNotify = false;

    // Ressort Rabbit
    final double rabbitDiff = _targetRabbit - _smoothRabbitProgress;
    if (rabbitDiff.abs() > 0.0001 || _rabbitVelocity.abs() > 0.0001) {
      final double accel = _springK * rabbitDiff - _springC * _rabbitVelocity;
      _rabbitVelocity += accel * dt;
      _smoothRabbitProgress += _rabbitVelocity * dt;

      if (rabbitDiff.abs() < 0.001 && _rabbitVelocity.abs() < 0.001) {
        _smoothRabbitProgress = _targetRabbit;
        _rabbitVelocity = 0.0;
      }
      needsNotify = true;
    }

    // Ressort Fox
    final double foxDiff = _targetFox - _smoothFoxProgress;
    if (foxDiff.abs() > 0.0001 || _foxVelocity.abs() > 0.0001) {
      final double accel = _springK * foxDiff - _springC * _foxVelocity;
      _foxVelocity += accel * dt;
      _smoothFoxProgress += _foxVelocity * dt;

      if (foxDiff.abs() < 0.001 && _foxVelocity.abs() < 0.001) {
        _smoothFoxProgress = _targetFox;
        _foxVelocity = 0.0;
      }
      needsNotify = true;
    }

    if (needsNotify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
