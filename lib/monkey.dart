import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'platform.dart';

class Monkey extends SpriteAnimationComponent 
    with HasGameRef, CollisionCallbacks {
  final JoystickComponent joystick;
  Vector2 velocity = Vector2.zero();
  double gravity = 500;
  bool _isGrounded = false;
  final double _animationSpeed = 0.1;

  Monkey(this.joystick);

  @override
  Future<void> onLoad() async {
    // Load sprites directly using Sprite.load()
    final sprites = await Future.wait(
      List.generate(26, (index) => Sprite.load('sprites/sprite_$index.png')),
    );

    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: _animationSpeed,
      loop: true,
    );

    size = Vector2(150, 150);
    position = Vector2(200, 200);
    add(RectangleHitbox());
    anchor = Anchor.center;
  }

  // Rest of the class remains unchanged
  void jump() {
    if (_isGrounded) {
      velocity.y = -300;
      _isGrounded = false;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is Platform) {
      _isGrounded = true;
      velocity.y = 0;
    }
    super.onCollisionStart(points, other);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    final horizontalMovement = Vector2(joystick.delta.x, 0);
    position.add(horizontalMovement * dt * 2);

    if (!_isGrounded) {
      velocity.y += gravity * dt;
      position.y += velocity.y * dt;
    }

    if (joystick.delta.x > 0) {
      scale.x = 1;
    } else if (joystick.delta.x < 0) {
      scale.x = -1;
    }
  }
}