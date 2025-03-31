import 'package:flutter/material.dart';
import 'game.dart';

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
                // TODO: Implement quit to menu functionality
                game.resumeGame();
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
