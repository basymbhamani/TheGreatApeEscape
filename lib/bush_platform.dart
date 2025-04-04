import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'monkey.dart';

class BushPlatform extends PositionComponent with CollisionCallbacks {
  static const double bushSize = 56.0;
  final Vector2 startPosition;
  final int numBlocks;
  final double height;
  final bool moveRight;

  // Movement constants
  final double moveDistance;
  final double moveSpeed;
  late final Vector2 _originalPosition;
  double _direction = 1;

  // Monkey tracking
  final Set<Monkey> _monkeysOnPlatform = {};

  // Collision settings
  static const double _hitboxHeight = 0.2;
  static const double _hitboxYOffset = 0.15;

  // For network identification
  final String platformId;

  BushPlatform({
    required this.startPosition,
    this.numBlocks = 5,
    this.height = 1,
    this.moveRight = false,
    this.moveDistance = 80.0,
    this.moveSpeed = 50.0,
    String? id,
  }) : platformId =
           id ?? 'bush_platform_${startPosition.x}_${startPosition.y}' {
    position = startPosition.clone();
    _originalPosition = startPosition.clone();
    size = Vector2(bushSize * numBlocks, bushSize * height);
  }

  @override
  Future<void> onLoad() async {
    // Load bush sprites
    final bushCenterSprite = await Sprite.load('Bush/bush_center.png');
    final bushRightSprite = await Sprite.load('Bush/bush_right.png');

    // Add left bush (flipped right bush)
    final bushLeft = SpriteComponent(
      sprite: bushRightSprite,
      position: Vector2(0, 0),
      size: Vector2.all(bushSize),
    );
    bushLeft.scale.x = -1; // Flip horizontally
    add(bushLeft);

    // Add center bushes
    for (int i = 1; i < numBlocks - 1; i++) {
      final bushCenter = SpriteComponent(
        sprite: bushCenterSprite,
        position: Vector2(bushSize * (i - 1), 0),
        size: Vector2.all(bushSize),
      );
      add(bushCenter);
    }

    // Add right bush
    final bushRight = SpriteComponent(
      sprite: bushRightSprite,
      position: Vector2(bushSize * (numBlocks - 2), 0),
      size: Vector2.all(bushSize),
    );
    add(bushRight);

    // Add wider collision hitbox with increased height
    add(
      RectangleHitbox(
        size: Vector2(bushSize * numBlocks, bushSize * _hitboxHeight),
        position: Vector2(
          -bushSize + (bushSize * 0.05),
          bushSize * _hitboxYOffset,
        ),
        collisionType: CollisionType.passive,
      )..debugMode = ApeEscapeGame.showHitboxes,
    );
  }

  void _updateMonkeyPositions() {
    for (final monkey in _monkeysOnPlatform) {
      if (!monkey.isDead && monkey.isGrounded) {
        if (moveRight) {
          // For horizontal movement, match the platform's velocity
          // This makes the monkey move with the platform while still allowing player control
          monkey.position.x +=
              moveSpeed *
              _direction *
              0.016; // Approximate delta time of one frame
        } else {
          // For vertical movement, keep the monkey firmly attached to the platform
          monkey.position.y =
              position.y - monkey.size.y / 2 + bushSize * _hitboxYOffset;
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Remove dead monkeys from tracking
    _monkeysOnPlatform.removeWhere((monkey) => monkey.isDead);

    if (moveRight) {
      // Move horizontally
      position.x += moveSpeed * _direction * dt;

      // Check if we need to change direction
      if (_direction > 0 && position.x >= _originalPosition.x + moveDistance) {
        _direction = -1;
      } else if (_direction < 0 && position.x <= _originalPosition.x) {
        _direction = 1;
      }
    } else {
      // Move vertically
      position.y += moveSpeed * _direction * dt;

      // Check if we need to change direction
      if (_direction > 0 && position.y >= _originalPosition.y + moveDistance) {
        _direction = -1;
      } else if (_direction < 0 && position.y <= _originalPosition.y) {
        _direction = 1;
      }
    }

    // Update positions of all monkeys on the platform
    _updateMonkeyPositions();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Monkey) {
      // Only add monkey if not already tracked
      if (!_monkeysOnPlatform.contains(other)) {
        // Check if the monkey is landing on top (not hitting from below or sides)
        final monkeyBottom = other.position.y + other.size.y / 2;
        final platformTop = position.y + bushSize * _hitboxYOffset;

        if ((monkeyBottom - platformTop).abs() < 10 && other.velocity.y >= 0) {
          other.isGrounded = true;
          other.velocity.y = 0;

          // Position monkey on top of platform
          other.position.y =
              position.y - other.size.y / 2 + bushSize * _hitboxYOffset;

          // Update animation based on movement
          if (other.joystick != null) {
            other.animation =
                (other.joystick!.delta.x.abs() > 0)
                    ? other.runAnimation
                    : other.idleAnimation;
          } else {
            other.animation = other.idleAnimation;
          }

          // Add to tracked monkeys
          _monkeysOnPlatform.add(other);
        }
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey) {
      if (_monkeysOnPlatform.contains(other)) {
        // Check if monkey is truly off the platform horizontally
        final platformLeft = position.x - size.x / 2;
        final platformRight = position.x + size.x / 2;

        if (other.position.x < platformLeft ||
            other.position.x > platformRight) {
          other.isGrounded = false;
          _monkeysOnPlatform.remove(other);
        }
        // If monkey is jumping, let physics handle it but keep it in our tracking set
        else if (other.velocity.y < 0) {
          other.isGrounded = false;
        }
      }
    }
    super.onCollisionEnd(other);
  }

  // Method for network synchronization (to keep compatible with game.dart)
  void syncState(String state, Map<String, dynamic> data) {
    // This class doesn't need state syncing as movement is deterministic
    // If position data is included, we could sync it
    if (data.containsKey('x') && data.containsKey('y')) {
      position.x = data['x'];
      position.y = data['y'];
    }
  }
}
