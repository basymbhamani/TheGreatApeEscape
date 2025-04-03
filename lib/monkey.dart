import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

// Custom hitbox classes to differentiate collision types
class MonkeyBodyHitbox extends RectangleHitbox {
  MonkeyBodyHitbox({required Vector2 size, required Vector2 position})
    : super(
        size: size,
        position: position,
        collisionType: CollisionType.active,
      );
}

class MonkeyFeetHitbox extends RectangleHitbox {
  MonkeyFeetHitbox({required Vector2 size, required Vector2 position})
    : super(
        size: size,
        position: position,
        collisionType: CollisionType.active,
      );
}

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

  // References to our hitboxes
  late MonkeyBodyHitbox bodyHitbox;
  late MonkeyFeetHitbox feetHitbox;

  // Static size and movement constants
  static const double monkeyWidth = 126.0; // 84 * 1.5
  static const double monkeyHeight = 126.0; // 84 * 1.5

  // Body hitbox (for monkey-to-monkey collisions)
  static const double bodyHitboxWidth = 75.6; // 50.4 * 1.5
  static const double bodyHitboxHeight = 75.0; // Taller to cover most of monkey
  static const double bodyHitboxOffsetX = 25.2; // 16.8 * 1.5
  static const double bodyHitboxOffsetY = 50; // Higher position to cover body

  // Feet hitbox (for platforms and other environmental objects)
  static const double feetHitboxWidth = 60.0; // Narrower than body
  static const double feetHitboxHeight = 15.0; // Just covers the feet
  static const double feetHitboxOffsetX = 33.0; // Centered
  static const double feetHitboxOffsetY = 110.0; // Bottom of the monkey

  // Movement constants
  static const double moveSpeed = 6.0; // Keeping current speed
  static const double jumpVelocity = -315.0; // -180 * 1.75
  static const double climbSpeed = 105.0; // 60 * 1.75
  static const double bounceVelocity = -840.0; // -480 * 1.75
  static const double maxFallSpeed = 525.0; // 300 * 1.75

  final String? playerId;
  final bool isRemotePlayer;
  bool _isVisible = true;
  bool _controlsEnabled = true;

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

    // Store previous position to check for potential collisions
    final Vector2 previousPosition = position.clone();

    // Update position and scale
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

    // Check for possible collisions with other monkeys after position update
    if (parent != null) {
      for (final component in parent!.children) {
        if (component is Monkey &&
            component != this &&
            !component.isDead &&
            !_isDead &&
            bodyHitbox.containsPoint(component.bodyHitbox.absoluteCenter)) {
          // Handle body-to-body collision
          final dx = position.x - component.position.x;

          // Adjust position to prevent overlap
          if (dx.abs() < Monkey.bodyHitboxWidth * 0.75) {
            if (dx > 0) {
              // Remote player is on the right
              position.x = component.position.x + Monkey.bodyHitboxWidth * 0.75;
            } else {
              // Remote player is on the left
              position.x = component.position.x - Monkey.bodyHitboxWidth * 0.75;
            }
          }
        }

        // Handle standing on other monkeys for remote players
        if (component is Monkey &&
            component != this &&
            !component.isDead &&
            !_isDead &&
            _isGrounded) {
          // Check if feet are positioned above another monkey
          final feetY = position.y + size.y / 2 - feetHitbox.height / 2;
          final otherMonkeyTop =
              component.position.y -
              component.size.y / 2 +
              Monkey.bodyHitboxOffsetY;
          final horizontalOverlap =
              position.x + Monkey.feetHitboxWidth / 2 >=
                  component.position.x - Monkey.bodyHitboxWidth / 2 &&
              position.x - Monkey.feetHitboxWidth / 2 <=
                  component.position.x + Monkey.bodyHitboxWidth / 2;

          if (feetY >= otherMonkeyTop - 5 &&
              feetY <= otherMonkeyTop + 10 &&
              horizontalOverlap) {
            // Position remote player correctly on top of other monkey
            position.y =
                component.position.y -
                component.bodyHitbox.height / 2 -
                size.y / 2 +
                feetHitbox.height / 2;

            _currentPlatform = component;
          }
        }
      }
    }
  }

  void jump() {
    if (_isGrounded && !_isDead) {
      velocity.y = jumpVelocity;
      _isGrounded = false;
      animation = jumpAnimation;
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

    // Create and add body hitbox (RED)
    bodyHitbox =
        MonkeyBodyHitbox(
            size: Vector2(bodyHitboxWidth, bodyHitboxHeight),
            position: Vector2(bodyHitboxOffsetX, bodyHitboxOffsetY),
          )
          ..debugMode = ApeEscapeGame.showHitboxes
          ..debugColor = Colors.red.withOpacity(
            0.5,
          ); // Semi-transparent for visibility

    // Create and add feet hitbox (GREEN)
    feetHitbox =
        MonkeyFeetHitbox(
            size: Vector2(feetHitboxWidth, feetHitboxHeight),
            position: Vector2(feetHitboxOffsetX, feetHitboxOffsetY),
          )
          ..debugMode = ApeEscapeGame.showHitboxes
          ..debugColor = Colors.green.withOpacity(
            0.5,
          ); // Semi-transparent for visibility

    // Add hitboxes after debug settings are applied
    add(bodyHitbox);
    add(feetHitbox);

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
    // Handle Body collisions (only for monkey-to-monkey)
    if (other is Monkey && !_isDead && !other.isDead) {
      final isBodyCollision =
          intersectionPoints.first.distanceTo(bodyHitbox.absoluteCenter) <
          intersectionPoints.first.distanceTo(feetHitbox.absoluteCenter);

      final isFeetCollision = !isBodyCollision;

      // Check if this is a remote-to-local player collision
      final isRemoteCollision = isRemotePlayer || other.isRemotePlayer;

      // If collision source is the body hitbox - handle horizontal blocking
      if (isBodyCollision) {
        // This is a body-to-body collision - prevent passing through
        final dx = position.x - other.position.x;
        if (dx > 0) {
          // This monkey is on the right
          stopMovingFromMonkey();
          velocity.x = 0;
          if (other.velocity.x > 0 && !other.isRemotePlayer) {
            other.stopMovingFromMonkey();
            other.velocity.x = 0;
          }
        } else {
          // This monkey is on the left
          stopMovingFromMonkey();
          velocity.x = 0;
          if (other.velocity.x < 0 && !other.isRemotePlayer) {
            other.stopMovingFromMonkey();
            other.velocity.x = 0;
          }
        }

        // If dealing with remote player, adjust position immediately to prevent overlapping
        if (isRemoteCollision) {
          if (dx > 0) {
            // This monkey is on the right of the other monkey
            position.x = other.position.x + Monkey.bodyHitboxWidth * 0.75;
          } else {
            // This monkey is on the left of the other monkey
            position.x = other.position.x - Monkey.bodyHitboxWidth * 0.75;
          }
        }
      }
      // If collision source is the feet hitbox - handle standing on top
      else if (isFeetCollision) {
        // This is a feet-to-body collision (standing on another monkey)
        if (velocity.y >= 0) {
          // Only when falling or standing
          _isGrounded = true;
          velocity.y = 0;
          _currentPlatform = other;

          // Position monkey correctly on top of other monkey
          final feetPosition = position.y + size.y / 2 - feetHitbox.height / 2;
          final otherBodyTop =
              other.position.y - other.size.y / 2 + Monkey.bodyHitboxOffsetY;

          // Only reposition if we're actually above the other monkey
          if (feetPosition <= otherBodyTop + 10) {
            position.y =
                other.position.y -
                Monkey.bodyHitboxHeight / 2 -
                size.y / 2 +
                feetHitbox.height / 2;
            animation =
                (joystick?.delta.x.abs() ?? 0) > 0
                    ? runAnimation
                    : idleAnimation;
          }
        }
      }
      return;
    }

    // Handle all other environmental collisions with feet hitbox
    if (other is Bush) {
      _isBlockedByBush = true;
    } else if (other is Mushroom) {
      velocity.y = -4200; // -2400 * 1.75
      _isGrounded = false;
      animation = jumpAnimation;
    } else if (other is Platform && !_isDead) {
      // Only ground if coming from above with downward velocity or negligible upward velocity
      if (velocity.y >= -20) {
        final feetPosition = position.y + size.y / 2 - feetHitbox.height / 2;
        if (feetPosition <= other.position.y + 10) {
          _isGrounded = true;
          velocity.y = 0;
          position.y = other.position.y - size.y / 2 + feetHitbox.height / 2;
          animation =
              (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
        }
      }
    } else if (other is MovingPlatform && !_isDead) {
      // Only ground if coming from above with downward velocity or negligible upward velocity
      if (velocity.y >= -20) {
        final feetPosition = position.y + size.y / 2 - feetHitbox.height / 2;
        if (feetPosition <= other.position.y + 10) {
          _isGrounded = true;
          velocity.y = 0;
          position.y = other.position.y - size.y / 2 + feetHitbox.height / 2;
          _currentPlatform = other;
          animation =
              (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
        }
      }
    } else if (other is RectangularMovingPlatform && !_isDead) {
      // Only ground if coming from above with downward velocity or negligible upward velocity
      if (velocity.y >= -20) {
        final feetPosition = position.y + size.y / 2 - feetHitbox.height / 2;
        if (feetPosition <= other.position.y + 10) {
          _isGrounded = true;
          velocity.y = 0;
          position.y = other.position.y - size.y / 2 + feetHitbox.height / 2;
          _currentPlatform = other;
          animation =
              (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
        }
      }
    } else if (other is Cloud && !_isDead) {
      // Only ground if coming from above with downward velocity or negligible upward velocity
      if (velocity.y >= -20) {
        final feetPosition = position.y + size.y / 2 - feetHitbox.height / 2;
        if (feetPosition <= other.position.y + 10) {
          _isGrounded = true;
          velocity.y = 0;
          position.y = other.position.y - size.y / 2 + feetHitbox.height / 2;
          _currentPlatform = other;
          animation =
              (joystick?.delta.x.abs() ?? 0) > 0 ? runAnimation : idleAnimation;
        }
      }
    } else if (other is Vine) {
      _currentVine = other;
    } else if (other is Heart) {
      checkpointPosition = position.clone();
      other.collect();
    } else if (other is Spikes) {
      die();
    } else if (other is Door) {
      print("Monkey collided with door!");
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
      // Immediately unground from clouds to prevent glitches
      _isGrounded = false;
      _currentPlatform = null;
    } else if (other is Vine && other == _currentVine) {
      _currentVine = null;
      _isClimbing = false;
    } else if (other is Monkey && !_isDead && !other.isDead) {
      // Clear blockage state for horizontal collisions
      _isBlockedByMonkey = false;

      // For remote players, additional check to make sure we don't falsely stay grounded
      if (other.isRemotePlayer && _currentPlatform == other) {
        // Only unground if we're truly no longer overlapping
        final myFeetY = position.y + size.y / 2 - feetHitbox.height / 2;
        final otherBodyTop =
            other.position.y - other.size.y / 2 + Monkey.bodyHitboxOffsetY;
        final horizontalOverlap =
            position.x + Monkey.feetHitboxWidth / 2 >=
                other.position.x - Monkey.bodyHitboxWidth / 2 &&
            position.x - Monkey.feetHitboxWidth / 2 <=
                other.position.x + Monkey.bodyHitboxWidth / 2;

        if (!horizontalOverlap || myFeetY > otherBodyTop + 15) {
          _isGrounded = false;
          _currentPlatform = null;
        }
      }
      // For local-to-local collisions, simply check platform reference
      else if (_currentPlatform == other) {
        _isGrounded = false;
        _currentPlatform = null;
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
                velocity.x =
                    (joystick?.delta.x ?? 0) * moveSpeed; // Can move right
              }
            } else {
              // We're on the left side of the other monkey
              if ((joystick?.delta.x ?? 0) > 0) {
                velocity.x = 0; // Can't move right
              } else {
                velocity.x =
                    (joystick?.delta.x ?? 0) * moveSpeed; // Can move left
              }
            }
          }
        } else {
          velocity.x = 0;
        }
      } else {
        velocity.x = 0;
      }

      // Check if we need to handle monkey-to-monkey collisions with remote players
      // that aren't being handled through the normal collision callbacks
      if (parent != null && !_isBlockedByMonkey) {
        for (final component in parent!.children) {
          if (component is Monkey &&
              component != this &&
              component.isRemotePlayer &&
              !component.isDead &&
              !_isDead) {
            // Check for body collision with remote monkey
            final dx = position.x - component.position.x;
            final hDistance = dx.abs();
            final vDistance = (position.y - component.position.y).abs();

            // If we're at similar heights (not one standing on the other)
            // and close enough horizontally, handle side collision
            if (vDistance < Monkey.bodyHitboxHeight * 0.7 &&
                hDistance < Monkey.bodyHitboxWidth * 0.8 &&
                velocity.x.sign == -dx.sign) {
              // Moving toward each other

              _isBlockedByMonkey = true;
              velocity.x = 0;
              break; // Stop checking once we've found a blocking collision
            }

            // Check if we're standing on a remote monkey
            final myFeetY =
                position.y + size.y / 2 - Monkey.feetHitboxHeight / 2;
            final otherTop =
                component.position.y -
                component.size.y / 2 +
                Monkey.bodyHitboxOffsetY;
            final horizontalOverlap =
                position.x + Monkey.feetHitboxWidth / 2 >=
                    component.position.x - Monkey.bodyHitboxWidth / 2 &&
                position.x - Monkey.feetHitboxWidth / 2 <=
                    component.position.x + Monkey.bodyHitboxWidth / 2;

            if (myFeetY >= otherTop - 5 &&
                myFeetY <= otherTop + 10 &&
                horizontalOverlap &&
                velocity.y >= 0) {
              // We're falling or standing

              _isGrounded = true;
              velocity.y = 0;
              _currentPlatform = component;

              // Position correctly on the remote monkey
              position.y =
                  component.position.y -
                  Monkey.bodyHitboxHeight / 2 -
                  size.y / 2 +
                  Monkey.feetHitboxHeight / 2;

              break;
            }
          }
        }
      }

      if (_currentPlatform != null && _isGrounded) {
        if (_currentPlatform is MovingPlatform) {
          final platform = _currentPlatform as MovingPlatform;
          position.x += platform.moveSpeed * platform.direction * dt;
          position.y = platform.position.y - size.y / 2 + feetHitbox.height / 2;
        } else if (_currentPlatform is RectangularMovingPlatform) {
          final platform = _currentPlatform as RectangularMovingPlatform;
          final toTarget = platform.currentTarget - platform.position;
          if (toTarget.length > 0) {
            toTarget.normalize();
            position.x += toTarget.x * platform.moveSpeed * dt;
            position.y =
                platform.position.y - size.y / 2 + feetHitbox.height / 2;
            velocity.y = 0;
          }
        } else if (_currentPlatform is Cloud) {
          // Ensure we stay properly positioned on clouds
          position.y =
              _currentPlatform!.position.y - size.y / 2 + feetHitbox.height / 2;
          velocity.y = 0;
        } else if (_currentPlatform is Monkey) {
          // Stay properly positioned on top of the other monkey
          final otherMonkey = _currentPlatform as Monkey;

          // If it's a remote player, ensure we use the proper positioning
          position.y =
              otherMonkey.position.y -
              Monkey.bodyHitboxHeight / 2 -
              size.y / 2 +
              feetHitbox.height / 2;

          velocity.y = 0;
        }
      }
    }

    position.x += velocity.x * dt;

    if (!_isGrounded && !_isClimbing) {
      velocity.y = (velocity.y + gravity * dt).clamp(
        -maxFallSpeed,
        maxFallSpeed,
      );
      position.y += velocity.y * dt;
      animation = jumpAnimation;
    } else if (_currentPlatform is Monkey) {
      velocity.y = 0;
      animation = isMoving ? runAnimation : idleAnimation;
    } else {
      position.y += velocity.y * dt;
      animation = isMoving ? runAnimation : idleAnimation;
    }

    // Reset blockage flag at the end of the update
    // so we check fresh next frame
    _isBlockedByMonkey = false;

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
