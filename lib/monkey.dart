import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' show lerpDouble;
import 'platform.dart';

class Monkey extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  final JoystickComponent joystick;
  Vector2 velocity = Vector2.zero();
  double gravity = 500;
  bool _isGrounded = false;
  final double _animationSpeed = 0.1;
  final double screenWidth;
  final double screenHeight;

  // Movement constants
  static const double moveSpeed = 0.00005; // Further reduced movement speed

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation jumpAnimation;

  Monkey(this.joystick, this.screenWidth, this.screenHeight);

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
    jumpAnimation = SpriteAnimation.spriteList([jumpSprite], stepTime: 1);

    // Initial animation
    animation = idleAnimation;

    // Size relative to screen height
    size = Vector2(screenHeight * 0.3, screenHeight * 0.3);
    add(RectangleHitbox());
    anchor = Anchor.center;

    // Adjust gravity and jump velocity based on screen size
    gravity = screenHeight * 1.2; // Scale gravity with screen height
  }

  void jump() {
    if (_isGrounded) {
      velocity.y = -screenHeight * 0.7; // Slightly lower jump
      _isGrounded = false;
      animation = jumpAnimation;
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

    // Direct horizontal movement without smoothing
    if (isMoving) {
      velocity.x = joystick.delta.x * screenWidth * moveSpeed;
    } else {
      velocity.x = 0; // Immediate stop when joystick is released
    }
    position.x += velocity.x;

    // Apply gravity
    if (!_isGrounded) {
      velocity.y += gravity * dt;
      position.y += velocity.y * dt;
    }

    // Keep monkey within screen bounds
    position.x = position.x.clamp(0, screenWidth - size.x);
    position.y = position.y.clamp(0, screenHeight - size.y);

    // Update direction
    if (joystick.delta.x > 0) {
      scale.x = 1;
    } else if (joystick.delta.x < 0) {
      scale.x = -1;
    }
  }
}
