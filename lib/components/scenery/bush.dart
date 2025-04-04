import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../models/monkey.dart';
import '../../game.dart';

class Bush extends PositionComponent with CollisionCallbacks, HasGameRef {
  static const double bushSize = 56.0; // Same size as platform blocks
  final Vector2 startPosition;
  final int pieceCount;
  bool _isMoving = false;
  double _moveSpeed = 0;
  static const double _totalMoveTime = 5.0; // 5 seconds to move off screen

  Bush({
    required this.startPosition,
    this.pieceCount = 3, // Default to 3 pieces
  }) {
    position = startPosition;
    size = Vector2(bushSize, bushSize * pieceCount);
  }

  void startMoving() {
    if (!_isMoving) {
      _isMoving = true;
      // Calculate speed based on screen height and time
      _moveSpeed = gameRef.size.y / _totalMoveTime;
    }
  }

  void reset() {
    _isMoving = false;
    _moveSpeed = 0;
    position = startPosition.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isMoving) {
      position.y += _moveSpeed * dt;
    }
  }

  @override
  Future<void> onLoad() async {
    final bushSprite = await Sprite.load('Bush/bush_center(1).png');
    
    // Calculate actual bush height based on piece spacing
    final bushHeight = 22 + ((pieceCount - 1) * (bushSize - 25)); // Match the actual visual height

    // Add bush pieces growing downward
    for (int i = 0; i < pieceCount; i++) {
      final piece = SpriteComponent(
        sprite: bushSprite,
        position: Vector2(0, 22 + (i * (bushSize - 25))), // From 20 to 22 (down 2 pixels)
        size: Vector2.all(bushSize),
      );
      add(piece);
    }

    // Add collision hitbox that matches actual bush length
    add(RectangleHitbox(
      size: Vector2(bushSize * 0.8, bushHeight), // Use calculated bush height
      position: Vector2(bushSize * 0.1, 13), // Center the hitbox and move it down 13 pixels
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey) {
      print('Bush: Collision detected with monkey!');
      // Stop the monkey's horizontal movement
      other.stopMoving();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
} 