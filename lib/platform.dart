import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Platform extends PositionComponent with CollisionCallbacks {
  Platform(Vector2 position, Vector2 size) {
    this.position = position;
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    debugMode = false;
    add(
      RectangleHitbox()
        ..collisionType = CollisionType.passive
        ..debugMode = false,
    );
  }
}
