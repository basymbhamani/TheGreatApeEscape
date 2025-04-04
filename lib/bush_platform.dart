import 'dart:convert';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'game.dart';
import 'monkey.dart';
import 'dart:math' as math;

class BushPlatform extends PositionComponent
    with CollisionCallbacks, HasGameRef<ApeEscapeGame> {
  static const double bushSize = 56.0;
  final Vector2 startPosition;
  final int numBlocks;
  final double height;

  // Visibility and state management
  bool _isVisible = false;
  bool _isStopped = true; // No movement needed

  // Sprites containers to manage visibility
  final List<SpriteComponent> _bushSprites = [];

  // Movement constants
  final double moveDistance = 150.0; // Increased height for more movement
  final double moveSpeed = 50.0;
  late final double originalY;
  late final double targetY;
  bool movingUp = false;
  final bool
  moveRight; // Whether the platform moves horizontally instead of vertically

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
    this.moveRight = false, // Default to vertical movement
    String? id,
  }) : platformId =
           id ?? 'bush_platform_${startPosition.x}_${startPosition.y}' {
    position = startPosition.clone();
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
    bushLeft.opacity = 0; // Start invisible
    add(bushLeft);
    _bushSprites.add(bushLeft);

    // Add center bushes
    for (int i = 1; i < numBlocks - 1; i++) {
      final bushCenter = SpriteComponent(
        sprite: bushCenterSprite,
        position: Vector2(bushSize * i, 0),
        size: Vector2.all(bushSize),
      );
      bushCenter.opacity = 0; // Start invisible
      add(bushCenter);
      _bushSprites.add(bushCenter);
    }

    // Add right bush
    final bushRight = SpriteComponent(
      sprite: bushRightSprite,
      position: Vector2(bushSize * (numBlocks - 1), 0),
      size: Vector2.all(bushSize),
    );
    bushRight.opacity = 0; // Start invisible
    add(bushRight);
    _bushSprites.add(bushRight);

    // Add collision hitbox - this is always active even when invisible
    add(
      RectangleHitbox(
        size: Vector2(bushSize * numBlocks, bushSize * _hitboxHeight),
        position: Vector2(0, bushSize * _hitboxYOffset),
        collisionType: CollisionType.passive,
      )..debugMode = ApeEscapeGame.showHitboxes,
    );

    // Initialize movement parameters
    if (moveRight) {
      // For horizontal movement
      originalY = position.x;
      targetY = originalY + moveDistance;
    } else {
      // For vertical movement
      originalY = position.y;
      targetY = originalY - moveDistance;
    }

    // Make the platform start in a random position in its movement cycle
    final random = math.Random();
    final randomOffset = random.nextDouble() * moveDistance;
    if (random.nextBool()) {
      if (moveRight) {
        position.x = originalY + randomOffset;
      } else {
        position.y = originalY - randomOffset;
      }
      movingUp = false;
    } else {
      if (moveRight) {
        position.x = originalY + moveDistance - randomOffset;
      } else {
        position.y = originalY - moveDistance + randomOffset;
      }
      movingUp = true;
    }
  }

  void makeVisible() {
    if (!_isVisible) {
      _isVisible = true;
      // Make all bush sprites visible
      for (final sprite in _bushSprites) {
        sprite.opacity = 1;
      }
      // Broadcast the visibility state to all players
      _broadcastState('visible');
    }
  }

  void _broadcastState(String state) {
    try {
      final socket = gameRef.socket;
      if (socket != null && gameRef.matchId != null) {
        final data = {
          'type': 'platform_state',
          'platformId': platformId,
          'state': state,
          'playerId': gameRef.session?.userId,
        };

        final jsonData = jsonEncode(data);
        socket.sendMatchData(
          matchId: gameRef.matchId!,
          opCode: 3, // opCode for platform state updates
          data: List<int>.from(utf8.encode(jsonData)),
        );
      }
    } catch (e) {
      print('Error broadcasting platform state: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update the positions of monkeys on the platform
    _updateMonkeyPositions();
  }

  void _updateMonkeyPositions() {
    for (final monkey in _monkeysOnPlatform) {
      if (!monkey.isDead && monkey.isGrounded) {
        // Keep monkey attached to the platform
        monkey.position.y =
            position.y - monkey.size.y / 2 + bushSize * _hitboxYOffset;
      } else if (monkey.velocity.y > 0) {
        // Monkey is falling - check if close to the platform
        final monkeyBottom = monkey.position.y + monkey.size.y / 2;
        final platformTop = position.y + bushSize * _hitboxYOffset;

        // If monkey is close to landing on the platform, re-attach it
        if ((monkeyBottom - platformTop).abs() < 15) {
          monkey.position.y =
              position.y - monkey.size.y / 2 + bushSize * _hitboxYOffset;
          monkey.velocity.y = 0;
          monkey.isGrounded = true;
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Monkey) {
      // Check if monkey is landing on top of the platform
      final monkeyBottom = other.position.y + other.size.y / 2;
      final platformTop = position.y + bushSize * _hitboxYOffset;

      if ((monkeyBottom - platformTop).abs() < 10 && other.velocity.y >= 0) {
        other.isGrounded = true;
        other.velocity.y = 0;

        // Position monkey on top of platform
        other.position.y =
            position.y - other.size.y / 2 + bushSize * _hitboxYOffset;

        // Add to tracked monkeys
        _monkeysOnPlatform.add(other);

        // Make platform visible when any player lands on it
        makeVisible();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Monkey) {
      final horizOffPlatform =
          other.position.x + other.size.x / 2 < position.x ||
          other.position.x - other.size.x / 2 > position.x + size.x;

      // If monkey is jumping upward, keep tracking it
      final isJumpingUp = other.velocity.y < -5;

      if (horizOffPlatform ||
          (!isJumpingUp && other.position.y > position.y + 20)) {
        _monkeysOnPlatform.remove(other);
        other.isGrounded = false;
      }
    }
    super.onCollisionEnd(other);
  }

  void syncState(String state, Map<String, dynamic>? data) {
    if (state == 'visible' && !_isVisible) {
      _isVisible = true;
      for (final sprite in _bushSprites) {
        sprite.opacity = 1;
      }
    }
  }
}
