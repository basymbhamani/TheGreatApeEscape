import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'platform.dart';
import 'vine.dart';
import 'game.dart';
import 'moving_platform.dart';
import 'mushroom.dart';
import 'bush.dart';
import 'heart.dart';
import 'spikes.dart';
import 'coin.dart';
import 'rectangular_moving_platform.dart';
import 'door.dart';
import 'cloud.dart';

class Monkey extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks, KeyboardHandler {
  final JoystickComponent? joystick;
  final double worldWidth;
  final double gameHeight;
  Vector2 velocity = Vector2.zero();
  static const double gravity = 525.0;
  bool _isGrounded = false;
  bool _isDead = false;
  bool _isBlinking = false;
  bool _isClimbing = false;
  bool _isBlockedByBush = false;
  bool _isBlockedByMonkey = false;
  Vine? _currentVine;
  PositionComponent? _currentPlatform;
  int _blinkCount = 0;
  final double _animationSpeed = 0.1;
  final double worldHeight;
  late final Vector2 _spawnPosition;
  static const int _totalBlinks = 6;
  static const double _blinkDuration = 0.2;
  double _blinkTimer = 0;
  VoidCallback? _onReset;
  static Vector2? checkpointPosition;
  
  // Static size and movement constants
  static const double monkeyWidth = 126.0;  // 84 * 1.5
  static const double monkeyHeight = 126.0;  // 84 * 1.5
  static const double hitboxWidth = 75.6;    // 50.4 * 1.5
  static const double hitboxHeight = 80;   // 25.2 * 1.5
  static const double hitboxOffsetX = 25.2;  // 16.8 * 1.5
  static const double hitboxOffsetY = 46;  // 58.8 * 1.5
  
  // Movement constants
  static const double moveSpeed = 6.0;       // Keeping current speed
  static const double jumpVelocity = -315.0; // -180 * 1.75
  static const double climbSpeed = 105.0;    // 60 * 1.75
  static const double bounceVelocity = -840.0; // -480 * 1.75
  static const double maxFallSpeed = 525.0;    // 300 * 1.75

  final String? playerId;
  final bool isRemotePlayer;
  bool _isVisible = true;
  bool _controlsEnabled = true;


  // Add a new property to track if another monkey is standing on this one
  bool _hasMonkeyOnHead = false;

  bool get isDead => _isDead;
  bool get isGrounded => _isGrounded;
  set isGrounded(bool value) => _isGrounded = value;
  bool get isVisible => _isVisible;
  set isVisible(bool value) => _isVisible = value;

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation jumpAnimation;

  Monkey(
    this.joystick,
    this.worldWidth,
    this.gameHeight, {
    this.playerId,
    this.isRemotePlayer = false,
  }) : worldHeight = gameHeight;

void enableControls() {
    _controlsEnabled = true;
  }

  void disableControls() {
    _controlsEnabled = false;
    velocity = Vector2.zero();
    animation = idleAnimation;
  }

  void setOnReset(VoidCallback callback) {
    _onReset = callback;
  }

  void reset() {
    _isDead = false;
    _isBlinking = false;
    _blinkCount = 0;
    _blinkTimer = 0;
    _isClimbing = false;
    _isBlockedByBush = false;
    _isBlockedByMonkey = false;
    _currentVine = null;
    _currentPlatform = null;
    position =
        checkpointPosition ??
        Vector2(
          200,
          worldHeight - Platform.platformSize - (worldHeight * 0.25) - 300,
        );
    opacity = 1.0;
    animation = idleAnimation;
    _onReset?.call();
  }

  void die() {
    if (!_isDead) {
      _isDead = true;
      _isBlinking = true;
      velocity = Vector2.zero();
    }
  }

  void stopMoving() {
    _isBlockedByBush = true;
    velocity.x = 0;
    animation = idleAnimation;
  }

  void stopMovingFromMonkey() {
    _isBlockedByMonkey = true;
    animation = idleAnimation;
  }

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
    scale.x = scaleX;

    // Update grounded state based on jumping
    _isGrounded = !isJumping;

