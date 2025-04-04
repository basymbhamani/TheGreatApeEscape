import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game.dart';

class Platform extends PositionComponent with CollisionCallbacks {
  static const double platformSize = 56.0; // Size of one platform block (4x original 14px size)
  static double worldHeight = 0; // Static world height
  final double worldWidth;
  final int numBlocks;
  final int heightInBlocks;
  final Vector2 startPosition;

  Platform({
    required this.worldWidth,
    required double height,
    required this.numBlocks,
    required this.startPosition,
    this.heightInBlocks = 1,
  }) {
    worldHeight = height;
    size = Vector2(platformSize * numBlocks, platformSize * heightInBlocks);
    position = startPosition;
  }

  @override
  Future<void> onLoad() async {
    // Load both grass and dirt sprites
    final grassSprite = await Sprite.load('Platforms/grass_platform.png');
    final dirtSprite = await Sprite.load('Platforms/dirt.png');

    // Create platform blocks for each row and column
    for (int row = 0; row < heightInBlocks; row++) {
      for (int col = 0; col < numBlocks; col++) {
        final sprite = row == 0 ? grassSprite : dirtSprite;
        final block = SpriteComponent(
          sprite: sprite,
          position: Vector2(col * platformSize, row * platformSize),
          size: Vector2(platformSize, platformSize),
        );
        add(block);
      }
    }

    // Add collision hitbox that matches the platform's total height
    add(RectangleHitbox(
      size: Vector2(platformSize * numBlocks, platformSize * 0.1), // Make hitbox height 10% of platform height
      position: Vector2(0, 0), // Position at the very top of the platform
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);

    debugMode = false; // Set to `true` to visualize collision hitboxes
  }
}
