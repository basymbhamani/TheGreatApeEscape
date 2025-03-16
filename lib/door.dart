import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'monkey.dart'; // Import Monkey for type checking
import 'package:flame/flame.dart'; // Import Flame to load images

class Door extends SpriteComponent with CollisionCallbacks {
  final Function() onPlayerEnter; // Callback for when the player enters the door

  Door(Vector2 position, {required this.onPlayerEnter})
      : super(
          position: position,
          size: Vector2(220, 260), // Door size WH
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the image and create a sprite for the door
    final doorImage = await Flame.images.load('jungle_door.png'); // Load the image asset

    // Check if image is loaded successfully
    if (doorImage != null) {
      sprite = Sprite(doorImage); // Set the sprite for the door
    } else {
      print('Failed to load door image!');
    }

    // Add a hitbox for collision detection (smaller than the door)
    final hitboxSize = Vector2(180, 200); // Adjusted hitbox size (width: 80, height: 200)
    final hitboxOffset = Vector2(
      (size.x - hitboxSize.x) / 2, // Center horizontally
      size.y - hitboxSize.y, // Align hitbox to the bottom of the door
    );

    add(
      RectangleHitbox(
        size: hitboxSize,
        position: hitboxOffset, // Position the hitbox
      )..collisionType = CollisionType.passive,
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Check if the player collides with the door
    if (other is Monkey) {
      print("Door detected collision with monkey!"); // Debug
      onPlayerEnter(); // Trigger the callback
    }
  }
}