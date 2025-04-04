import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nakama/nakama.dart';
import 'host_join_screen.dart';

class CelebrationScreen extends StatelessWidget {
  final Session session;

  const CelebrationScreen({super.key, required this.session});

  void _navigateToHostJoin(BuildContext context) {
    // Create a new client with the environment variables
    final nakamaClient = getNakamaClient(
      host: dotenv.env['NAKAMA_HOST']!,
      ssl: dotenv.env['NAKAMA_SSL']!.toLowerCase() == 'true',
      serverKey: dotenv.env['NAKAMA_SERVER_KEY']!,
      grpcPort: int.parse(dotenv.env['NAKAMA_GRPC_PORT']!),
      httpPort: int.parse(dotenv.env['NAKAMA_HTTP_PORT']!),
    );

    // Navigate to host join screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                HostJoinScreen(nakamaClient: nakamaClient, session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToHostJoin(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LEVEL',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Monospace',
                ),
              ),
              const Text(
                'COMPLETE',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Monospace',
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/Monkeys/Monkey1/sprite_jump.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap anywhere to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
