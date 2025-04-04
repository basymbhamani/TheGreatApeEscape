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
  // Track monkeys that jumped off but might land back
  final Set<Monkey> _recentlyJumpedMonkeys = {};
  bool _isMoving = false;
  Vector2 _lastMoveAmount = Vector2.zero();

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

  // Check if we have both monkeys on the platform
  bool get _hasBothMonkeys {
    if (_monkeysOnPlatform.length < 2) return false;

    // Check if there's at least one local and one remote player
    bool hasLocalPlayer = false;
    bool hasRemotePlayer = false;

    for (var monkey in _monkeysOnPlatform) {
      if (monkey.isRemotePlayer) {
        hasRemotePlayer = true;
      } else {
        hasLocalPlayer = true;
      }
    }

    return hasLocalPlayer && hasRemotePlayer;
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
        size: Vector2(platformSize * numBlocks, platformSize * 0.15),
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

    // Reset last movement amount
    _lastMoveAmount = Vector2.zero();

    // Check if any monkey is dead
    for (final monkey in _monkeysOnPlatform.toList()) {
      if (monkey.isDead) {
        _monkeysOnPlatform.clear();
        _recentlyJumpedMonkeys.clear();
        return;
      }
    }

    // Clear recently jumped monkeys that are far away
    _recentlyJumpedMonkeys.removeWhere((monkey) {
      final distance = (monkey.position - position).length;
      return distance > platformSize * 3;
    });

    // Check for monkeys that jumped but are now falling back down
    for (final monkey in _recentlyJumpedMonkeys.toList()) {
      if (monkey.velocity.y > 0 && // Falling down
          monkey.position.x >= position.x - platformSize &&
          monkey.position.x <= position.x + (platformSize * numBlocks) &&
          monkey.position.y + monkey.size.y / 2 >=
              position.y - platformSize * 0.2 &&
          monkey.position.y + monkey.size.y / 2 <=
              position.y + platformSize * 0.3) {
        // Monkey is falling back onto the platform
        _monkeysOnPlatform.add(monkey);
        _recentlyJumpedMonkeys.remove(monkey);
        monkey.isGrounded = true;
        monkey.velocity.y = 0;
        monkey.position.y = position.y - monkey.size.y / 2;
      }
    }

    // Update movement state based on monkeys
    _isMoving = _hasBothMonkeys;

    // Only move if we have both monkeys on the platform
    if (_isMoving) {
      final Vector2 toTarget = _currentTarget - position;
      if (toTarget.length < moveSpeed * dt) {
        // Reached target, move to next corner
        _lastMoveAmount = _currentTarget - position;
        position = _currentTarget;
        _currentCorner = (_currentCorner + 1) % 4;
        _updateTarget();
      } else {
        // Move towards target
        toTarget.normalize();
        Vector2 moveAmount = toTarget * moveSpeed * dt;
        position += moveAmount;
        _lastMoveAmount = moveAmount;

        // Move all monkeys with the platform
        for (final monkey in _monkeysOnPlatform) {
          monkey.position += moveAmount;
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Monkey && !other.isDead) {
      // Check if the monkey is landing on top of the platform
      final bool isLandingOnTop =
          other.velocity.y > 0 && // Falling down
          other.position.y + other.size.y / 2 <=
              position.y + platformSize * 0.3;

      if (isLandingOnTop) {
        other.isGrounded = true;
        other.velocity.y = 0;
        other.position.y = position.y - other.size.y / 2;

        if (other.joystick != null) {
          other.animation =
              (other.joystick!.delta.x.abs() > 0)
                  ? other.runAnimation
                  : other.idleAnimation;
        } else {
          other.animation = other.idleAnimation;
        }

        // Add monkey to platform
        _monkeysOnPlatform.add(other);
        _recentlyJumpedMonkeys.remove(other);

        // Listen for monkey reset
        other.setOnReset(() {
          _monkeysOnPlatform.clear();
          _recentlyJumpedMonkeys.clear();
        });
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Continually check collision while platform is moving
    if (other is Monkey && _monkeysOnPlatform.contains(other)) {
      // If platform is moving and monkey is still on it,
      // make sure monkey follows it properly, especially for vertical movement
      if (_lastMoveAmount.y != 0) {
        other.position.y += _lastMoveAmount.y;
        other.velocity.y = 0;
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey) {
      if (_monkeysOnPlatform.contains(other)) {
        // If the monkey was on the platform but is now jumping
        if (other.velocity.y < 0) {
          // Jumping up
          // Add to recently jumped set to handle returning to platform
          _recentlyJumpedMonkeys.add(other);
        }

        other.isGrounded = false;
        _monkeysOnPlatform.remove(other);
      }
    }
    super.onCollisionEnd(other);
  }
}
