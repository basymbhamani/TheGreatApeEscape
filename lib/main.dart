import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:nakama/nakama.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'host_join_screen.dart';
import 'game.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations first (await ensures it completes)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide Status Bar and Navigation Bar for immersive game experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Nakama client
  await dotenv.load(fileName: "assets/.env");
  final nakamaClient = getNakamaClient(
    host: dotenv.env['NAKAMA_HOST']!,
    ssl: dotenv.env['NAKAMA_SSL']!.toLowerCase() == 'true',
    serverKey: dotenv.env['NAKAMA_SERVER_KEY']!,
    grpcPort: int.parse(dotenv.env['NAKAMA_GRPC_PORT']!),
    httpPort: int.parse(dotenv.env['NAKAMA_HTTP_PORT']!),
  );

  // Authenticate with a device ID (unique per device)
  final session = await nakamaClient.authenticateDevice(
    deviceId: 'unique-device-id${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
  );

  // Run the app
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HostJoinScreen(nakamaClient: nakamaClient, session: session), // Start with the HostJoinScreen
    ),
  );
}