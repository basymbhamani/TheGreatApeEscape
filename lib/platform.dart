import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Platform extends PositionComponent with CollisionCallbacks {
  Platform(Vector2 position, Vector2 size) {
    this.position = position;
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    debugMode = false; // Set to `true` to visualize collision hitboxes
  }
}
