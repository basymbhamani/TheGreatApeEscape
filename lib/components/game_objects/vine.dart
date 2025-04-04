import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game.dart';

class Vine extends PositionComponent with CollisionCallbacks {
  final int pieceCount;
  static const double pieceSize = 56.0; // Same size as platform blocks
  static const double hitboxWidth = 10.0; // Reduced width of the climbable area (from 20 to 10)

  Vine({
    required this.pieceCount,
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2(pieceSize, pieceSize * pieceCount);
  }

  @override
  Future<void> onLoad() async {
    // Load vine pieces
    final vinePiece = await Sprite.load('Vine/vine_piece.png');
    final vineTop = await Sprite.load('Vine/vine_top.png');

    // Add the top piece first
    final top = SpriteComponent(
      sprite: vineTop,
      position: Vector2(-2, -3), // Shifted 2 pixels left
      size: Vector2.all(pieceSize),
    );
    add(top);

    // Calculate actual vine height based on piece spacing
    final vineHeight = 22 + ((pieceCount - 1) * (pieceSize - 25)); // Match the actual visual height

    // Add the main vine pieces growing downward
    for (int i = 0; i < pieceCount - 1; i++) {
      final piece = SpriteComponent(
        sprite: vinePiece,
        position: Vector2(0, 22 + (i * (pieceSize - 25))), // From 20 to 22 (down 2 pixels)
        size: Vector2.all(pieceSize),
      );
      add(piece);
    }

    // Add collision hitbox for climbing that matches actual vine length
    add(RectangleHitbox(
      size: Vector2(hitboxWidth, vineHeight), // Use calculated vine height instead of total size
      position: Vector2((pieceSize - hitboxWidth) / 2, 13), // Center the hitbox and move it down 13 pixels
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }
} 