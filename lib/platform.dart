import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class Platform extends PositionComponent with CollisionCallbacks {
  Platform(Vector2 position, Vector2 size) {
    this.position = position;
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF8B4513), // Added brown color
      ),
    );
    debugMode = false; // Set to `true` to visualize collision hitboxes
  }
}
