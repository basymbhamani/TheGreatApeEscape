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

    // Add collision hitbox
    add(
      RectangleHitbox(
        size: Vector2(
          bushSize * numBlocks * 1.0,
          bushSize * 0.2,
        ), // Increased height from 0.1 to 0.2 for better collision detection
        position: Vector2(
          -bushSize + (bushSize * 0.05),
          bushSize * 0.15,
        ), // Kept at same position
        collisionType: CollisionType.passive,
      )..debugMode = ApeEscapeGame.showHitboxes,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if any monkey is dead and reset platform
    for (final monkey in _monkeysOnPlatform.toList()) {
      if (monkey.isDead) {
        reset();
        return;
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
          // Ensure monkey stays on top of platform
          monkey.position.y = position.y - monkey.size.y / 2 + bushSize * 0.15;
        }
      } else {
        // Move upward
        position.y -= _moveSpeed * dt;
        _hasMoved = true;

        // Move all monkeys up with platform
        for (final monkey in _monkeysOnPlatform) {
          monkey.position.y -= _moveSpeed * dt;
          // Ensure monkey stays on top of platform
          monkey.position.y = position.y - monkey.size.y / 2 + bushSize * 0.15;
        }

        // Check if we've reached the target height
        if (position.y <= _targetHeight) {
          position.y = _targetHeight;
          _isMoving = false;

          // One final position adjustment for all monkeys
          for (final monkey in _monkeysOnPlatform) {
            monkey.position.y =
                position.y - monkey.size.y / 2 + bushSize * 0.15;
          }
        }
      }
    } else if (_isReturning) {
      final Vector2 toStart = startPosition - position;
      if (toStart.length < _moveSpeed * dt) {
        // Close enough to snap to start position
        reset();
      } else {
        toStart.normalize();
        position += toStart * _moveSpeed * dt;
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Monkey && !_isReturning) {
      other.isGrounded = true;
      other.velocity.y = 0;

      // Set the monkey's position to be on top of the platform
      other.position.y = position.y - other.size.y / 2 + bushSize * 0.15;

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

      // Check if we now have both monkeys to start moving
      if (_hasBothMonkeys && !_hasMoved) {
        _isMoving = true;
      }

      // Listen for monkey reset
      other.setOnReset(() {
        reset();
      });
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey) {
      other.isGrounded = false;
      _monkeysOnPlatform.remove(other);

      // If all monkeys left and platform has moved, start returning
      if (_monkeysOnPlatform.isEmpty && _hasMoved) {
        startReturning();
      }
    }
    super.onCollisionEnd(other);
  }
}
