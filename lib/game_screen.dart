import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Map<String, dynamic>? _storyData;
  String _currentNodeKey = 'start';
  bool _isLoading = true;
  static const String _saveKey = 'saved_node_key';

  // Audio players
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  String _currentBgmPath = '';

  @override
  void initState() {
    super.initState();
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // 1. Load story data from Firestore
    final storySnapshot = await FirebaseFirestore.instance
        .collection('story')
        .get();

    // Convert the snapshot into the Map format the game uses
    final storyMap = <String, dynamic>{};
    for (var doc in storySnapshot.docs) {
      storyMap[doc.id] = doc.data();
    }
    _storyData = storyMap;

    // 2. Check arguments to see if we should load a saved game
    // This needs a 'mounted' check since it's in an async method.
    if (mounted) {
      final shouldLoadGame =
          ModalRoute.of(context)!.settings.arguments as bool? ?? false;

      if (shouldLoadGame) {
        // 3a. Load the saved game state, which will set the node key
        await _loadGame();
      } else {
        // 3b. This is a new game, so just update BGM for the 'start' node
        _updateBgm();
      }
    }

    // 4. Update the UI to show the game screen
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _makeChoice(Map<String, dynamic> choice) {
    final nextNodeKey = choice['next'] as String;
    final sfx = choice['sfx'] as String?;

    if (sfx != null) {
      _playSfx(sfx);
    }

    if (_storyData!.containsKey(nextNodeKey)) {
      setState(() {
        _currentNodeKey = nextNodeKey;
      });
      _updateBgm();
    }
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, _currentNodeKey);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Game Saved!')));
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_saveKey)) {
      final savedNodeKey = prefs.getString(_saveKey) ?? 'start';
      if (!mounted) return;

      setState(() {
        _currentNodeKey = savedNodeKey;
      });
      _updateBgm(); // Update BGM after loading the new state

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Game Loaded!')));
    }
  }

  void _goToMainMenu() async {
    // Instead of restarting, we go back to the main menu.
    Navigator.of(context).pop();
  }

  void _playSfx(String sfxFile) {
    _sfxPlayer.play(AssetSource('audio/$sfxFile'));
  }

  void _updateBgm() {
    if (_storyData == null) return; // Don't do anything if story isn't loaded
    final currentNode = _storyData![_currentNodeKey]!;
    final newBgmPath = currentNode['bgm'] as String?;

    // Only change BGM if a new, different path is provided.
    if (newBgmPath != null && newBgmPath != _currentBgmPath) {
      _currentBgmPath = newBgmPath;
      if (_currentBgmPath.isEmpty) {
        _bgmPlayer.stop();
      } else {
        _bgmPlayer.play(AssetSource('audio/$_currentBgmPath'));
      }
    }
  }

  List<Widget> _buildCharacterSprites(List<dynamic> characters) {
    return characters.map((charData) {
      final sprite = charData['sprite'] as String;
      final position = charData['position'] as String;

      Alignment alignment;
      switch (position) {
        case 'left':
          alignment = Alignment.bottomLeft;
          break;
        case 'right':
          alignment = Alignment.bottomRight;
          break;
        default:
          alignment = Alignment.bottomCenter;
      }

      return Align(
        alignment: alignment,
        child: Image.asset(
          'assets/images/$sprite',
          height: MediaQuery.of(context).size.height * 0.7,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visual Novel')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Data is loaded, build the UI
    final currentNode = _storyData![_currentNodeKey]!;
    final text = currentNode['text'] as String;
    final choices = currentNode['choices'] as List<dynamic>;
    final characters = currentNode['characters'] as List<dynamic>? ?? [];
    final backgroundPath = currentNode['background'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Novel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGame,
            tooltip: 'Save Game',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goToMainMenu,
            tooltip: 'Main Menu',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          if (backgroundPath != null)
            Positioned.fill(
              child: Image.asset(
                'assets/images/$backgroundPath',
                fit: BoxFit.cover,
              ),
            ),
          // Character Sprites
          ..._buildCharacterSprites(characters),
          // UI Layer (Text Box and Choices)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.white.withOpacity(0.8)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final choice = choices[index] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(choice['text']! as String),
                          onTap: () => _makeChoice(choice),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
