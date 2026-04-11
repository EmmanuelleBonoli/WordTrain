import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:word_riders/features/gameplay/services/player_preferences.dart';
import 'package:word_riders/features/gameplay/services/word_service.dart';
import 'package:word_riders/features/gameplay/services/goal_service.dart';
import 'package:word_riders/data/audio_data.dart';
import 'package:word_riders/features/gameplay/services/audio_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum GameStatus { loading, waitingForConfig, playing, paused, won, lost }

class GameController extends ChangeNotifier with WidgetsBindingObserver {
  final bool isCampaign;
  final String locale;
  final WordService wordService;

  GameStatus _status = GameStatus.loading;
  String _targetWord = "";
  List<String> _shuffledLetters = [];
  String _currentInput = "";
  int? _trainingLength;

  Timer? _gameTimer;
  final Set<String> _sessionWords = {}; // Mots trouvés dans la partie en cours

  // Bonus
  int _bonusExtraLetterCount = 0;
  int _bonusDoubleDistanceCount = 0;
  int _bonusFreezeRivalCount = 0;
  
  bool _extraLetterUsed = false;
  bool _isNextWordDistanceDoubled = false;
  int _remainingFreezeDeciseconds = 0; // en centièmes de seconde (100ms)

  bool _isDisposed = false;

  double _rabbitProgress = 0.0;
  double _foxProgress = 0.0;
  // Vitesse du renard : % du parcours par seconde. 
  double _foxSpeed = 0.01;

  GameStatus get status => _status;
  String get targetWord => _targetWord; 
  int get currentStage => _currentStageId;
  List<String> get shuffledLetters => List.unmodifiable(_shuffledLetters);
  String get currentInput => _currentInput;
  bool get isLoading => _status == GameStatus.loading;
  bool get isPaused => _status == GameStatus.paused;
  
  double get rabbitProgress => _rabbitProgress;
  double get foxProgress => _foxProgress;

  // Accès aux bonus
  int get bonusExtraLetterCount => _bonusExtraLetterCount;
  int get bonusDoubleDistanceCount => _bonusDoubleDistanceCount;
  int get bonusFreezeRivalCount => _bonusFreezeRivalCount;
  bool get extraLetterUsed => _extraLetterUsed;
  bool get isNextWordDistanceDoubled => _isNextWordDistanceDoubled;
  bool get isRivalFrozen => _remainingFreezeDeciseconds > 0;
  int get frozenRivalSeconds => (_remainingFreezeDeciseconds / 10).ceil();

  String? _feedbackMessage;
  String? get feedbackMessage => _feedbackMessage;

  bool _isSuccessFlash = false;
  bool get isSuccessFlash => _isSuccessFlash;

  GameController({
    required this.isCampaign, 
    required this.locale, 
    required this.wordService
  }) {
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
  }

