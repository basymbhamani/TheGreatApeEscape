import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'platform.dart';
import 'monkey.dart';
import 'game.dart';

class GameBlock extends PositionComponent with CollisionCallbacks {
  static const double blockSize = 56.0; // Same size as platform blocks
  final Vector2 startPosition;
  static const int numBlocks = 5; // Number of blocks in the sequence

  GameBlock({
    required this.startPosition,
  }) {
    position = startPosition;
    size = Vector2(blockSize * numBlocks, blockSize); // Width spans all blocks
  }

  @override
  Future<void> onLoad() async {
    final blockSprite = await Sprite.load('Block/block.png');
    
    // Add block sprites for each block
    for (int i = 0; i < numBlocks; i++) {
      final block = SpriteComponent(
        sprite: blockSprite,
        position: Vector2(blockSize * i, 0),
        size: Vector2(blockSize, blockSize),
      );
      add(block);
    }

    // Add single continuous collision hitbox that spans all blocks
    add(RectangleHitbox(
      size: Vector2(blockSize * numBlocks, blockSize * 0.1), // Thin layer at top
      position: Vector2.zero(), // Start from top-left corner
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey && !other.isDead) {
      other.isGrounded = true;
      other.velocity.y = 0;
      other.animation = (other.joystick?.delta.x.abs() ?? 0) > 0 ? other.runAnimation : other.idleAnimation;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey && !other.isDead) {
      other.isGrounded = false;
    }
    super.onCollisionEnd(other);
  }
} 