import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'monkey.dart';
import 'platform.dart';

class Heart extends PositionComponent with CollisionCallbacks {
  static const double heartSize = 56.0; // Same size as platform blocks
  bool _isCollected = false;

  Heart({
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2.all(heartSize);
  }

  @override
  Future<void> onLoad() async {
    // Load heart sprite
    final heartSprite = await Sprite.load('Heart/heart.png');
    add(SpriteComponent(
      sprite: heartSprite,
      size: Vector2.all(heartSize),
    ));

    // Add collision hitbox
    add(RectangleHitbox(
      size: Vector2(heartSize * 0.8, heartSize * 0.8), // Slightly smaller than sprite
      position: Vector2(4, 10), // Offset 4 pixels right and 10 pixels down
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  void collect() {
    if (!_isCollected) {
      _isCollected = true;
      // Set checkpoint position slightly above the heart
      Monkey.checkpointPosition = Vector2(
        position.x,
        position.y - Platform.platformSize, // One block above the heart
      );
      // Change sprite to empty heart
      Sprite.load('Heart/empty_heart.png').then((sprite) {
        if (children.isNotEmpty) {
          (children.first as SpriteComponent).sprite = sprite;
        }
      });
    }
  }

  bool get isCollected => _isCollected;
} 