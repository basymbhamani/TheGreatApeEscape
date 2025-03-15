import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'monkey.dart';
import 'platform.dart';

class ApeEscapeGame extends FlameGame with HasCollisionDetection {
  late final JoystickComponent joystick;
  late final Monkey player;
  static const gameWidth = 2856.0;
  static const gameHeight = 1280.0;

  @override
  Future<void> onLoad() async {
    debugMode = false;

    // Configure world bounds with adaptive viewport
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 0.7;

    // Background
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(gameWidth, gameHeight),
        paint: Paint()..color = const Color(0xFF87CEEB),
      ),
    );

    // Ground platform spanning screen width
    add(Platform(Vector2(0, 400), Vector2(gameWidth, 100)));

    // Initialize joystick first - using screen percentage for positioning
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 25,
        paint: Paint()..color = const Color(0xFFAAAAAA),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF444444),
      ),
      margin: const EdgeInsets.only(left: 100, top: 200),
      priority: 1,
    );
    add(joystick);

    // Then create player after joystick is initialized
    player = Monkey(joystick)..position = Vector2(400, 200);
    add(player);

    // Jump button - positioned near monkey
    add(
      HudButtonComponent(
        button: CircleComponent(
          radius: 40,
          paint: Paint()..color = const Color(0xFF00FF00),
        ),
        position: Vector2(600, 200),
        priority: 1,
        onPressed: player.jump,
      ),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);
}
