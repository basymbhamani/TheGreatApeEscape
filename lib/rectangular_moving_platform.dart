import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'monkey.dart';

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

  // Track monkeys on the platform
  final Set<Monkey> _monkeysOnPlatform = {};

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

  void _updateMonkeyPositions() {
    for (final monkey in _monkeysOnPlatform) {
      if (!monkey.isDead && monkey.isGrounded) {
        // Make sure monkeys move with the platform
        // First, calculate platform's current velocity
        final Vector2 toTarget = _currentTarget - position;
        if (toTarget.length > 0) {
          toTarget.normalize();

          // Apply the same velocity to the monkey
          final Vector2 monkeyVelocity =
              toTarget * moveSpeed * 0.016; // Approximate one frame
          monkey.position.x += monkeyVelocity.x;

          // For vertical position, keep the monkey firmly on top of the platform
          monkey.position.y = position.y - monkey.size.y / 2;
          monkey.velocity.y = 0;
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Remove dead monkeys from tracking
    _monkeysOnPlatform.removeWhere((monkey) => monkey.isDead);

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

    // Update monkey positions
    _updateMonkeyPositions();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Monkey) {
      // Only add the monkey if not already being tracked
      if (!_monkeysOnPlatform.contains(other)) {
        // Check if monkey is landing on top of the platform
        final monkeyBottom = other.position.y + other.size.y / 2;
        final platformTop = position.y;

        if ((monkeyBottom - platformTop).abs() < 10 && other.velocity.y >= 0) {
          // Set the monkey's position firmly on top of the platform
          other.position.y = position.y - other.size.y / 2;
          other.velocity.y = 0;
          other.isGrounded = true;

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
        final platformLeft = position.x;
        final platformRight = position.x + size.x;

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
}
