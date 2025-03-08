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
    // Add white background first
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: size,
        paint: Paint()..color = const Color(0xFFFFFFFF),
      ),
    );

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: Paint()..color = const Color(0xFFAAAAAA)),
      background: CircleComponent(radius: 50, paint: Paint()..color = const Color(0xFF444444)),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
    );

    player = Monkey(joystick);
    add(player);
    add(joystick);

    // Add jump button
    add(
      HudButtonComponent(
        button: RectangleComponent(
          size: Vector2(80, 80),
          paint: Paint()..color = const Color(0xFF00FF00),
        ),
        position: Vector2(size.x - 90, size.y - 90),
        onPressed: player.jump,
      ),
    );

    // Add ground platform
    add(Platform(Vector2(0, size.y - 40), Vector2(size.x, 40)));
  }
}