    // Update animation based on state
    if (isJumping) {
      animation = jumpAnimation;
    } else if (isMoving) {
      animation = runAnimation;
    } else {
      animation = idleAnimation;
    }
  }

  void jump() {
    if (_isGrounded && !_isDead && !_hasMonkeyOnHead) {
      velocity.y = jumpVelocity;
      _isGrounded = false;
      animation = jumpAnimation;
    } else if (_hasMonkeyOnHead) {
      print("Cannot jump while another monkey is on head");
    }
  }

  void bounce(double bounceVelocity) {
    if (!_isDead) {
      velocity.y = bounceVelocity;
      _isGrounded = false;
      _currentPlatform = null;
      animation = jumpAnimation;
    }
  }

  @override
  Future<void> onLoad() async {
    final runSprites = await Future.wait(
      List.generate(
        6,
        (index) => Sprite.load('Monkeys/Monkey1/sprite_$index.png'),
      ),
    );

    final jumpSprite = await Sprite.load('Monkeys/Monkey1/sprite_jump.png');

    idleAnimation = SpriteAnimation.spriteList([runSprites[0]], stepTime: 1);
    runAnimation = SpriteAnimation.spriteList(
      runSprites,
      stepTime: _animationSpeed,
      loop: true,
    );
    jumpAnimation = SpriteAnimation.spriteList([jumpSprite], stepTime: 1);

    animation = idleAnimation;

    size = Vector2(monkeyWidth, monkeyHeight);

    final hitbox = RectangleHitbox(
      size: Vector2(hitboxWidth, hitboxHeight),
      position: Vector2(hitboxOffsetX, hitboxOffsetY),
      collisionType: CollisionType.active,
    )..debugMode = ApeEscapeGame.showHitboxes;
    add(hitbox);

    anchor = Anchor.center;

    _spawnPosition = position.clone();
    _isVisible = true;

    _isGrounded = true;
    velocity.y = 0;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Bush) {
      _isBlockedByBush = true;
    } else if (other is Mushroom) {
      velocity.y = -4200;  // -2400 * 1.75
      _isGrounded = false;
      animation = jumpAnimation;
    } else if (other is Platform && !_isDead) {
      if (position.y + size.y / 2 > other.position.y &&
          position.y + size.y / 2 < other.position.y + 20 &&
          velocity.y > 0) {
        _isGrounded = true;
        velocity.y = 0;
        position.y = other.position.y - size.y / 2;
        animation =
            (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
      }
    } else if (other is MovingPlatform && !_isDead) {
      _isGrounded = true;
      velocity.y = 0;
      position.y = other.position.y - size.y / 2;
      _currentPlatform = other;
      animation =
          (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
    } else if (other is RectangularMovingPlatform && !_isDead) {
      _isGrounded = true;
      velocity.y = 0;
      position.y = other.position.y - size.y / 2;
      _currentPlatform = other;
      animation =
          (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
    } else if (other is Cloud && !_isDead) {
      _isGrounded = true;
      velocity.y = 0;
      position.y = other.position.y - size.y / 2;
      _currentPlatform = other;
      animation =
          (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
    } else if (other is Vine) {
      _currentVine = other;
    } else if (other is Heart) {
      checkpointPosition = position.clone();
      other.collect();
    } else if (other is Spikes) {
      die();
    } else if (other is Door) {
      print("Monkey collided with door!");
    } else if (other is Monkey && !_isDead && !other.isDead) {
      // Modified monkey-to-monkey collision logic to work with the new hitbox dimensions
      
      // Calculate the bottom and top positions of both monkeys' hitboxes
      final thisHitboxBottom = position.y + hitboxOffsetY + hitboxHeight;
      final thisHitboxTop = position.y + hitboxOffsetY;
      final otherHitboxTop = other.position.y + hitboxOffsetY;
      final otherHitboxBottom = other.position.y + hitboxOffsetY + hitboxHeight;
      
      // Debug information
      print("Monkey collision detected");
      print("This monkey hitbox: top=$thisHitboxTop, bottom=$thisHitboxBottom");
      print("Other monkey hitbox: top=$otherHitboxTop, bottom=$otherHitboxBottom");
      
      // Check if this monkey is standing on the other monkey
      // Allow a small threshold for standing (10 pixels)
      if (thisHitboxBottom >= otherHitboxTop && thisHitboxBottom <= otherHitboxTop + 10 && velocity.y >= 0) {
        print("This monkey standing on other monkey");
        _isGrounded = true;
        velocity.y = 0;
        _currentPlatform = other;
        
        // Position adjustment - place this monkey's hitbox bottom exactly at other's hitbox top
        position.y = otherHitboxTop - hitboxHeight - hitboxOffsetY;
        
        animation = (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
        
        // Set the flag on the bottom monkey to indicate it has a monkey on its head
        other._hasMonkeyOnHead = true;
        print("Setting hasMonkeyOnHead=true for bottom monkey");
      } 
      // Check if other monkey is standing on this monkey
      else if (otherHitboxBottom >= thisHitboxTop && otherHitboxBottom <= thisHitboxTop + 10 && other.velocity.y >= 0) {
        print("Other monkey standing on this monkey");
        other.isGrounded = true;
        other.velocity.y = 0;
        other._currentPlatform = this;
        
        // Position adjustment - place other monkey's hitbox bottom exactly at this hitbox top
        other.position.y = thisHitboxTop - hitboxHeight - hitboxOffsetY;
        
        other.animation = (other.joystick?.delta.x.abs() ?? 0) > 0 ? other.runAnimation : other.idleAnimation;
        
        // Set the flag on this monkey to indicate it has a monkey on its head
        _hasMonkeyOnHead = true;
        print("Setting hasMonkeyOnHead=true for this monkey");
      } 
      // Horizontal collision
      else {
        // Determine horizontal direction of collision
        final thisHitboxLeft = position.x + hitboxOffsetX;
        final thisHitboxRight = position.x + hitboxOffsetX + hitboxWidth;
        final otherHitboxLeft = other.position.x + hitboxOffsetX;
        final otherHitboxRight = other.position.x + hitboxOffsetX + hitboxWidth;
        
        final dx = position.x - other.position.x;
        
        // This monkey is to the right of the other
        if (dx > 0) {
          print("This monkey colliding from right");
          stopMovingFromMonkey();
          velocity.x = 0;
          if (other.velocity.x > 0) {
            other.stopMovingFromMonkey();
            other.velocity.x = 0;
          }
        } 
        // This monkey is to the left of the other
        else {
          print("This monkey colliding from left");
          stopMovingFromMonkey();
          velocity.x = 0;
          if (other.velocity.x < 0) {
            other.stopMovingFromMonkey();
            other.velocity.x = 0;
          }
        }
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Bush) {
      _isBlockedByBush = false;
    } else if (other is Mushroom) {
      return;
    } else if (other is Platform && !_isDead) {
      _isGrounded = false;
    } else if (other is MovingPlatform && !_isDead) {
      _isGrounded = false;
      _currentPlatform = null;
    } else if (other is RectangularMovingPlatform && !_isDead) {
      _isGrounded = false;
      _currentPlatform = null;
    } else if (other is Cloud && !_isDead && other == _currentPlatform) {
      // Keep grounded state longer to bridge gaps
      Future.delayed(Duration(milliseconds: 200), () {
        if (_currentPlatform == other) {
          // Only unground if we haven't found another cloud
          if (!children.any((component) => 
              component is CollisionCallbacks && 
              component.activeCollisions.any((collision) => collision is Cloud))) {
            _isGrounded = false;
            _currentPlatform = null;
          }
        }
      });
    } else if (other is Vine && other == _currentVine) {
      _currentVine = null;
      _isClimbing = false;
    } else if (other is Monkey && !_isDead && !other.isDead) {
      _isBlockedByMonkey = false;
      if (_currentPlatform == other) {
        print("Monkey no longer standing on another monkey");
        _isGrounded = false;
        _currentPlatform = null;
        
        // Reset the flag on the bottom monkey
        other._hasMonkeyOnHead = false;
        print("Setting hasMonkeyOnHead=false for bottom monkey");
      }
      // Check if the other monkey was standing on this one
      if (other._currentPlatform == this) {
        _hasMonkeyOnHead = false;
        print("Setting hasMonkeyOnHead=false for this monkey");
      }
    }
    super.onCollisionEnd(other);
  }

  @override
  void update(double dt) {
if (!_controlsEnabled) {
      // When controls are disabled, ignore joystick input
      if (joystick != null) {
        velocity.x = 0;
      }
      return;
    }
    super.update(dt);

    if (isRemotePlayer) return;

    if (_isDead) {
      if (_isBlinking) {
        _blinkTimer += dt;
        if (_blinkTimer >= _blinkDuration) {
          _blinkTimer = 0;
          opacity = opacity == 1.0 ? 0.0 : 1.0;
          _blinkCount++;

          if (_blinkCount >= _totalBlinks) {
            _isBlinking = false;
            opacity = 0.0;
            Future.delayed(const Duration(milliseconds: 500), reset);
          }
        }
      }
      return;
    }

    final bool isMoving = (joystick?.delta.x.abs() ?? 0) > 0;
    final bool isClimbingInput =
        _currentVine != null && (joystick?.delta.y ?? 0) < 0;

    if (isClimbingInput) {
      _isClimbing = true;
      velocity.y = -climbSpeed;
      velocity.x = 0;
    } else if (_isClimbing) {
      _isClimbing = false;
      velocity.y = 0;
    }

    if (!_isClimbing) {
      if (isMoving) {
        if (!_isBlockedByBush && !_isBlockedByMonkey) {
          velocity.x = (joystick?.delta.x ?? 0) * moveSpeed;
        } else if (_isBlockedByMonkey) {
          // If we're on top of another monkey, allow movement
          if (_currentPlatform is Monkey) {
            velocity.x = (joystick?.delta.x ?? 0) * moveSpeed;
          } else {
            // If we're colliding with the side of another monkey, prevent movement in that direction
            final dx = position.x - (_currentPlatform?.position.x ?? 0);
            if (dx > 0) {
              // We're on the right side of the other monkey
              if ((joystick?.delta.x ?? 0) < 0) {
                velocity.x = 0; // Can't move left
              } else {
                velocity.x = (joystick?.delta.x ?? 0) * moveSpeed; // Can move right
              }
            } else {
              // We're on the left side of the other monkey
              if ((joystick?.delta.x ?? 0) > 0) {
                velocity.x = 0; // Can't move right
              } else {
                velocity.x = (joystick?.delta.x ?? 0) * moveSpeed; // Can move left
              }
            }
          }
        } else {
          velocity.x = 0;
        }
      } else {
        velocity.x = 0;
      }

      if (_currentPlatform != null && _isGrounded) {
        if (_currentPlatform is MovingPlatform) {
          final platform = _currentPlatform as MovingPlatform;
          position.x += platform.moveSpeed * platform.direction * dt;
          position.y = platform.position.y - size.y / 2;
        } else if (_currentPlatform is RectangularMovingPlatform) {
          final platform = _currentPlatform as RectangularMovingPlatform;
          final toTarget = platform.currentTarget - platform.position;
          if (toTarget.length > 0) {
            toTarget.normalize();
            position.x += toTarget.x * platform.moveSpeed * dt;
            position.y = platform.position.y - size.y / 2;
            velocity.y = 0;
          }
        } else if (_currentPlatform is Cloud) {
          // Ensure we stay properly positioned on clouds
          position.y = _currentPlatform!.position.y - size.y / 2;
          velocity.y = 0;
        } else if (_currentPlatform is Monkey) {
          velocity.y = 0;
        }
      }
    }

    position.x += velocity.x * dt;

    if (!_isGrounded && !_isClimbing) {
      velocity.y = (velocity.y + gravity * dt).clamp(-maxFallSpeed, maxFallSpeed);
      position.y += velocity.y * dt;
      animation = jumpAnimation;
    } else if (_currentPlatform is Monkey) {
      velocity.y = 0;
      animation = isMoving ? runAnimation : idleAnimation;
    } else {
      position.y += velocity.y * dt;
      animation = isMoving ? runAnimation : idleAnimation;
    }

    // Ensure the monkey stays within world bounds after all position updates
    position.x = position.x.clamp(0, worldWidth - size.x);

    if (position.y > worldHeight - 55) {
      die();
    }

    if ((joystick?.delta.x ?? 0) > 0) {
      scale.x = 1;
    } else if ((joystick?.delta.x ?? 0) < 0) {
      scale.x = -1;
    }
  }
}
