import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Climbable extends PositionComponent with CollisionCallbacks {
  Climbable(Vector2 position, Vector2 size) {
    this.position = position;
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleComponent(
      position: Vector2.zero(),
      size: size,
      paint: Paint()..color = Colors.green,
    ));
    add(RectangleHitbox()
      ..collisionType = CollisionType.passive
      ..size = size
      ..position = Vector2.zero());
    debugMode = true; // Set to `true` to visualize collision hitboxes
  }
}