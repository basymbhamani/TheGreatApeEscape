import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'game.dart';
import 'monkey.dart';
import 'package:flame/flame.dart';

class Door extends SpriteComponent with CollisionCallbacks {
  final Function() onPlayerEnter;

  Door(Vector2 position, {required this.onPlayerEnter})
      : super(
          position: position,
          size: Vector2(220, 260),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final doorImage = await Flame.images.load('jungle_door.png');

    if (doorImage != null) {
      sprite = Sprite(doorImage);
    } else {
      print('Failed to load door image!');
    }

    final hitboxSize = Vector2(180, 200);
    final hitboxOffset = Vector2(
      (size.x - hitboxSize.x) / 2,
      size.y - hitboxSize.y,
    );

    add(
      RectangleHitbox(
        size: hitboxSize,
        position: hitboxOffset,
      )..collisionType = CollisionType.passive,
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Monkey) {
      print("Door detected collision with monkey!");
      onPlayerEnter();
    }
  }
}
