import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'host_join_screen.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HostJoinScreen(), // Start with the HostJoinScreen
      ),
    );
  });
}
