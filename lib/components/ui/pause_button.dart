import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../game.dart';

class PauseButton extends PositionComponent
    with TapCallbacks, HasGameRef<ApeEscapeGame> {
  late final SpriteComponent pauseSprite;

  @override
  Future<void> onLoad() async {
    // Load the pause button sprite
    final sprite = await Sprite.load('pause.png');

    size = Vector2(50, 50);
    position = Vector2(gameRef.size.x - 70, 10);

    pauseSprite = SpriteComponent(sprite: sprite, size: size);
    add(pauseSprite);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    gameRef.pauseGame();
    return true;
  }
}
