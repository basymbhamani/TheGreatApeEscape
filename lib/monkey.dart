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

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation jumpAnimation; // New jump animation

  Monkey(this.joystick);

  @override
  Future<void> onLoad() async {
    // Load regular sprites
    final runSprites = await Future.wait(
      List.generate(6, (index) => Sprite.load('sprites/sprite_$index.png')),
    );

    // Load jump sprite separately
    final jumpSprite = await Sprite.load('sprites/sprite_jump.png');

    // Create animations
    idleAnimation = SpriteAnimation.spriteList([runSprites[0]], stepTime: 1);

    runAnimation = SpriteAnimation.spriteList(
      runSprites,
      stepTime: _animationSpeed,
      loop: true,
    );

    // Create jump animation with single frame
    jumpAnimation = SpriteAnimation.spriteList([jumpSprite], stepTime: 1);

    // Initial animation
    animation = idleAnimation;

    size = Vector2(150, 150);
    position = Vector2(200, 200);
    add(RectangleHitbox());
    anchor = Anchor.center;
  }

  void jump() {
    if (_isGrounded) {
      velocity.y = -300;
      _isGrounded = false;
      animation = jumpAnimation; // Switch to jump animation when jumping
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Platform) {
      _isGrounded = true;
      velocity.y = 0;
      // Revert to appropriate animation when landing
      animation = joystick.delta.x.abs() > 0 ? runAnimation : idleAnimation;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final bool isMoving = joystick.delta.x.abs() > 0;

    // Only update animation if grounded
    if (_isGrounded) {
      animation = isMoving ? runAnimation : idleAnimation;
    }

    // Horizontal movement
    final horizontalMovement = Vector2(joystick.delta.x, 0);
    position.add(horizontalMovement * dt * 2);

    // Apply gravity
    if (!_isGrounded) {
      velocity.y += gravity * dt;
      position.y += velocity.y * dt;
    }

    // Keep monkey within screen bounds
    position.x = position.x.clamp(0, 1280 - size.x);
    position.y = position.y.clamp(0, 720 - size.y);

    // Update direction
    if (joystick.delta.x > 0) {
      scale.x = 1;
    } else if (joystick.delta.x < 0) {
      scale.x = -1;
    }
  }
}
