import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game.dart';
import '../../models/monkey.dart';

class TreeBlock extends PositionComponent with CollisionCallbacks {
  static const double blockSize = 56.0; // Base block size
  static const double treeSizeFactor = 6.0; // Scale factor for the tree

  TreeBlock({
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2.all(blockSize * treeSizeFactor);
  }

  @override
  Future<void> onLoad() async {
    final treeSprite = await Sprite.load('Tree/tree_block.png');
    final spriteComponent = SpriteComponent(
      sprite: treeSprite,
      size: Vector2.all(blockSize * treeSizeFactor),
      position: Vector2(0, -blockSize), // Move sprite up by one block
    );
    add(spriteComponent);

    // Add thin platform hitbox at the top
    add(RectangleHitbox(
      size: Vector2(blockSize * treeSizeFactor * 0.7, blockSize * 0.1), // Thin horizontal hitbox
      position: Vector2(
        blockSize * treeSizeFactor * 0.15, // Centered horizontally
        -blockSize * 0.5, // Move hitbox half a block lower (from -blockSize to -blockSize * 0.5)
      ),
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey) {
      other.isGrounded = true;
      other.velocity.y = 0;
      other.animation = (other.joystick?.delta.x.abs() ?? 0) > 0 ? other.runAnimation : other.idleAnimation;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey) {
      other.isGrounded = false;
    }
    super.onCollisionEnd(other);
  }
} 