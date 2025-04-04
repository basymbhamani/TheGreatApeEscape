import 'package:flutter/material.dart';
import '../game.dart';

class SettingsMenu extends StatefulWidget {
  final ApeEscapeGame game;

  const SettingsMenu({super.key, required this.game});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  late int _soundVolume;
  late bool _invertControls;

  @override
  void initState() {
    super.initState();
    // Initialize with current game values
    _soundVolume = (widget.game.soundVolume * 10).round();
    _invertControls = widget.game.invertControls;
  }

  void _adjustVolume(int change) {
    setState(() {
      _soundVolume = (_soundVolume + change).clamp(0, 10);
      // Convert back to 0-1 range for the game
      widget.game.setSoundVolume(_soundVolume / 10);
    });
  }

  void _toggleInvertControls() {
    setState(() {
      _invertControls = !_invertControls;
      widget.game.setInvertControls(_invertControls);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.black.withOpacity(0.54),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/settings.png',
                width: 490 * 0.7,
                height: 72 * 0.7,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 0),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 70,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Volume',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus button
                        GestureDetector(
                          onTap: () => _adjustVolume(-1),
                          child: Transform.rotate(
                            angle: 0,
                            child: Image.asset(
                              'assets/images/minus_button.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Volume number
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _soundVolume.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Plus button
                        GestureDetector(
                          onTap: () => _adjustVolume(1),
                          child: Image.asset(
                            'assets/images/plus_button.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Invert Controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _toggleInvertControls,
                      child: Image.asset(
                        _invertControls
                            ? 'assets/images/enabled.png'
                            : 'assets/images/sound_button.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/images/back.png',
                  width: 490 * 0.7,
                  height: 72 * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
