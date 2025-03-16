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
import 'game_main_menu.dart'; // Import the next screen

class PreGameLobby extends StatelessWidget {
  final String code;
  final bool isHost;
  final String groupName;

  const PreGameLobby({
    super.key,
    required this.code,
    required this.isHost,
    this.groupName = 'Group Name',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/main_background.png"),
            fit: BoxFit.cover, // Ensures the image covers the whole screen
          ),
        ),
        child: Stack(
          children: [
            GameWidget(
              game: LobbyGame(
                code: code,
                groupName: groupName,
                context: context, // Pass context for navigation
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Code: $code',
                    style: const TextStyle(fontSize: 16),
                  ),
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
                    offset: Offset(0, -20), // Moves the "Walk in to start" text 20 pixels up
                    child: Text(
                      'Walk in to start',
                      style: TextStyle(fontSize: 44),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LobbyGame extends ApeEscapeGame {
  final String code;
  final String groupName;
  final BuildContext context; // Context for navigation

  LobbyGame({
    required this.code,
    required this.groupName,
    required this.context,
  });

  @override
  Future<void> onLoad() async {
    // Reset camera settings for the lobby
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(1280, 720),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;
    
    // Ground (brown, with collision)
    final ground = RectangleComponent(
      position: Vector2(0, 350),
      size: Vector2(2856.0, 1280),
      paint: Paint()..color = const Color(0xFF8B4513),
      priority: 1,
    );
    ground.add(RectangleHitbox()..collisionType = CollisionType.passive);
    add(ground);

    // Door (centered on ground) with navigation callback
    final door = Door(
      Vector2(700, 155), // Position the door on the ground (adjust Y position)
      onPlayerEnter: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GameMainMenu()),
        );
      },
    )..priority = 2;
    add(door);

    // Load parent components (joystick, jump button, player)
    await super.onLoad();

    // Remove the original platform from ApeEscapeGame
    final oldPlatform = children.whereType<Platform>().firstOrNull;
    if (oldPlatform != null) {
      remove(oldPlatform);
    }


    // Debugging
    debugMode = true; // Set to true to visualize hitboxes
    print("LobbyGame size: ${size}");
    print("Ground position: ${ground.position}, size: ${ground.size}");
    print("Door position: ${door.position}, size: ${door.size}");
    print("Player position: ${player.position}, size: ${player.size}");
    print("Joystick position: ${joystick.position}, margin: ${joystick.margin}");
  }

  @override
  Color backgroundColor() => Colors.transparent;
}