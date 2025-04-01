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
                isHost: isHost,
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
  final bool isHost;
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
    required this.isHost,
  }) : super(socket: socket, matchId: code);

  @override
  Future<void> onLoad() async {
    
    // Set game dimensions
    gameWidth = size.x;
    gameHeight = size.y;

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    
    // Create ground platform - position higher on the screen
    final ground = Platform(
      worldWidth: 2856.0,
      height: gameHeight,
      numBlocks: 28,
      startPosition: Vector2(
        0,
        gameHeight - Platform.platformSize, // Position higher than before
      ),
      heightInBlocks: 1,
    );
    add(ground);
    
    // Initialize joystick exactly like in game.dart
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: gameHeight * 0.06,
        paint: Paint()..color = const Color(0xFFAAAAAA).withOpacity(0.8),
      ),
      background: CircleComponent(
        radius: gameHeight * 0.12,
        paint: Paint()..color = const Color(0xFF444444).withOpacity(0.5),
      ),
      position: Vector2(gameWidth * 0.1, gameHeight * 0.7),
      priority: 2,
    );
    add(joystick);
    
    // Initialize player separately
    player = Monkey(
      joystick,
      2856.0, // worldWidth (same as ground width)
      gameHeight,
      playerId: session.userId,
      isRemotePlayer: false,
    )..position = Vector2(
      400,
      gameHeight - Platform.platformSize * 2,
    );
    add(player);

    // Add jump button exactly like in game.dart
    final jumpButton = HudButtonComponent(
      button: CircleComponent(
        radius: gameHeight * 0.12,
        paint: Paint()..color = const Color(0xFF00FF00).withOpacity(0.5),
      ),
      position: Vector2(gameWidth * 0.85, gameHeight * 0.59),
      priority: 2,
      onPressed: player.jump,
    );
    add(jumpButton);

    // Create door
    final door = Door(
      Vector2((750) - (Platform.platformSize * 4), gameHeight - Platform.platformSize * 4.5),
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
    
    // Print the lobby code for the host
    if (isHost) {
      print("Lobby Code: $code");
    }

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

      final x = decoded['x'] as double?;
      final y = decoded['y'] as double?;
      final remoteScreenHeight = (decoded['screenHeight'] as num?)?.toDouble();

      if (x == null || y == null) {
        print('Invalid position data received from $playerId');
        return;
      }
      
      // Store remote screen height and calculate offset using the inherited field
      if (remoteScreenHeight != null) {
        remoteScreenHeights[playerId] = remoteScreenHeight;
        platformYOffset = (gameHeight - remoteScreenHeight) / 2; // Use inherited field
        print('Calculated platformYOffset: $platformYOffset for player $playerId');
      } else {
         // Use existing offset or default to 0 if no height received yet for this player
         print('No screenHeight received from $playerId, using existing inherited offset: $platformYOffset');
      }
      
      // Apply offset to Y position using the inherited field
      // platformYOffset defaults to 0.0 in ApeEscapeGame, so it's safe to add directly
      final adjustedY = y + platformYOffset; 

      final isMoving = decoded['isMoving'] as bool? ?? false;
      final isJumping = decoded['isJumping'] as bool? ?? false;
      final scaleX = (decoded['scaleX'] as num?)?.toDouble() ?? 1.0;

      if (!remotePlayers.containsKey(playerId)) {
        _addRemotePlayer(playerId);
      }
      
      // Update remote player with adjusted position
      remotePlayers[playerId]!.updateRemoteState(
        Vector2(x, adjustedY),
        isMoving,
        isJumping,
        scaleX,
      );
    } catch (e, stackTrace) {
      print('Error handling match data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _addRemotePlayer(String playerId) {
    if (!remotePlayers.containsKey(playerId)) {
      print("Adding remote player: $playerId");
      final remotePlayer = Monkey(
        null,
        2856.0, // worldWidth (same as ground width)
        gameHeight,
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
    // Use inherited platformYOffset (defaults to 0.0)
    final state = {
      'playerId': _ownUserId,
      'x': player.position.x,
      'y': player.position.y - platformYOffset, // Send adjusted Y using inherited offset
      'isMoving': (joystick?.delta.x.abs() ?? 0) > 0,
      'isJumping': !player.isGrounded,
      'scaleX': player.scale.x,
      'screenHeight': gameHeight, // Send local screen height
    };

    final encodedData = utf8.encode(jsonEncode(state));
    socket.sendMatchData(matchId: code, opCode: 1, data: encodedData);
  }

  @override
  Color backgroundColor() => Colors.transparent;
}
