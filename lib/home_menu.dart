import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nakama/nakama.dart';
import 'host_join_screen.dart';
import 'settings_menu.dart';
import 'game.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  // Show confirmation dialog before exiting
  Future<void> _showExitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Exit Game', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to exit?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
              onPressed: () {
                SystemNavigator.pop(); // Exit the app
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Background/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title Logo with reduced height
                Image.asset(
                  'assets/images/Title_Sprite.png',
                  width: 550,
                  height: 170,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                // Start Game Button
                GestureDetector(
                  onTap: () async {
                    // Create a new client with the environment variables
                    final client = getNakamaClient(
                      host: dotenv.env['NAKAMA_HOST']!,
                      ssl: dotenv.env['NAKAMA_SSL']!.toLowerCase() == 'true',
                      serverKey: dotenv.env['NAKAMA_SERVER_KEY']!,
                      grpcPort: int.parse(dotenv.env['NAKAMA_GRPC_PORT']!),
                      httpPort: int.parse(dotenv.env['NAKAMA_HTTP_PORT']!),
                    );

                    // Create a session for the client
                    final session = await client.authenticateCustom(
                      id:
                          'unique-device-id${DateTime.now().millisecondsSinceEpoch}',
                    );

                    // Navigate to the host/join screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HostJoinScreen(
                              nakamaClient: client,
                              session: session,
                            ),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/Start_Game.png',
                    width: 490 * 0.7,
                    height: 72 * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                // Settings Button
                GestureDetector(
                  onTap: () {
                    // Create a temporary game instance for settings
                    final tempGame = ApeEscapeGame();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                SettingsMenu(game: tempGame),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/Settings_Clear.png',
                    width: 490 * 0.7,
                    height: 72 * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                // Exit Game Button
                GestureDetector(
                  onTap: () => _showExitDialog(context),
                  child: Image.asset(
                    'assets/images/Exit_Game.png',
                    width: 490 * 0.7,
                    height: 72 * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
