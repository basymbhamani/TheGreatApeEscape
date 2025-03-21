import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'platform.dart';
import 'monkey.dart';
import 'game.dart';

class Cloud extends Platform {
  static const double heightScale = 3.5; // Reduced from 4
  static const double widthScale = 2.0; // Reduced from 2.5
  final Vector2 initialPosition;
  bool _isFlashing = false;
  bool _isBreaking = false;
  int _blinkCount = 0;
  static const int _totalBlinks = 10;
  static const double _blinkDuration = 0.2;
  double _blinkTimer = 0;
  double opacity = 1.0;
  Monkey? _monkeyOnCloud;

  Cloud({
    required double worldWidth,
    required double height,
    required Vector2 startPosition,
    int numBlocks = 1,
    int heightInBlocks = 1,
  })  : initialPosition = startPosition.clone(),
        super(
          worldWidth: worldWidth,
          height: height,
          numBlocks: numBlocks,
          startPosition: startPosition,
          heightInBlocks: heightInBlocks,
        );

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('Cloud/cloud.png');
    final cloudSprite = SpriteComponent(
      sprite: sprite,
      size: Vector2(Platform.platformSize * widthScale, Platform.platformSize * heightScale),
    );
    cloudSprite.opacity = opacity;
    add(cloudSprite);

    // Add collision hitbox that matches the cloud's total height
    add(RectangleHitbox(
      size: Vector2(Platform.platformSize * numBlocks - 30, Platform.platformSize * 0.6), // Increased height further
      position: Vector2(0, 56), // Moved up more to better match visual cloud
      collisionType: CollisionType.passive, // Changed back to passive
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  void startBreaking() {
    if (!_isBreaking) {
      _isBreaking = true;
      _isFlashing = true;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey) {
      // Check if monkey is above the cloud and falling
      if (other.position.y + other.size.y / 2 > position.y && 
          other.position.y + other.size.y / 2 < position.y + 60 && // Increased buffer zone further
          other.velocity.y > 0) {
        other.isGrounded = true;
        other.velocity.y = 0;
        //other.position.y = position.y - other.size.y / 2;
        _monkeyOnCloud = other;
      }
      startBreaking();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey && other == _monkeyOnCloud) {
      other.isGrounded = false;
      _monkeyOnCloud = null;
    }
    super.onCollisionEnd(other);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isBreaking) {
      if (_isFlashing) {
        _blinkTimer += dt;
        if (_blinkTimer >= _blinkDuration) {
          _blinkTimer = 0;
          opacity = opacity == 1.0 ? 0.0 : 1.0;
          // Update the sprite opacity
          children.whereType<SpriteComponent>().forEach((sprite) {
            sprite.opacity = opacity;
          });
          _blinkCount++;
          
          if (_blinkCount >= _totalBlinks) {
            _isFlashing = false;
            opacity = 0.0;
            // Update the sprite opacity one final time
            children.whereType<SpriteComponent>().forEach((sprite) {
              sprite.opacity = opacity;
            });
            
            // Keep the cloud in the game layer but make it invisible
            // This ensures collision detection continues to work
            final parentRef = parent;
            final positionRef = position.clone();
            
            // Remove the cloud after a short delay to ensure proper collision handling
            Future.delayed(const Duration(milliseconds: 100), () {
              removeFromParent();

              // Restore the cloud after 5 seconds
              Future.delayed(Duration(seconds: 5), () {
                final newCloud = Cloud(
                  worldWidth: worldWidth,
                  height: height,
                  startPosition: positionRef,
                  numBlocks: numBlocks,
                  heightInBlocks: heightInBlocks,
                );
                parentRef?.add(newCloud);
              });
            });
          }
        }
      }
    }
  }
}