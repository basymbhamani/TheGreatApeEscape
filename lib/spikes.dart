import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game.dart';
import 'monkey.dart';

class Spikes extends PositionComponent with CollisionCallbacks {
  static const double spikeSize = 56.0; // Same size as platform blocks
  static const double widthScale = 0.8; // Make spikes 80% of original width
  final Vector2 startPosition;
  final int numImages; // Number of spike images to use (each image contains 2 spikes)

  Spikes({
    required this.startPosition,
    this.numImages = 2, // Default to 2 images (4 spikes)
  }) {
    position = startPosition;
    size = Vector2(spikeSize * numImages * widthScale, spikeSize); // Adjust size based on number of images
  }

  @override
  Future<void> onLoad() async {
    final spikeSprite = await Sprite.load('Spikes/spikes.png');
    
    // Add spike images
    for (int i = 0; i < numImages; i++) {
      final spike = SpriteComponent(
        sprite: spikeSprite,
        position: Vector2(spikeSize * widthScale * i, 0),
        size: Vector2(spikeSize * widthScale, spikeSize),
      );
      add(spike);
    }

    // Add collision hitbox for all spikes
    add(RectangleHitbox(
      size: Vector2(spikeSize * numImages * widthScale, spikeSize * 0.5), // Adjusted width for all spikes
      position: Vector2(0, spikeSize * 0.5), // Position at the bottom half
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey) {
      other.die(); // Kill the monkey when it touches the spikes
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class SingleSpikes extends PositionComponent with CollisionCallbacks {
  static const double spikeSize = 56.0; // Same size as platform blocks
  static const double widthScale = 0.8; // Make spikes 80% of original width
  final Vector2 startPosition;

  SingleSpikes({
    required this.startPosition,
  }) {
    position = startPosition;
    size = Vector2(spikeSize * widthScale, spikeSize); // One spike at 80% width
  }

  @override
  Future<void> onLoad() async {
    final spikeSprite = await Sprite.load('Spikes/spikes.png');
    
    // Add single spike image (which contains two spikes)
    final spike = SpriteComponent(
      sprite: spikeSprite,
      position: Vector2(0, 0),
      size: Vector2(spikeSize * widthScale, spikeSize),
    );
    add(spike);

    // Add collision hitbox for the spikes
    add(RectangleHitbox(
      size: Vector2(spikeSize * widthScale, spikeSize * 0.5), // Adjusted width for single spike image
      position: Vector2(0, spikeSize * 0.5), // Position at the bottom half
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey) {
      other.die(); // Kill the monkey when it touches the spikes
    }
    super.onCollisionStart(intersectionPoints, other);
  }
} 