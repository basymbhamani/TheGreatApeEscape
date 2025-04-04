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
  final bool moveRight; // Whether to move right instead of up

  // Movement constants
  static const double _moveSpeed = 80.0;
  static const double _targetHeight = 80.0;
  static const double _moveTime = 3.0;
  static const double _hitboxHeight = 0.2;
  static const double _hitboxYOffset = 0.15;

  // Platform state
  bool _isMoving = false;
  bool _isReturning = false;
  bool _hasMoved = false; // Track if platform has moved from starting position
  double _moveTimer = 0.0;

  // Monkey tracking
  final Set<Monkey> _monkeysOnPlatform = {};
  final Set<String> _monkeyIds = {};

  // Offsets for monkey positioning
  late final double _monkeyYOffset;

  BushPlatform({
    required this.startPosition,
    this.numBlocks = 5, // Default to 5 blocks
    this.height = 1, // Default to 1 block height
    this.moveRight = false, // Default to moving up
  }) {
    position = startPosition.clone(); // Clone to keep original startPosition
    size = Vector2(bushSize * numBlocks, bushSize * height);
    _monkeyYOffset = bushSize * _hitboxYOffset;
  }

  void reset() {
    position = startPosition.clone();
    _isMoving = false;
    _isReturning = false;
    _hasMoved = false;
    _moveTimer = 0.0;
    _monkeysOnPlatform.clear();
    _monkeyIds.clear();
  }

  // Check if we have both local and remote monkeys
  bool get _hasBothMonkeys {
    if (_monkeysOnPlatform.length < 2) return false;

    bool hasLocalPlayer = false;
    bool hasRemotePlayer = false;

    for (final monkey in _monkeysOnPlatform) {
      if (monkey.isRemotePlayer) {
        hasRemotePlayer = true;
      } else {
        hasLocalPlayer = true;
      }

      // Early return if we already found both types
      if (hasLocalPlayer && hasRemotePlayer) return true;
    }

    return hasLocalPlayer && hasRemotePlayer;
  }

  void startReturning() {
    if (_hasMoved && !_isReturning) {
      _isReturning = true;
      _isMoving = false;
      _moveTimer = 0.0;
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
      if (!monkey.isDead) {
        // Keep monkeys firmly attached to platform
        monkey.position.y = position.y - monkey.size.y / 2 + _monkeyYOffset;

        // Reset monkey velocity to prevent falling
        monkey.velocity.y = 0;
        monkey.isGrounded = true;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle monkey deaths
    final deadMonkeys = _monkeysOnPlatform.where((m) => m.isDead).toList();
    if (deadMonkeys.isNotEmpty) {
      for (final monkey in deadMonkeys) {
        _monkeysOnPlatform.remove(monkey);
        if (monkey.playerId != null) {
          _monkeyIds.remove(monkey.playerId);
        }
      }
    }

    // Check if any monkey is dead and reset platform if needed
    if (_isMoving && _monkeysOnPlatform.any((m) => m.isDead)) {
      reset();
      return;
    }

    // Start moving only when both monkeys are on the platform
    if (!_isMoving && !_isReturning && _hasBothMonkeys) {
      _isMoving = true;
      _hasMoved = true;
    }

    if (_isMoving) {
      _moveTimer += dt;

      if (_moveTimer >= _moveTime) {
        // Stop moving but stay in position
        _isMoving = false;
        _updateMonkeyPositions(); // Final position adjustment
        return;
      }

      if (moveRight) {
        // Move right
        position.x += _moveSpeed * dt;

        // Move all monkeys right with platform
        for (final monkey in _monkeysOnPlatform) {
          if (!monkey.isDead) {
            monkey.position.x += _moveSpeed * dt;
          }
        }
      } else {
        // Move upward
        position.y -= _moveSpeed * dt;

        // Check if we've reached the target height
        if (position.y <= startPosition.y - _targetHeight) {
          position.y = startPosition.y - _targetHeight;
          _isMoving = false;
        }
      }

      // Update all monkeys' positions to keep them firmly on platform
      _updateMonkeyPositions();
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
      // Only add the monkey if it's not already being tracked
      // and check if we already have this player ID
      if (!_monkeysOnPlatform.contains(other) &&
          (other.playerId == null || !_monkeyIds.contains(other.playerId))) {
        // Set the monkey's position firmly on top of the platform
        other.position.y = position.y - other.size.y / 2 + _monkeyYOffset;
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

        // Track this monkey
        _monkeysOnPlatform.add(other);
        if (other.playerId != null) {
          _monkeyIds.add(other.playerId!);
        }

        // Reset callback for monkey
        other.setOnReset(() {
          if (_monkeysOnPlatform.contains(other)) {
            _monkeysOnPlatform.remove(other);
            if (other.playerId != null) {
              _monkeyIds.remove(other.playerId);
            }
          }

          // If any monkey resets, also reset the platform
          reset();
        });
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey) {
      // Only unground if the monkey is actually leaving the platform
      // and not just during collision fluctuations
      if (_monkeysOnPlatform.contains(other)) {
        // Check if the monkey is truly off the platform by position
        final monkeyBottom = other.position.y + other.size.y / 2;
        final platformTop = position.y + bushSize * _hitboxYOffset;

        // Only remove if monkey is clearly off platform
        if (monkeyBottom < platformTop - 10 ||
            other.position.x < position.x - size.x / 2 ||
            other.position.x > position.x + size.x / 2) {
          other.isGrounded = false;
          _monkeysOnPlatform.remove(other);
          if (other.playerId != null) {
            _monkeyIds.remove(other.playerId);
          }

          // If all monkeys left and platform has moved, start returning
          if (_monkeysOnPlatform.isEmpty && _hasMoved) {
            startReturning();
          }
        }
      }
    }
    super.onCollisionEnd(other);
  }
}
