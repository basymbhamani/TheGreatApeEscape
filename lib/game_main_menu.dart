import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart'; // Add this for NakamaWebsocketClient
import 'game.dart';
import 'pre_game_lobby.dart';

class GameMainMenu extends StatelessWidget {
  final String matchId; // Match ID from Nakama or elsewhere
  final NakamaWebsocketClient socket; // WebSocket client for Nakama
  final Session session; // Add session parameter

  const GameMainMenu({
    super.key,
    required this.matchId,
    required this.socket,
    required this.session, // Add session to constructor
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
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMenuOption(
                            icon: Icons.book,
                            label: 'Story Mode',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StoryModeScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuOption(
                            icon: Icons.home,
                            label: 'Return to Lobby',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PreGameLobby(
                                        code: matchId,
                                        socket: socket,
                                        isHost: true,
                                        session: session,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMenuOption(
                            icon: Icons.settings,
                            label: 'Settings',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuOption(
                            icon: Icons.leaderboard,
                            label: 'Leaderboard',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const LeaderboardScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/images/jungle_sign.png', width: 350, height: 350),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StoryModeScreen extends StatelessWidget {
  const StoryModeScreen({super.key});

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
        child: const Center(
          child: Text(
            'Story Mode',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        child: const Center(
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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
        child: const Center(
          child: Text(
            'Leaderboard',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
