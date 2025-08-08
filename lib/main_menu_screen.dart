import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _canContinue = false;
  static const String _saveKey = 'saved_node_key';

  @override
  void initState() {
    super.initState();
    _checkIfCanContinue();
  }

  Future<void> _checkIfCanContinue() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _canContinue = prefs.containsKey(_saveKey);
    });
  }

  Future<void> _startNewGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey); // Clear previous save
    if (!mounted) return; // Check mounted status before async gap
    // Wait for the game screen to be popped before continuing.
    await Navigator.pushNamed(context, '/game', arguments: false);
    // This code runs after the user returns from the game screen.
    _checkIfCanContinue();
  }

  Future<void> _continueGame() async {
    if (!mounted) return; // Check mounted status before async gap
    // Wait for the game screen to be popped before continuing.
    await Navigator.pushNamed(context, '/game', arguments: true);
    // This code runs after the user returns from the game screen.
    _checkIfCanContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            // Using an existing image for the menu background
            image: AssetImage('assets/images/background/crossroads.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Gemini Story',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(5.0, 5.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startNewGame,
                child: const Text('New Game'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _canContinue ? _continueGame : null,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Quit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
