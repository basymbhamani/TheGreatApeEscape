import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'monkey.dart';
import 'spikes.dart';

class Tree extends PositionComponent with CollisionCallbacks {
  static const double blockSize = 56.0; // Base block size

  Tree({
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2(blockSize * 9, blockSize * 4); // 9 blocks wide, 4 blocks tall
  }

  @override
  Future<void> onLoad() async {
    // Load all tree sprites
    final trunkSprite = await Sprite.load('Tree/trunk_1.png');
    final treeCenterSprite = await Sprite.load('Tree/tree_center.png');
    final treeBottomSprite = await Sprite.load('Tree/tree_bottom.png');
    final treeBottomLeftSprite = await Sprite.load('Tree/tree_bottom_left.png');
    final treeBottomRightSprite = await Sprite.load('Tree/tree_bottom_right.png');
    final treeLeftSprite = await Sprite.load('Tree/tree_left.png');
    final treeRightSprite = await Sprite.load('Tree/tree_right.png');
    final treeTopRightSprite = await Sprite.load('Tree/tree_top_right.png');
    final treeTopLeftSprite = await Sprite.load('Tree/tree_top_left.png');
    final treeTopSprite = await Sprite.load('Tree/tree_top.png');

    // Add top row of tree pieces
    // Left edge
    add(SpriteComponent(
      sprite: treeTopLeftSprite,
      position: Vector2(blockSize * 2, -blockSize * 3.25),
      size: Vector2.all(blockSize),
    ));

    // Middle pieces
    for (int i = 0; i < 7; i++) {
      add(SpriteComponent(
        sprite: treeTopSprite,
        position: Vector2(blockSize * (i + 3), -blockSize * 3.25),
        size: Vector2.all(blockSize),
      ));
    }

    // Right edge
    add(SpriteComponent(
      sprite: treeTopRightSprite,
      position: Vector2(blockSize * 10, -blockSize * 3.25),
      size: Vector2.all(blockSize),
    ));

    // Add left block under top row
    add(SpriteComponent(
      sprite: treeLeftSprite,
      position: Vector2(blockSize * 2, -blockSize * 2.25),  // One block below top row
      size: Vector2.all(blockSize),
    ));

    // Add tree top right next to highest left wall block
    add(SpriteComponent(
      sprite: treeTopRightSprite,
      position: Vector2(blockSize * 3, 0),  // Moved down one block
      size: Vector2.all(blockSize),
    ));

    // Add top left block
    add(SpriteComponent(
      sprite: treeTopLeftSprite,
      position: Vector2(blockSize * 2, 0),  // Moved down one block
      size: Vector2.all(blockSize),
    ));

    // Add platform hitbox for the two highest blocks
    add(RectangleHitbox(
      size: Vector2(blockSize * 2 * 0.8, blockSize * 0.1),  // Width of two blocks, thin height
      position: Vector2(
        blockSize * 2.2,  // Slightly inset from left edge
        3 - blockSize * 0.05,  // Half a block higher, plus 3 pixels down
      ),
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);

    // Add left wall (2 blocks tall, since top block is separate)
    for (int i = 0; i < 2; i++) {
      add(SpriteComponent(
        sprite: treeLeftSprite,
        position: Vector2(blockSize * 2, blockSize * (i + 1)),  // Start one block lower
        size: Vector2.all(blockSize),
      ));
    }

    // Add right wall (4 blocks tall)
    for (int i = 0; i < 4; i++) {
      add(SpriteComponent(
        sprite: treeRightSprite,
        position: Vector2(blockSize * 10, blockSize * (i - 1)),  // Moved down one block
        size: Vector2.all(blockSize),
      ));
    }

    // Add single trunk piece
    add(SpriteComponent(
      sprite: trunkSprite,
      position: Vector2(blockSize * 6, blockSize * 3),  // Single trunk piece
      size: Vector2.all(blockSize),
    ));

    // Add tree center piece above trunk
    add(SpriteComponent(
      sprite: treeCenterSprite,
      position: Vector2(blockSize * 6, blockSize * 2),  // Moved down one block
      size: Vector2.all(blockSize),
    ));

    // Add middle tree bottom piece
    add(SpriteComponent(
      sprite: treeBottomSprite,
      position: Vector2(blockSize * 7, blockSize * 0.5),  // Half a block lower
      size: Vector2.all(blockSize),
      angle: 3.14159,  // 180 degrees in radians
    ));

    // Add hitbox for the upside-down block
    add(RectangleHitbox(
      size: Vector2(blockSize * 0.8, blockSize * 0.1),  // Thin platform hitbox
      position: Vector2(
        blockSize * 6.1,  // One block left
        -blockSize * 0.55 + 4,  // Adjusted for new block position
      ),
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);

    // Add hitbox for top right wall block
    add(RectangleHitbox(
      size: Vector2(blockSize * 0.8, blockSize * 0.1),  // Thin platform hitbox
      position: Vector2(
        blockSize * 10.1,  // Slightly inset from right edge
        -blockSize * 0.95,  // Near the top of the highest right block
      ),
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);

    // Add bottom row of tree pieces
    // Left edge
    add(SpriteComponent(
      sprite: treeBottomLeftSprite,
      position: Vector2(blockSize * 2, blockSize * 2),  // Moved down one block
      size: Vector2.all(blockSize),
    ));

    // Middle pieces
    for (int i = 0; i < 7; i++) {
      add(SpriteComponent(
        sprite: treeBottomSprite,
        position: Vector2(blockSize * (i + 3), blockSize * 2),  // Moved down one block
        size: Vector2.all(blockSize),
      ));
    }

    // Right edge
    add(SpriteComponent(
      sprite: treeBottomRightSprite,
      position: Vector2(blockSize * 10, blockSize * 2),  // Moved down one block
      size: Vector2.all(blockSize),
    ));

    // Add spikes at the bottom (moved to end so they render on top)
    final baseX = blockSize * 3 + 10;  // Starting X position, moved 10 pixels right
    final spacing = blockSize * 2 - 20;  // Spacing between spikes (two full blocks)
    for (int i = 0; i < 4; i++) {
      add(Spikes(
        startPosition: Vector2(baseX + (spacing * i), blockSize),  // One block higher
      ));
    }
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