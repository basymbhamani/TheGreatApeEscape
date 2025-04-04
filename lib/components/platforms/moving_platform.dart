import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game.dart';

class MovingPlatform extends PositionComponent with CollisionCallbacks {
  static const double platformSize = 56.0;
  final double worldWidth;
  final double worldHeight;
  final Vector2 startPosition;
  final double moveDistance;
  final double moveSpeed;
  late Vector2 _originalPosition;
  double _direction = 1;

  // Make direction accessible
  double get direction => _direction;

  MovingPlatform({
    required this.worldWidth,
    required this.worldHeight,
    required this.startPosition,
    this.moveDistance = platformSize * 3, // Move 3 blocks by default
    this.moveSpeed = 100, // Pixels per second
  }) {
    position = startPosition;
    _originalPosition = startPosition.clone();
    size = Vector2(platformSize, platformSize);
  }

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('Platforms/moving_platform_single.png');
    final platform = SpriteComponent(
      sprite: sprite,
      size: Vector2(platformSize, platformSize),
    );
    add(platform);

    // Add collision hitbox that matches the platform's total height
    add(RectangleHitbox(
      size: Vector2(platformSize, platformSize * 0.1), // Make hitbox height 10% of platform height
      position: Vector2(0, 0), // Position at the very top of the platform
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move horizontally
    position.x += moveSpeed * _direction * dt;

    // Check if we need to change direction
    if (_direction > 0 && position.x >= _originalPosition.x + moveDistance) {
      _direction = -1;
    } else if (_direction < 0 && position.x <= _originalPosition.x) {
      _direction = 1;
    }
  }
} 