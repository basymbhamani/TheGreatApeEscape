import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class GameTimer extends TextComponent {
  double _elapsedTime = 0;
  bool _isRunning = true;

  GameTimer() : super(
    text: '00:00',
    textRenderer: TextPaint(
      style: const TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ) {
    position = Vector2(10, 10);
    priority = 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isRunning) {
      _elapsedTime += dt;
      text = _formatTime(_elapsedTime);
    }
  }

  String _formatTime(double time) {
    final minutes = (time ~/ 60).toString().padLeft(2, '0');
    final seconds = (time % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void pause() {
    _isRunning = false;
  }

  void start() {
    _isRunning = true;
  }

  void reset() {
    _elapsedTime = 0;
    _isRunning = true;
  }
} 