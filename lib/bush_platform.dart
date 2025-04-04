import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'platform.dart';
import 'bush.dart';
import 'monkey.dart';

class BushPlatform extends PositionComponent with CollisionCallbacks {
  static const double bushSize = 56.0; // Same size as platform blocks
  final Vector2 startPosition;
  final int numBlocks;
  final double height;
  bool _isMoving = false;
  bool _isReturning = false;
  bool _hasMoved = false; // Track if platform has moved from starting position
  static const double _moveSpeed = 80.0; // Even slower speed (from 100 to 80)
  static const double _targetHeight =
      80.0; // Half a block lower (from 50 to 80)
  static const double _moveTime =
      3.0; // Time in seconds before platform stops moving
  double _moveTimer = 0.0;
  // Replace single monkey tracking with a set to track multiple monkeys
  final Set<Monkey> _monkeysOnPlatform = {};
  // Track monkeys that jumped off but might land back
  final Set<Monkey> _recentlyJumpedMonkeys = {};
  double _lastMoveY = 0.0; // Track the last vertical movement amount
  final bool moveRight; // Whether to move right instead of up

  BushPlatform({
    required this.startPosition,
    this.numBlocks = 5, // Default to 5 blocks
    this.height = 1, // Default to 1 block height
    this.moveRight = false, // Default to moving up
  }) {
    position = startPosition.clone(); // Clone to keep original startPosition
    size = Vector2(bushSize * numBlocks, bushSize * height);
  }

  void reset() {
    position = startPosition.clone();
    _isMoving = false;
    _isReturning = false;
    _hasMoved = false;
    _moveTimer = 0.0;
    _monkeysOnPlatform.clear();
    _recentlyJumpedMonkeys.clear();
    _lastMoveY = 0.0;
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

  void startReturning() {
    if (_hasMoved && !_isReturning) {
      _isReturning = true;
      _isMoving = false;
      _moveTimer = 0.0;

      // Update all monkeys on platform
      for (final monkey in _monkeysOnPlatform) {
        monkey.isGrounded = false;
      }
      _monkeysOnPlatform.clear();
    }
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

    // Add larger collision hitbox for better detection
    add(
      RectangleHitbox(
        size: Vector2(
          bushSize * numBlocks * 1.0,
          bushSize * 0.15, // Slightly thicker hitbox
        ),
        position: Vector2(
          -bushSize + (bushSize * 0.05),
          bushSize * 0.1, // Position it a bit higher
        ),
        collisionType: CollisionType.passive,
      )..debugMode = ApeEscapeGame.showHitboxes,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Reset the last move amount at the beginning of the update
    _lastMoveY = 0.0;

    // Check if any monkey is dead and reset platform
    for (final monkey in _monkeysOnPlatform.toList()) {
      if (monkey.isDead) {
        reset();
        return;
      }
    }

    // Clear recently jumped monkeys that are far away
    _recentlyJumpedMonkeys.removeWhere((monkey) {
      final distance = (monkey.position.y - position.y).abs();
      return distance > bushSize * 3;
    });

    // Check for monkeys that jumped but are now falling back down
    for (final monkey in _recentlyJumpedMonkeys.toList()) {
      if (monkey.velocity.y > 0 && // Falling down
          monkey.position.x >= position.x - (bushSize * numBlocks / 2) &&
          monkey.position.x <= position.x + (bushSize * numBlocks) &&
          monkey.position.y + monkey.size.y / 2 >=
              position.y - bushSize * 0.2 &&
          monkey.position.y + monkey.size.y / 2 <=
              position.y + bushSize * 0.3) {
        // Monkey is falling back onto the platform
        _monkeysOnPlatform.add(monkey);
        _recentlyJumpedMonkeys.remove(monkey);
        monkey.isGrounded = true;
        monkey.velocity.y = 0;
        monkey.position.y = position.y - monkey.size.y / 2;
      }
    }

    // Start moving only if both monkeys are on the platform
    if (_monkeysOnPlatform.isNotEmpty && !_isMoving && !_isReturning) {
      _isMoving = _hasBothMonkeys;
    }

    if (_isMoving) {
      _moveTimer += dt;

      if (_moveTimer >= _moveTime) {
        // Stop moving but stay in position
        _isMoving = false;
        return;
      }

      if (moveRight) {
        // Move right
        position.x += _moveSpeed * dt;
        _hasMoved = true;

        // Move all monkeys right with platform
        for (final monkey in _monkeysOnPlatform) {
          monkey.position.x += _moveSpeed * dt;
        }
      } else {
        // Move upward
        final double moveAmount = _moveSpeed * dt;
        position.y -= moveAmount;
        _lastMoveY =
            -moveAmount; // Store the movement amount (negative for upward)
        _hasMoved = true;

        // Move all monkeys up with platform
        for (final monkey in _monkeysOnPlatform) {
          monkey.position.y -= moveAmount;
        }

        // Check if we've reached the target height
        if (position.y <= _targetHeight) {
          position.y = _targetHeight;
          _isMoving = false;
        }
      }
    } else if (_isReturning) {
      final Vector2 toStart = startPosition - position;
      if (toStart.length < _moveSpeed * dt) {
        // Close enough to snap to start position
        reset();
      } else {
        toStart.normalize();
        Vector2 moveAmount = toStart * _moveSpeed * dt;
        position += moveAmount;

        // Track vertical movement for collision detection
        _lastMoveY = moveAmount.y;
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Monkey && !_isReturning) {
      // Check if the monkey is landing on top of the platform
      final bool isLandingOnTop =
          other.velocity.y > 0 && // Falling down
          other.position.y + other.size.y / 2 <= position.y + bushSize * 0.3;

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

        // Add monkey to tracking set
        _monkeysOnPlatform.add(other);
        _recentlyJumpedMonkeys.remove(other);

        // Check if we now have both monkeys to start moving
        if (_hasBothMonkeys && !_hasMoved) {
          _isMoving = true;
        }

        // Listen for monkey reset
        other.setOnReset(() {
          reset();
        });
      } else {
        // If not landing on top, don't ground the monkey
        // This prevents side collisions from causing issues
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Continually check collision for platform movement
    if (other is Monkey && _monkeysOnPlatform.contains(other)) {
      // If platform is moving downward (returning) and monkey is still on it,
      // make sure monkey follows it properly
      if (_lastMoveY > 0) {
        // Platform is moving downward
        other.position.y += _lastMoveY;
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

        // If all monkeys left and platform has moved, start returning
        if (_monkeysOnPlatform.isEmpty && _hasMoved) {
          startReturning();
        }
      }
    }
    super.onCollisionEnd(other);
  }
}
