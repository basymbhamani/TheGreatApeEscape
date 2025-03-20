import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'platform.dart';
import 'monkey.dart';

class Mushroom extends Platform {
  static const double bounceVelocity = -475; // Reduced bounce force (from -900)
  static const double heightScale = 4; // Make mushroom 4.5x taller (increased from 3x)
  static const double widthScale = 2.5; // Make mushroom 2.5x wider (increased from 1.5x)

  Mushroom({
    required double worldWidth,
    required double height,
    required Vector2 startPosition,
  }) : super(
          worldWidth: worldWidth,
          height: height,
          numBlocks: 1, // Single mushroom
          startPosition: startPosition,
          heightInBlocks: 1,
        );

  @override
  Future<void> onLoad() async {
    final mushroomSprite = await Sprite.load('Platforms/mushroom.png');
    final mushroom = SpriteComponent(
      sprite: mushroomSprite,
      size: Vector2(Platform.platformSize * widthScale, Platform.platformSize * heightScale), // Increased width and height
      position: Vector2(-Platform.platformSize * (widthScale - 1) / 2, -Platform.platformSize * (heightScale - 1) + 35), // Center it and align bottom
    );
    add(mushroom);

    // Add bounce collision hitbox at the top of the mushroom
    add(RectangleHitbox(
      size: Vector2(Platform.platformSize * (widthScale - 0.3), Platform.platformSize * 0.1), // Wider hitbox (increased from widthScale - 0.3)
      position: Vector2(
        -Platform.platformSize * (widthScale - 1) / 2 - Platform.platformSize * 0.1 + 14, // Adjusted center position for wider hitbox
        -Platform.platformSize * (heightScale - 1) - Platform.platformSize * 0.1 + 72, // Align with visual top
      ),
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey) {
      other.bounce(bounceVelocity); // Apply bounce force to monkey
    }
    super.onCollisionStart(intersectionPoints, other);
  }
} 