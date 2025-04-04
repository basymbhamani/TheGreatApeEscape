import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../platforms/platform.dart';
import '../../models/monkey.dart';
import '../../game.dart';

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
      size: Vector2(Platform.platformSize * numBlocks - 60, Platform.platformSize), // Increased horizontal padding from 20 to 40
      position: Vector2(0, 60), // Adjusted position to better match visual cloud
      collisionType: CollisionType.passive,
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
      print("\n=== Cloud Collision Debug ===");
      print("Monkey position: ${other.position}");
      print("Monkey velocity: ${other.velocity}");
      print("Cloud position: $position");
      print("Cloud hitbox size: ${children.whereType<RectangleHitbox>().first.size}");
      print("Cloud hitbox position: ${children.whereType<RectangleHitbox>().first.position}");
      
      // Handle platform behavior
      final verticalOverlap = other.position.y + other.size.y / 2 - position.y;
      print("Vertical overlap: $verticalOverlap");
      
      // Simplified collision check - just check if monkey is above cloud and within range
      if (other.position.y + other.size.y / 2 > position.y && 
          other.position.y + other.size.y / 2 < position.y + 100) { // Increased range to 100
        print("Platform conditions met - grounding monkey");
        other.isGrounded = true;
        other.velocity.y = 0;
         // Snap to cloud surface
        other.animation = (other.joystick?.delta.x.abs() ?? 0) > 0 ? other.runAnimation : other.idleAnimation;
        _monkeyOnCloud = other;
      } else {
        print("Platform conditions NOT met:");
        print("Above cloud: ${other.position.y + other.size.y / 2 > position.y}");
        print("Within range: ${other.position.y + other.size.y / 2 < position.y + 100}");
      }
      
      // Start breaking animation
      print("Starting cloud breaking animation");
      startBreaking();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey && other == _monkeyOnCloud) {
      print("\n=== Cloud Collision End Debug ===");
      print("Monkey leaving cloud");
      print("Monkey position: ${other.position}");
      print("Monkey velocity: ${other.velocity}");
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