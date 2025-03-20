import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'game.dart';
import 'monkey.dart';

class Coin extends SpriteComponent with CollisionCallbacks {
  static const double coinSize = 28.0; // Half the size of a platform block
  bool isCollected = false;
  final VoidCallback onCollected;

  Coin({
    required Vector2 position,
    required this.onCollected,
  }) {
    this.position = position;
    size = Vector2.all(coinSize);
  }

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('Coin/coin_1.png');
    this.sprite = sprite;

    // Add circular hitbox for better coin collection
    add(CircleHitbox(
      radius: coinSize / 2,
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  void collect() {
    if (!isCollected) {
      isCollected = true;
      removeFromParent();
      onCollected();
    }
  }
} 