import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'monkey.dart';
import 'platform.dart';
import 'dart:math';

class ApeEscapeGame extends FlameGame with HasCollisionDetection {
  late final JoystickComponent joystick;
  late final Monkey player;
  late final double gameWidth;
  late final double gameHeight;
  late final PositionComponent gameLayer;

  // World boundaries
  static const worldWidth = 3000.0; // Make world 3x wider than screen

  // Camera window settings
  static const double cameraWindowMarginRatio =
      0.3; // How close to the edge before camera follows

  @override
  Future<void> onLoad() async {
    // Get actual screen dimensions
    gameWidth = size.x;
    gameHeight = size.y;

    // Set up camera and viewport
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;

    // Create game layer
    gameLayer = PositionComponent();
    add(gameLayer);

    // Sky background
    final background = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(worldWidth, gameHeight),
      paint: Paint()..color = const Color(0xFF87CEEB),
    );
    gameLayer.add(background);

    // Add evenly spaced clouds
    final numberOfClouds = 10;
    final cloudSpacing = worldWidth / (numberOfClouds + 1);
    final cloudWidth = gameWidth * 0.3;
    final cloudHeight = gameHeight * 0.06;

    for (int i = 0; i < numberOfClouds; i++) {
      final cloudX = cloudSpacing * (i + 1);
      final cloudY =
          gameHeight * (0.1 + (i % 3) * 0.1); // Alternate between 3 heights

      gameLayer.add(
        RectangleComponent(
          position: Vector2(cloudX, cloudY),
          size: Vector2(cloudWidth, cloudHeight),
          paint: Paint()..color = Colors.white.withOpacity(0.8),
        ),
      );
    }

    // Add evenly spaced trees
    final numberOfTrees = 15;
    final treeSpacing = worldWidth / (numberOfTrees + 1);
    final treeWidth = gameWidth * 0.1;
    final baseTreeHeight = gameHeight * 0.3;

    for (int i = 0; i < numberOfTrees; i++) {
      final treeX = treeSpacing * (i + 1);
      final treeHeight =
          baseTreeHeight +
          (i % 2 == 0
              ? baseTreeHeight * 0.1
              : 0); // Alternate between two heights
      final treeY = gameHeight * 0.85 - treeHeight;

      // Tree trunk
      gameLayer.add(
        RectangleComponent(
          position: Vector2(treeX + treeWidth * 0.4, treeY + treeHeight * 0.6),
          size: Vector2(treeWidth * 0.2, treeHeight * 0.4),
          paint: Paint()..color = const Color(0xFF8B4513),
        ),
      );

      // Tree top
      gameLayer.add(
        RectangleComponent(
          position: Vector2(treeX, treeY),
          size: Vector2(treeWidth, treeHeight * 0.7),
          paint: Paint()..color = const Color(0xFF228B22),
        ),
      );
    }

    // Ground platform
    final platform = Platform(
      Vector2(0, gameHeight * 0.85),
      Vector2(worldWidth, gameHeight * 0.15),
    );
    gameLayer.add(platform);

    // Initialize joystick
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: gameHeight * 0.06,
        paint: Paint()..color = const Color(0xFFAAAAAA).withOpacity(0.8),
      ),
      background: CircleComponent(
        radius: gameHeight * 0.12,
        paint: Paint()..color = const Color(0xFF444444).withOpacity(0.5),
      ),
      position: Vector2(gameWidth * 0.1, gameHeight * 0.7),
      priority: 2,
    );
    add(joystick);

    // Create player
    player =
        Monkey(joystick, worldWidth, gameHeight)
          ..position = Vector2(gameWidth * 0.3, gameHeight * 0.7)
          ..priority = 2;
    gameLayer.add(player);

    // Jump button
    final jumpButton = HudButtonComponent(
      button: CircleComponent(
        radius: gameHeight * 0.12,
        paint: Paint()..color = const Color(0xFF00FF00).withOpacity(0.5),
      ),
      position: Vector2(gameWidth * 0.85, gameHeight * 0.59),
      priority: 2,
      onPressed: player.jump,
    );
    add(jumpButton);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Calculate the camera window boundaries
    final windowLeft =
        -gameLayer.position.x + gameWidth * cameraWindowMarginRatio;
    final windowRight =
        -gameLayer.position.x + gameWidth * (1 - cameraWindowMarginRatio);

    // Check if player is outside the camera window
    if (player.position.x < windowLeft) {
      // Player is too far left, move game layer right
      gameLayer.position.x =
          -(player.position.x - gameWidth * cameraWindowMarginRatio);
    } else if (player.position.x > windowRight) {
      // Player is too far right, move game layer left
      gameLayer.position.x =
          -(player.position.x - gameWidth * (1 - cameraWindowMarginRatio));
    }

    // Clamp game layer position to world boundaries
    gameLayer.position.x = gameLayer.position.x.clamp(
      -(worldWidth - gameWidth),
      0,
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);
}
