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
  static const gameWidth = 2856.0;
  static const gameHeight = 1280.0;

  // Nakama integration
  final NakamaBaseClient nakamaClient;
  final Session session;
  late Match match;
  late NakamaWebsocketClient socket;
  final Map<String, Monkey> opponents = {}; // Store other players

  Vector2? lastPositionSent;
  Vector2? lastVelocitySent;
  bool? lastGroundedSent;

  ApeEscapeGame(this.nakamaClient, this.session);

  @override
  Future<void> onLoad() async {
    debugMode = false;

    // Configure world bounds with adaptive viewport
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 0.7;

    // Background
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(gameWidth, gameHeight),
        paint: Paint()..color = const Color(0xFF87CEEB),
      ),
    );

    // Ground platform
    add(Platform(Vector2(0, 400), Vector2(gameWidth, 100)));

    // Joystick
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 25,
        paint: Paint()..color = const Color(0xFFAAAAAA),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF444444),
      ),
      margin: const EdgeInsets.only(left: 100, top: 200),
      priority: 1,
    );
    add(joystick);

    // Player
    player = Monkey(joystick)..position = Vector2(400, 200);
    add(player);

    // Jump button
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

    // Connect to Nakama multiplayer
    await _setupMultiplayer();
  }

  Future<void> _setupMultiplayer() async {
    try {
      // Initialize WebSocket connection
      socket = NakamaWebsocketClient.init(
        host: '127.0.0.1',
        ssl: false,
        token: session.token,
      );
      // socket.onError.listen((err) => print('WebSocket Error: $err'));
      // socket.onDone.listen((_) => print('WebSocket Closed'));

      // Define a fixed match ID for testing
      const testMatchId = 'test-match-123';

      // Try to join the match; if it fails (e.g., doesn't exist), create it
      match = await socket.joinMatch('16a2d3c7-0a89-4f53-bdd1-002b767290c8.');
      print('Joined existing match: ${match.matchId}');

      // match = await socket.createMatch();
      // print('Created new match: ${match.matchId}');

      socket.onMatchData.listen(_onMatchData);
      // print('Connected to match: ${match.matchId} with self: ${match.self.userId}');

      // Send initial player state
      _sendPlayerState();
    } catch (e) {
      print('Multiplayer setup failed: $e');
    }
  }

  void _sendPlayerState() {
    final needsUpdate =
        (lastPositionSent?.distanceTo(player.position) ?? 0) > 1.0 ||
        (lastVelocitySent?.distanceTo(player.velocity) ?? 0) > 1.0 ||
        lastGroundedSent != player.isGrounded;

    if (!needsUpdate) return;

    final data = {
      'position': {'x': player.position.x, 'y': player.position.y},
      'velocity': {'x': player.velocity.x, 'y': player.velocity.y},
      'isGrounded': player.isGrounded,
    };

    // Convert the JSON string to a List<int> using utf8.encode
    final encodedData = utf8.encode(jsonEncode(data));

    socket.sendMatchData(
      matchId: match.matchId, // Named parameter
      opCode: 1,             // Named parameter
      data: encodedData,     // Named parameter, now List<int>
    );

    lastPositionSent = player.position.clone();
    lastVelocitySent = player.velocity.clone();
    lastGroundedSent = player.isGrounded;
  }

  void _onMatchData(MatchData data) {
    final rawData = data.data;
    final userId = data.presence?.userId;

    if (rawData == null || userId == null || userId == session.userId) return;

    try {
      final decoded = jsonDecode(String.fromCharCodes(rawData)) as Map<String, dynamic>;

      final pos = decoded['position'] as Map<String, dynamic>?;
      final vel = decoded['velocity'] as Map<String, dynamic>?;
      final isGrounded = decoded['isGrounded'] as bool?;

      if (pos == null || vel == null || isGrounded == null) return;

      if (!opponents.containsKey(userId)) {
        final opponent = Monkey(null)
          ..position = Vector2(pos['x'] as double, pos['y'] as double);
        opponents[userId] = opponent;
        add(opponent);
      } else {
        final opponent = opponents[userId]!;
        opponent.position = Vector2(pos['x'] as double, pos['y'] as double);
        opponent.velocity = Vector2(vel['x'] as double, vel['y'] as double);
        opponent.isGrounded = isGrounded;
      }
    } catch (e) {
      print('Error processing match data: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sendPlayerState();
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);
}