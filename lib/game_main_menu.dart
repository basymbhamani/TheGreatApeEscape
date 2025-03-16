import 'package:flutter/material.dart';
import 'game.dart';
import 'pre_game_lobby.dart';

class GameMainMenu extends StatelessWidget {
  const GameMainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background image
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/main_background.png"),
            fit: BoxFit.cover, // Ensures the image covers the whole screen
          ),
        ),
        child: Column(
          children: [
            // Title: MAIN MENU at the top
            const Padding(
              padding: EdgeInsets.only(top: 20), // Add padding to the top
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 90, // Very large font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // White text
                ),
              ),
            ),
            const SizedBox(height: 20), // Space between title and menu items

            // Menu Items in a scrollable column to avoid overflow
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20), // Reduced horizontal padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First Row: Story Mode and Return to Lobby
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Story Mode
                          _buildMenuOption(
                            icon: Icons.book,
                            label: 'Story Mode',
                            onTap: () {
                              // Navigate to Story Mode
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const StoryModeScreen()),
                              );
                            },
                          ),
                          // Return to Lobby
                          _buildMenuOption(
                            icon: Icons.home,
                            label: 'Return to Lobby',
                            onTap: () {
                              // Navigate to Lobby
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PreGameLobby(code: 'ABCDEF', isHost: true)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // Reduced space between rows
                      // Second Row: Settings and Leaderboard
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Settings
                          _buildMenuOption(
                            icon: Icons.settings,
                            label: 'Settings',
                            onTap: () {
                              // Navigate to Settings
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                          // Leaderboard
                          _buildMenuOption(
                            icon: Icons.leaderboard,
                            label: 'Leaderboard',
                            onTap: () {
                              // Navigate to Leaderboard
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
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

  // Helper method to build a menu option with a sign image
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
          // Jungle sign image
          Image.asset(
            'assets/images/jungle_sign.png',
            width: 350,
            height: 350, 
          ),
          // Icon and text on top of the sign
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30, // Slightly smaller icon
                color: Colors.white,
              ),
              const SizedBox(height: 4), // Reduced space between icon and text
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16, // Slightly smaller font size
                  color: Colors.white,
                ),
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
          child: Text('Story Mode', style: TextStyle(fontSize: 24, color: Colors.white)),
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
          child: Text('Settings', style: TextStyle(fontSize: 24, color: Colors.white)),
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
          child: Text('Leaderboard', style: TextStyle(fontSize: 24, color: Colors.white)),
        ),
      ),
    );
  }
}
