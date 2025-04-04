import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game.dart';

class RectangularMovingPlatform extends PositionComponent
    with CollisionCallbacks {
  static const double platformSize = 56.0;
  final Vector2 startPosition;
  final double width;
  final double height;
  final double moveSpeed;
  late Vector2 _originalPosition;
  Vector2 _currentTarget = Vector2.zero();
  int _currentCorner = 0;
  final int numBlocks; // Number of platform blocks wide

  // Add getter for _currentTarget
  Vector2 get currentTarget => _currentTarget;

  RectangularMovingPlatform({
    required this.startPosition,
    required this.width,
    required this.height,
    this.moveSpeed = 100, // Pixels per second
    this.numBlocks = 3, // Default to 3 blocks wide
  }) {
    position = startPosition;
    _originalPosition = startPosition.clone();
    size = Vector2(platformSize * numBlocks, platformSize);
  }

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('Platforms/moving_platform_single.png');

    // Add multiple platform sprites side by side
    for (int i = 0; i < numBlocks; i++) {
      final platform = SpriteComponent(
        sprite: sprite,
        position: Vector2(platformSize * i, 0),
        size: Vector2(platformSize, platformSize),
      );
      add(platform);
    }

    // Add collision hitbox that spans all blocks
    add(
      RectangleHitbox(
        size: Vector2(platformSize * numBlocks, platformSize * 0.1),
        position: Vector2(0, 0),
        collisionType: CollisionType.passive,
      )..debugMode = ApeEscapeGame.showHitboxes,
    );

    // Set initial target
    _updateTarget();
  }

  void _updateTarget() {
    switch (_currentCorner) {
      case 0: // Top right
        _currentTarget = _originalPosition + Vector2(width, 0);
        break;
      case 1: // Bottom right
        _currentTarget = _originalPosition + Vector2(width, height);
        break;
      case 2: // Bottom left
        _currentTarget = _originalPosition + Vector2(0, height);
        break;
      case 3: // Top left (back to start)
        _currentTarget = _originalPosition;
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final Vector2 toTarget = _currentTarget - position;
    if (toTarget.length < moveSpeed * dt) {
      // Reached target, move to next corner
      position = _currentTarget;
      _currentCorner = (_currentCorner + 1) % 4;
      _updateTarget();
    } else {
      // Move towards target
      toTarget.normalize();
      position += toTarget * moveSpeed * dt;
    }
  }
}