  bool _wasPlayingBeforeBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      // Si on joue activement et que le téléphone se met en veille ou quitte l'app
      if (_status == GameStatus.playing) {
        _wasPlayingBeforeBackground = true;
        _status = GameStatus.paused; // Stop la progression du renard et du timer
        _gameTimer?.cancel();
        notifyListeners();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Quand l'utilisateur revient sur le jeu
      if (_wasPlayingBeforeBackground) {
        _wasPlayingBeforeBackground = false;
        _status = GameStatus.playing;
        notifyListeners();
        _startGameLoop();
      }
    }
  }

  Future<void> _initializeGame() async {
    _status = GameStatus.loading;
    notifyListeners();

    try {
      debugPrint("GameController: Loading dictionary & word for locale: $locale");
      
      // Chargement des bonus si en campagne
      if (isCampaign) {
          _bonusExtraLetterCount = await PlayerPreferences.getBonusExtraLetterCount();
          _bonusDoubleDistanceCount = await PlayerPreferences.getBonusDoubleDistanceCount();
          _bonusFreezeRivalCount = await PlayerPreferences.getBonusFreezeRivalCount();
      }

      // 1. On s'assure que le dictionnaire est chargé pour ce locale (normalement déjà fait par main ou settings)
      await wordService.loadDictionary(locale);

      if (!isCampaign && _trainingLength == null) {
        _status = GameStatus.waitingForConfig;
        notifyListeners();
        return;
      }

      if (isCampaign) {
         // En mode campagne, on récupère un mot du niveau (juste pour avoir les lettres)
         int currentStage = await PlayerPreferences.getCurrentStage();
         _currentStageId = currentStage;
         String? stageWord = await PlayerPreferences.getWordForStage(currentStage, locale);
         
         if (stageWord != null && stageWord.isNotEmpty) {
           _targetWord = stageWord;
           debugPrint("GameController: Restored existing word for stage $currentStage: $_targetWord");
         } else {
           // Génération d'un nouveau mot adapté à la difficulté
           _targetWord = await wordService.getNextCampaignWord(locale, stage: currentStage);
           // IMPORTANT : On sauvegarde ce mot pour ce stage pour qu'il ne change pas si on quitte/revient
           await PlayerPreferences.setWordForStage(currentStage, _targetWord, locale);
           debugPrint("GameController: Generated and saved new word for stage $currentStage: $_targetWord");
         }

         // Ajustement de la difficulté (Vitesse du renard)
         if (currentStage % 5 == 0) {
           // Distance doublée = Temps doublé pour le joueur
           // Donc le jeu doit durer 2x plus longtemps de base -> Vitesse / 2
           _foxSpeed /= 2; 
         }
         if (currentStage % 10 == 0) {
           // Boss Level ! On accélère le renard
           _foxSpeed *= 1.3;
         }
      } else {
        // En mode Entraînement
        int len = _trainingLength ?? 6;
        _targetWord = await wordService.getNextCampaignWord(locale, stage: 1, forceLength: len); 
      }
      
      // Mélange des lettres
      List<String> chars = _targetWord.split('');
      chars.shuffle();
      _shuffledLetters = chars;

      // Reset état de la partie
      _rabbitProgress = 0.0;
      _foxProgress = 0.0;
      _currentInput = "";
      _sessionWords.clear();
      _extraLetterUsed = false;
      _isNextWordDistanceDoubled = false;
      _remainingFreezeDeciseconds = 0;
      _status = GameStatus.playing;
      
      _startGameLoop();

    } catch (e) {
      debugPrint("GameController: ERROR initializing game: $e");
      _targetWord = "ERREUR";
      _shuffledLetters = ["E", "R", "R", "E", "U", "R"];
      _status = GameStatus.playing;
    }

    notifyListeners();
  }

  Future<void> startTraining(int length) async {
    _trainingLength = length;
    await _initializeGame();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    WakelockPlus.enable();
    
    // ENTRAINEMENT : Pas de timer ni de renard
    if (!isCampaign) return;
    
    // Rafraichissement toutes les 100ms
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_status != GameStatus.playing) {
        // En pause on ne fait rien, mais on ne coupe pas le timer pour autant
        return;
      }

      // Gérer le gel du renard
      if (_remainingFreezeDeciseconds > 0) {
        _remainingFreezeDeciseconds--;
        notifyListeners();
        return;
      }

      // Avancée du renard (vitesse par seconde / 10 pour 100ms)
      _foxProgress += _foxSpeed / 10;
      
      if (_foxProgress >= 1.0) {
        _foxProgress = 1.0;
        _handleLoss();
      }
      
      notifyListeners();
    });
  }


  void onLetterTap(String letter) {
    if (_status != GameStatus.playing || _isSuccessFlash) return;

    if (_currentInput.length < 20) { 
      AudioService().playSfx(AudioData.sfxButtonPress);
      _currentInput += letter;
      notifyListeners();
    }
  }

  void onBackspace() {
    if (_status != GameStatus.playing || _isSuccessFlash) return;

    if (_currentInput.isNotEmpty) {
      AudioService().playSfx(AudioData.sfxButtonPress);
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      notifyListeners();
    }
  }

  void onShuffle() {
    if (_status != GameStatus.playing || _isSuccessFlash) return;
    
    _shuffledLetters.shuffle();
    notifyListeners();
  }

  int _currentStageId = 1;

  // Retourne true si le mot est valide et fait avancer le lapin
  bool validate() {
    if (_status != GameStatus.playing) return false;
    
    final word = _currentInput.toUpperCase();

    // 1. Longueur min du mot proposé
    if (word.length < 3) {
      AudioService().playSfx(AudioData.sfxWordInvalid);
      showFeedback(tr('game.feedback_too_short'));
      clearInput();
      return false;
    }

    // 2. Mot déjà trouvé ?
    if (_sessionWords.contains(word)) {
      AudioService().playSfx(AudioData.sfxWordInvalid);
      showFeedback(tr('game.feedback_already_used'));
      clearInput();
      return false;
    }

    // 3. Mot existe dans le dico ?
    if (wordService.isValid(word)) {
      AudioService().playSfx(AudioData.sfxWordValid);
      _sessionWords.add(word);
      GoalService().incrementWordsFound(1, wordLength: word.length);
      
      // Faire avancer le lapin
      // Formule de progression : plus le mot est long, plus on avance ?
      double advance = 0.15; // Un mot = 15% de la course
      if (word.length >= _targetWord.length) advance = 0.25;

      // DIFFICULTÉ : Si stage fini par 5 ou 0, la distance est doublée
      // Doubler la distance revient à diviser la progression par 2
      if (isCampaign) {
         if (_currentStageId % 5 == 0) {
           advance /= 2.0;
         }
      } else {
         // Entrainement : distance plus longue (progression plus lente) si 7 ou 8 lettres
         if ((_trainingLength ?? 6) >= 7) {
             advance /= 2.0;
         }
      }

      // BONUS DOUBLE DISTANCE
      if (_isNextWordDistanceDoubled) {
        advance *= 2.0;
        _isNextWordDistanceDoubled = false; // Consommé
      }

      _rabbitProgress += advance;

      if (_rabbitProgress >= 1.0) {
        _rabbitProgress = 1.0;
        _handleWin();
      }
      
      _isSuccessFlash = true;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed) {
          _isSuccessFlash = false;
          clearInput();
        }
      });
      
      return true;
    }
    
    // Mot invalide/inconnu
    AudioService().playSfx(AudioData.sfxWordInvalid);
    showFeedback(tr('game.feedback_invalid'));
    clearInput();
    return false;
  }

  // --- ACTIONS DES BONUS ---
  Future<void> useBonusExtraLetter() async {
    if (_status != GameStatus.playing || !isCampaign) return;
    if (_extraLetterUsed || _bonusExtraLetterCount <= 0) return;
    
    await PlayerPreferences.useBonusExtraLetter();
    _bonusExtraLetterCount--;
    _extraLetterUsed = true;
    GoalService().incrementBonusesUsed(1);
    
    // Ajout d'une voyelle aléatoire
    final vowels = ['A', 'E', 'I', 'O', 'U', 'Y'];
    vowels.shuffle();
    _shuffledLetters.add(vowels.first);
    
    notifyListeners();
  }

  Future<void> useBonusDoubleDistance() async {
    if (_status != GameStatus.playing || !isCampaign) return;
    if (_isNextWordDistanceDoubled || _bonusDoubleDistanceCount <= 0) return;
    
    await PlayerPreferences.useBonusDoubleDistance();
    _bonusDoubleDistanceCount--;
    _isNextWordDistanceDoubled = true;
    GoalService().incrementBonusesUsed(1);
    
    notifyListeners();
  }

  Future<void> useBonusFreezeRival() async {
    if (_status != GameStatus.playing || !isCampaign) return;
    if (_bonusFreezeRivalCount <= 0) return;
    
    await PlayerPreferences.useBonusFreezeRival();
    _bonusFreezeRivalCount--;
    _remainingFreezeDeciseconds += 80;  // 8 secondes
    GoalService().incrementBonusesUsed(1);
    
    notifyListeners();
  }

  void clearInput() {
    _currentInput = "";
    notifyListeners();
  }

  Future<void> _handleWin() async {
    AudioService().playSfx(AudioData.sfxWin);
    _status = GameStatus.won;
    _gameTimer?.cancel();
    WakelockPlus.disable();

    if (isCampaign) {
      await GoalService().incrementLevelsWon(1);
      await PlayerPreferences.addUsedWord(_targetWord); 
      
      int currentStage = await PlayerPreferences.getCurrentStage();
      await PlayerPreferences.setCurrentStage(currentStage + 1);
    }
    notifyListeners();
  }

  // Permet de quitter proprement en comptabilisant la défaite si nécessaire
  Future<void> quitGame() async {
    _gameTimer?.cancel();
    WakelockPlus.disable();
    // Si on quitte une partie en cours en mode campagne, c'est une défaite (donc perte de vie)
    if (isCampaign && (_status == GameStatus.playing || _status == GameStatus.paused)) {
      await PlayerPreferences.loseLife();
    }
    _status = GameStatus.lost; // On marque comme fini pour éviter des effets de bord
    notifyListeners();
  }

  // Consomme une vie pour un restart manuel (équivalent à un abandon)
  Future<bool> consumeLifeForRestart() async {
    return await PlayerPreferences.loseLife();
  }

  void restartGame() {
    _status = GameStatus.loading;
    notifyListeners();
    _initializeGame();
  }

  void pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _gameTimer?.cancel();
      WakelockPlus.disable();
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      WakelockPlus.enable();
      notifyListeners();
      _startGameLoop();
    }
  }

  Timer? _feedbackTimer;

  void showFeedback(String message) {
    _feedbackTimer?.cancel();
    _feedbackMessage = message;
    notifyListeners();

    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      _feedbackMessage = null;
      notifyListeners();
    });
  }

  Future<void> _handleLoss() async {
    AudioService().playSfx(AudioData.sfxLose);
    _status = GameStatus.lost;
    _gameTimer?.cancel();
    WakelockPlus.disable();
    
    notifyListeners();
  }

  Future<void> concedeGame() async {
     if (isCampaign) {
       await PlayerPreferences.loseLife();
     }
  }

  // Permet de continuer la partie (revive) après une défaite
  // Le renard recule de 40%
  Future<void> revive() async {
    if (_status != GameStatus.lost) return;

    _foxProgress = (_foxProgress - 0.4).clamp(0.0, 1.0);
    
    _status = GameStatus.playing;
    notifyListeners();
    _startGameLoop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _gameTimer?.cancel();
    _feedbackTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }
}
