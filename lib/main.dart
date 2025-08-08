import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';

void main() {
  runApp(const VisualNovelApp());
}

class VisualNovelApp extends StatelessWidget {
  const VisualNovelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Visual Novel',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}
