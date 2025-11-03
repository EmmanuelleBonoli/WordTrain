import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:word_train/utils/dictionary.dart';

import 'features/ui/screens/game_screen.dart';

void main() async {
  /// nécessaire pour charger les assets
  WidgetsFlutterBinding.ensureInitialized();

  /// charger le dictionnaire
  final dictionary = Dictionary();
  await dictionary.load();

  /// forcer le mode paysage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  /// lancer le jeu
  runApp(WordTrainApp(dictionary: dictionary));
}

class WordTrainApp extends StatelessWidget {
  final Dictionary dictionary;

  const WordTrainApp({super.key, required this.dictionary});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Train',
      theme: ThemeData.dark(),
      home: GameScreen(dictionary: dictionary),
    );
  }
}
