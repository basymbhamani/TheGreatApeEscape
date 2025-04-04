import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart'; // Add this for NakamaWebsocketClient
import 'package:flame/game.dart';
import 'game.dart';
import 'pre_game_lobby.dart';
import 'dart:convert';
import 'settings_menu.dart';

class GameMainMenu extends StatefulWidget {
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
  State<GameMainMenu> createState() => _GameMainMenuState();
}

class _GameMainMenuState extends State<GameMainMenu> {
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
          fit: StackFit.expand,
          children: [
            // Title at the top center
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 0.0,
                ), // Reduced top padding from 40.0
                child: Text(
                  'MAIN MENU',
                  style: TextStyle(
                    fontSize: 75,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // Story Mode button at top left
            Positioned(
              top: 25.0,
              left: 150.0,
              child: _buildMenuOption(
                icon: Icons.book,
                label: 'Story Mode',
                onTap: () async {
                  // Create a new match for the game level
                  final newMatch = await widget.socket.createMatch();

                  // Send the new match ID to all players
                  widget.socket.sendMatchData(
                    matchId: widget.matchId,
                    opCode: 2,
                    data: utf8.encode(
                      jsonEncode({
                        'newMatchId': newMatch.matchId,
                        'initiator': widget.session.userId,
                      }),
                    ),
                  );

                  // Join the new match and start the game
                  await widget.socket.joinMatch(newMatch.matchId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => GameWidget(
                            game: ApeEscapeGame(
                              socket: widget.socket,
                              matchId: newMatch.matchId,
                              session: widget.session,
                            ),
                            backgroundBuilder:
                                (context) =>
                                    Container(color: const Color(0xFF87CEEB)),
                          ),
                    ),
                  );
                },
              ),
            ),

            // Return to Lobby button at top right
            Positioned(
              top: 25.0,
              right: 150.0,
              child: _buildMenuOption(
                icon: Icons.home,
                label: 'Return to Lobby',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PreGameLobby(
                            code: widget.matchId,
                            socket: widget.socket,
                            isHost: true,
                            session: widget.session,
                          ),
                    ),
                  );
                },
              ),
            ),

            // Settings button at bottom left
            Positioned(
              bottom: -50.0,
              left: 150.0,
              child: _buildMenuOption(
                icon: Icons.settings,
                label: 'Settings',
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
              ),
            ),

            // Leaderboard button at bottom right (greyed out)
            Positioned(
              bottom: -50.0,
              right: 150.0,
              child: _buildMenuOption(
                icon: Icons.leaderboard,
                label: 'Leaderboard',
                onTap: () {
                  // Do nothing - leaderboard is disabled
                },
                isDisabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    widget.socket.onMatchData.listen((state) {
      if (state.matchId == widget.matchId && state.opCode == 2) {
        try {
          final data =
              jsonDecode(String.fromCharCodes(state.data ?? []))
                  as Map<String, dynamic>;
          final newMatchId = data['newMatchId'] as String?;
          final initiatorId = data['initiator'] as String?;

          if (newMatchId != null &&
              initiatorId != null &&
              initiatorId != widget.session.userId) {
            // Join the new match and start the game
            widget.socket.joinMatch(newMatchId).then((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => GameWidget(
                        game: ApeEscapeGame(
                          socket: widget.socket,
                          matchId: newMatchId,
                          session: widget.session,
                        ),
                        backgroundBuilder:
                            (context) =>
                                Container(color: const Color(0xFF87CEEB)),
                      ),
                ),
              );
            });
          }
        } catch (e) {
          print('Error processing match data: $e');
        }
      }
    });
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.matrix(
              isDisabled
                  ? [
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]
                  : [
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ],
            ),
            child: Image.asset(
              'assets/images/jungle_sign.png',
              width: 250,
              height: 250,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: isDisabled ? Colors.grey : Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isDisabled ? Colors.grey : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
