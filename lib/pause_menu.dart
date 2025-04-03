import 'package:flutter/material.dart';
import 'game.dart';
import 'host_join_screen.dart';
import 'package:nakama/nakama.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PauseMenu extends StatelessWidget {
  final ApeEscapeGame game;

  const PauseMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageButton(
              imagePath: 'assets/images/RESUME.png',
              onPressed: () => game.resumeGame(),
            ),
            _buildImageButton(
              imagePath: 'assets/images/RESTART.png',
              onPressed: () {
                game.resetLevel();
                game.sendRestartSignal();
              },
            ),
            _buildImageButton(
              imagePath: 'assets/images/settings.png',
              onPressed: () {
                // TODO: Implement settings to menu functionality
                game.resumeGame();
              },
            ),
            _buildImageButton(
              imagePath: 'assets/images/RETURN.png',
              onPressed: () {
                // Send return to menu signal to other player
                if (game.socket != null &&
                    game.matchId != null &&
                    game.session != null) {
                  final data = {
                    'playerId': game.session!.userId,
                    'type': 'return_to_menu',
                  };

                  game.socket!.sendMatchData(
                    matchId: game.matchId!,
                    opCode: 2,
                    data: List<int>.from(utf8.encode(jsonEncode(data))),
                  );
                }

                // Navigate back to host join screen
                Navigator.of(context).popUntil((route) => route.isFirst);

                if (game.session != null) {
                  // Get the client from the current session
                  final Session session = game.session!;

                  // Use a slight delay to ensure the message is sent before disconnecting
                  Future.delayed(const Duration(milliseconds: 100), () {
                    // Create a new client with the environment variables
                    final nakamaClient = getNakamaClient(
                      host: dotenv.env['NAKAMA_HOST']!,
                      ssl: dotenv.env['NAKAMA_SSL']!.toLowerCase() == 'true',
                      serverKey: dotenv.env['NAKAMA_SERVER_KEY']!,
                      grpcPort: int.parse(dotenv.env['NAKAMA_GRPC_PORT']!),
                      httpPort: int.parse(dotenv.env['NAKAMA_HTTP_PORT']!),
                    );

                    // Push the HostJoinScreen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HostJoinScreen(
                              nakamaClient: nakamaClient,
                              session: session,
                            ),
                      ),
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton({
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          imagePath,
          width: 490 * 0.7, // Larger image size
          height: 72 * 0.7, // Larger image size
          fit: BoxFit.contain,
        ),
        SizedBox(
          width: 490 * 0.7, // Smaller clickable area
          height: 68 * 0.7, // Smaller clickable area
          child: GestureDetector(
            onTap: onPressed,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
