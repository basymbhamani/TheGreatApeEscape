import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'platform.dart';
import 'door.dart'; // Import Door for type checking

class Monkey extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  final JoystickComponent?
  joystick; // Make joystick optional for remote players
  Vector2 velocity = Vector2.zero();
  double gravity = 500;
  bool _isGrounded = false;
  final double _animationSpeed = 0.1;
  final String? playerId; // Add player ID for multiplayer
  bool isRemotePlayer; // Flag to identify remote players
  bool _isVisible = true;

  // Public setter for _isGrounded
  set isGrounded(bool value) {
    _isGrounded = value;
  }

  // Public getter for _isGrounded (optional, if needed elsewhere)
  bool get isGrounded => _isGrounded;
  bool get isVisible => _isVisible;

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation jumpAnimation;

  Monkey(this.joystick, {this.playerId, this.isRemotePlayer = false});

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

    size = Vector2(150, 150);
    position = Vector2(400, 200); // Start at a consistent position
    add(RectangleHitbox());
    anchor = Anchor.center;

    // Set initial visibility
    _isVisible = true;
  }

  void jump() {
    if (_isGrounded) {
      velocity.y = -300;
      _isGrounded = false;
      animation = jumpAnimation;
    }
  }

  // Method to update remote player state
  void updateRemoteState(
    Vector2 newPosition,
    bool isMoving,
    bool isJumping,
    double scaleX,
  ) {
    if (!_isVisible) {
      _isVisible = true;
    }

    position = newPosition;
    if (isJumping) {
      animation = jumpAnimation;
    } else {
      animation = isMoving ? runAnimation : idleAnimation;
    }
    scale.x = scaleX;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Platform || other is RectangleComponent && !(other is Door)) {
      // Check if the player is landing on top of a platform or ground
      if (velocity.y > 0 && intersectionPoints.first.y >= other.position.y) {
        _isGrounded = true;
        velocity.y = 0;
        position.y = other.position.y - size.y / 2; // Stand on top
        if (joystick != null) {
          animation =
              joystick!.delta.x.abs() > 0 ? runAnimation : idleAnimation;
        }
      }
    } else if (other is Door) {
      // Door collision handled by Door.dart, no position adjustment needed
      print("Monkey collided with door!"); // Debug
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only update if this is the local player
    if (!isRemotePlayer && joystick != null) {
      final bool isMoving = joystick!.delta.x.abs() > 0;

      if (_isGrounded) {
        animation = isMoving ? runAnimation : idleAnimation;
      }

      // Horizontal movement
      final horizontalMovement = Vector2(joystick!.delta.x, 0);
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
      if (joystick!.delta.x > 0) {
        scale.x = 1;
      } else if (joystick!.delta.x < 0) {
        scale.x = -1;
      }
    }
  }
}
