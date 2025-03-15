import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF87CEEB),
          body: GameWidget(
            game: ApeEscapeGame(),
            backgroundBuilder:
                (context) => Container(color: const Color(0xFF87CEEB)),
          ),
        ),
      ),
    );
  });
}
