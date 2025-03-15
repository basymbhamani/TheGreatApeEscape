import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:nakama/nakama.dart';
import 'game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Nakama client
  final nakamaClient = getNakamaClient(
    host: '127.0.0.1', // Localhost for development
    ssl: false,
    serverKey: 'defaultkey',
    grpcPort: 7349,
    httpPort: 7350,
  );

  // Authenticate with a device ID (unique per device)
  final session = await nakamaClient.authenticateDevice(
    deviceId: 'test-device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
  );

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
            game: ApeEscapeGame(nakamaClient, session),
            backgroundBuilder:
                (context) => Container(color: const Color(0xFF87CEEB)),
          ),
        ),
      ),
    );
  });
}