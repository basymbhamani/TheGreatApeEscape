import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import '../../game.dart';
import '../../models/monkey.dart';

class Coin extends SpriteComponent with CollisionCallbacks {
  static const double coinSize = 28.0; // Half the size of a platform block
  bool _isCollected = false;
  final Function() onCollected;

  Coin({
    required Vector2 position,
    required this.onCollected,
  }) : super(
          position: position,
          size: Vector2(28, 28), // Reduced from 56x56 to 28x28
        );

  @override
  Future<void> onLoad() async {
    final coinSprite = await Sprite.load('Coin/coin_1.png');
    sprite = coinSprite;

    // Add collision hitbox
    add(RectangleHitbox(
      size: Vector2(20, 20), // Reduced from 40x40 to 20x20
      position: Vector2(4, 4), // Adjusted from 8,8 to 4,4 to center the smaller hitbox
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey && !_isCollected) {
      _isCollected = true;
      onCollected();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
} 