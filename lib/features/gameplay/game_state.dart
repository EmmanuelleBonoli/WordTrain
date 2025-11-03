import 'package:flutter/foundation.dart';

/// Gère l'état du jeu (séparation de la logique métier)
class GameState extends ChangeNotifier {
  String _currentWord = '';
  bool _isGameOver = false;
  bool _playerWon = false;

  String get currentWord => _currentWord;
  bool get isGameOver => _isGameOver;
  bool get playerWon => _playerWon;

  void addLetter(String letter) {
    _currentWord += letter;
    notifyListeners();
  }

  void clearWord() {
    _currentWord = '';
    notifyListeners();
  }

  String consumeWord() {
    final word = _currentWord;
    _currentWord = '';
    notifyListeners();
    return word;
  }

  void setGameOver({required bool playerWon}) {
    _isGameOver = true;
    _playerWon = playerWon;
    notifyListeners();
  }

  void reset() {
    _currentWord = '';
    _isGameOver = false;
    _playerWon = false;
    notifyListeners();
  }
}
