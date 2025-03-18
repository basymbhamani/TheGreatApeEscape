import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'monkey.dart';
import 'platform.dart';
import 'dart:convert';

class ApeEscapeGame extends FlameGame with HasCollisionDetection {
  late final JoystickComponent joystick;
  late final Monkey player;
  static const gameWidth = 1280.0;
  static const gameHeight = 720.0;
  final NakamaWebsocketClient? socket;
  final String? matchId;
  final Map<String, Monkey> remotePlayers = {};
  static const updateRate = 1.0 / 30.0; // 30 updates per second
  double _timeSinceLastUpdate = 0.0;

  ApeEscapeGame({this.socket, this.matchId});

  @override
  Future<void> onLoad() async {
    debugMode = false;

    // Configure world bounds with adaptive viewport
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 0.7;

    // Ground platform spanning screen width
    add(Platform(Vector2(0, 400), Vector2(gameWidth, 100)));

    // Initialize joystick first - using screen percentage for positioning
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 25,
        paint: Paint()..color = const Color(0xFFAAAAAA),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF444444),
      ),
      margin: const EdgeInsets.only(left: 30, top: 225),
      priority: 1,
    );
    add(joystick);

    // Then create player after joystick is initialized
    player = Monkey(joystick, playerId: matchId)..position = Vector2(400, 200);
    add(player);

    // Jump button - positioned near monkey
    add(
      HudButtonComponent(
        button: CircleComponent(
          radius: 40,
          paint: Paint()..color = const Color(0xFF00FF00),
        ),
        position: Vector2(600, 200),
        priority: 1,
        onPressed: player.jump,
      ),
    );

    // Set up match state handling if in multiplayer mode
    if (socket != null && matchId != null) {
      socket!.onMatchData.listen(_handleMatchData);
    }
  }

  void _handleMatchData(MatchData matchData) {
    if (matchData.matchId != matchId) return;

    try {
      final rawData = matchData.data;
      if (rawData == null) return;

      final decoded =
          jsonDecode(String.fromCharCodes(rawData)) as Map<String, dynamic>;
      final playerId = decoded['playerId'] as String;
      if (playerId == matchId) return; // Skip our own updates

      final position = Vector2(decoded['x'] as double, decoded['y'] as double);
      final isMoving = decoded['isMoving'] as bool;
      final isJumping = decoded['isJumping'] as bool;
      final scaleX = decoded['scaleX'] as double;

      if (!remotePlayers.containsKey(playerId)) {
        _addRemotePlayer(playerId);
      }
      remotePlayers[playerId]!.updateRemoteState(
        position,
        isMoving,
        isJumping,
        scaleX,
      );
    } catch (e) {
      print('Error handling match data: $e');
    }
  }

  void _addRemotePlayer(String playerId) {
    if (!remotePlayers.containsKey(playerId)) {
      final remotePlayer = Monkey(
        null,
        playerId: playerId,
        isRemotePlayer: true,
      )..position = Vector2(400, 200);
      add(remotePlayer);
      remotePlayers[playerId] = remotePlayer;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Send player state updates if in multiplayer mode
    if (socket != null && matchId != null) {
      _timeSinceLastUpdate += dt;
      if (_timeSinceLastUpdate >= updateRate) {
        _sendPlayerState();
        _timeSinceLastUpdate = 0.0;
      }
    }
  }

  void _sendPlayerState() {
    if (socket == null || matchId == null) return;

    final state = {
      'playerId': matchId,
      'x': player.position.x,
      'y': player.position.y,
      'isMoving': joystick.delta.x.abs() > 0,
      'isJumping': !player.isGrounded,
      'scaleX': player.scale.x,
    };

    final encodedData = utf8.encode(jsonEncode(state));
    socket!.sendMatchData(matchId: matchId!, opCode: 1, data: encodedData);
  }

  @override
  Color backgroundColor() => Colors.transparent;
}
