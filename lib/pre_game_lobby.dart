import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/collisions.dart';
import 'package:flame/camera.dart';
import 'monkey.dart';
import 'platform.dart';
import 'game.dart';
import 'door.dart';
import 'game_main_menu.dart';
import 'package:nakama/nakama.dart';
import 'dart:convert';

class PreGameLobby extends StatelessWidget {
  final NakamaWebsocketClient socket;
  final String code;
  final bool isHost;
  final String groupName;
  final Session session;

  PreGameLobby({
    super.key,
    required this.code,
    required this.socket,
    required this.isHost,
    required this.session,
    this.groupName = 'Group Name',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/main_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            GameWidget(
              game: LobbyGame(
                code: code,
                socket: socket,
                groupName: groupName,
                context: context,
                session: session,
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Code: $code', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Positioned(
              top: 20,
              left: 20,
              child: Text(
                'Ready: 0/1',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'APE ESCAPE',
                    style: TextStyle(fontSize: 87, fontWeight: FontWeight.bold),
                  ),
                  Transform.translate(
                    offset: Offset(0, -20),
                    child: Text(
                      'Walk in to start',
                      style: TextStyle(fontSize: 44),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LobbyGame extends ApeEscapeGame {
  final String code;
  final String groupName;
  final BuildContext context;
  final NakamaWebsocketClient socket;
  final Session session;
  static const updateRate = 1.0 / 30.0; // 30 updates per second
  double _timeSinceLastUpdate = 0.0;
  String? _ownUserId;
  late Match match;

  LobbyGame({
    required this.code,
    required this.socket,
    required this.groupName,
    required this.context,
    required this.session,
  }) : super(socket: socket, matchId: code);

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1280, 720));
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;

    // Initialize joystick
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: size.y * 0.06,
        paint: Paint()..color = const Color(0xFFAAAAAA).withOpacity(0.8),
      ),
      background: CircleComponent(
        radius: size.y * 0.12,
        paint: Paint()..color = const Color(0xFF444444).withOpacity(0.5),
      ),
      position: Vector2(size.x * 0.1, size.y * 0.7),
      priority: 2,
    );
    add(joystick);

    // Create ground platform
    final ground = Platform(
      worldWidth: 2856.0,
      height: 720.0,
      numBlocks: 28,
      startPosition: Vector2(
        0,
        gameHeight - Platform.platformSize,
      ), // Position at bottom of screen
      heightInBlocks: 2, // Make it taller to ensure good collision
    );
    add(ground);

    // Create player with adjusted starting position
    player = Monkey(
        joystick,
        2856.0, // worldWidth (same as ground width)
        720.0, // gameHeight (from viewport)
        playerId: session.userId,
        isRemotePlayer: false,
      )
      ..position = Vector2(
        400,
        gameHeight - Platform.platformSize - 100,
      ); // Position above ground
    add(player);

    // Create door
    final door = Door(
      Vector2(700, 300),
      onPlayerEnter: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => GameMainMenu(
                  matchId: code,
                  socket: socket,
                  session: session,
                ),
          ),
        );
      },
    )..priority = 2;
    add(door);

    // Get our own user ID from the session
    _ownUserId = session.userId;
    print("Own user ID: $_ownUserId");

    // Set up match state handling
    socket.onMatchData.listen(_handleMatchData);
    socket.onMatchPresence.listen(_handleMatchPresence);

    debugMode = true;
    print("LobbyGame size: ${size}");
    print("Ground position: ${ground.position}, size: ${ground.size}");
    print("Door position: ${door.position}, size: ${door.size}");
    print("Player position: ${player.position}, size: ${player.size}");
    print(
      "Joystick position: ${joystick.position}, margin: ${joystick.margin}",
    );
  }

  void _handleMatchPresence(MatchPresenceEvent event) {
    if (event.matchId != code) return;

    print(
      "Match presence event: ${event.joins.length} joins, ${event.leaves.length} leaves",
    );

    // Handle players who joined
    for (final presence in event.joins) {
      if (presence.userId != _ownUserId) {
        print("Player joined: ${presence.userId}");
        _addRemotePlayer(presence.userId);
      }
    }

    // Handle players who left
    for (final presence in event.leaves) {
      if (presence.userId != _ownUserId) {
        print("Player left: ${presence.userId}");
        _removeRemotePlayer(presence.userId);
      }
    }
  }

  void _handleMatchData(MatchData matchData) {
    if (matchData.matchId != code) return;

    try {
      final rawData = matchData.data;
      if (rawData == null) return;

      final decoded =
          jsonDecode(String.fromCharCodes(rawData)) as Map<String, dynamic>;
      final playerId = decoded['playerId'] as String;
      if (playerId == _ownUserId) return; // Skip our own updates

      print("Received update from player: $playerId");

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
      print("Adding remote player: $playerId");
      final remotePlayer = Monkey(
        null,
        2856.0, // worldWidth (same as ground width)
        720.0, // gameHeight (from viewport)
        playerId: playerId,
        isRemotePlayer: true,
      )..position = Vector2(400, 200);
      add(remotePlayer);
      remotePlayers[playerId] = remotePlayer;
    }
  }

  void _removeRemotePlayer(String playerId) {
    if (remotePlayers.containsKey(playerId)) {
      print("Removing remote player: $playerId");
      final player = remotePlayers[playerId]!;
      remove(player);
      remotePlayers.remove(playerId);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Send player state updates
    _timeSinceLastUpdate += dt;
    if (_timeSinceLastUpdate >= updateRate) {
      _sendPlayerState();
      _timeSinceLastUpdate = 0.0;
    }
  }

  void _sendPlayerState() {
    final state = {
      'playerId': _ownUserId,
      'x': player.position.x,
      'y': player.position.y,
      'isMoving': joystick.delta.x.abs() > 0,
      'isJumping': !player.isGrounded,
      'scaleX': player.scale.x,
    };

    final encodedData = utf8.encode(jsonEncode(state));
    socket.sendMatchData(matchId: code, opCode: 1, data: encodedData);
  }

  @override
  Color backgroundColor() => Colors.transparent;
}
