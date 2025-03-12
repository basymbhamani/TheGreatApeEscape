import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'monkey.dart';
import 'platform.dart';

class ApeEscapeGame extends FlameGame with HasCollisionDetection {
  late final JoystickComponent joystick;
  late final Monkey player;

  @override
  Future<void> onLoad() async {
    debugMode = false;

    // Background
    add(RectangleComponent(
      position: Vector2.zero(),
      size: size,
      paint: Paint()..color = const Color(0xFF87CEEB), // Light blue for sky
    ));

    // Joystick in bottom-left
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: Paint()..color = const Color(0xFFAAAAAA)),
      background: CircleComponent(radius: 50, paint: Paint()..color = const Color(0xFF444444)),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );

    // Player
    player = Monkey(joystick);
    add(player);
    add(joystick);

    // Jump button in bottom-right
    add(HudButtonComponent(
      button: CircleComponent(radius: 40, paint: Paint()..color = const Color(0xFF00FF00)),
      position: Vector2(size.x - 100, size.y - 80),
      onPressed: player.jump,
    ));

    // Ground platform spanning screen width
    add(Platform(Vector2(0, size.y - 40), Vector2(size.x, 40)));
  }
}
