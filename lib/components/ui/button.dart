import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../models/monkey.dart';
import '../../game.dart';
import '../scenery/bush.dart';

class Button extends PositionComponent with CollisionCallbacks {
  static const double buttonSize = 56.0; // Same size as platform blocks
  final Vector2 startPosition;
  bool _isEnabled = false;
  late SpriteComponent buttonSprite;
  Bush? _targetBush;

  Button({
    required this.startPosition,
    Bush? targetBush,
  }) {
    position = startPosition;
    size = Vector2(buttonSize, buttonSize);
    _targetBush = targetBush;
  }

  void reset() {
    _isEnabled = false;
    // Update the sprite to disabled state
    final buttonSprites = children.whereType<ButtonSprites>().first;
    buttonSprites.updateSprite(false);
    buttonSprite.sprite = buttonSprites.currentSprite.sprite;
    
    // Reset the target bush if it exists
    _targetBush?.reset();
  }

  @override
  Future<void> onLoad() async {
    final disabledSprite = await Sprite.load('Button/button_disabled.png');
    final enabledSprite = await Sprite.load('Button/button_enabled.png');
    
    buttonSprite = SpriteComponent(
      sprite: disabledSprite,
      size: Vector2(buttonSize, buttonSize),
    );
    add(buttonSprite);

    // Add collision hitbox
    add(RectangleHitbox(
      size: Vector2(buttonSize * 0.4, buttonSize * 0.2), // Keep width at 0.4, height at 0.2
      position: Vector2(buttonSize * 0.3, buttonSize * 0.5), // Move hitbox slightly lower (from 0.45 to 0.5 for Y)
      collisionType: CollisionType.passive,
    )..debugMode = ApeEscapeGame.showHitboxes);

    // Store sprites for later use
    add(ButtonSprites(disabledSprite, enabledSprite));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Monkey && !_isEnabled) {
      _isEnabled = true;
      // Update the sprite to enabled state
      final buttonSprites = children.whereType<ButtonSprites>().first;
      buttonSprites.updateSprite(true);
      buttonSprite.sprite = buttonSprites.currentSprite.sprite;
      
      // Start moving the target bush if it exists
      _targetBush?.startMoving();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class ButtonSprites extends Component {
  final Sprite disabledSprite;
  final Sprite enabledSprite;
  late SpriteComponent currentSprite;

  ButtonSprites(this.disabledSprite, this.enabledSprite) {
    currentSprite = SpriteComponent(
      sprite: disabledSprite,
      size: Vector2(56.0, 56.0),
    );
  }

  void updateSprite(bool enabled) {
    currentSprite.sprite = enabled ? enabledSprite : disabledSprite;
  }
} 