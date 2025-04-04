import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nakama/nakama.dart';
import 'dart:ui' show lerpDouble;
import 'monkey.dart';
import 'platform.dart';
import 'vine.dart';
import 'moving_platform.dart';
import 'mushroom.dart';
import 'spikes.dart';
import 'cloud.dart';
import 'game_block.dart';
import 'button.dart';
import 'bush.dart';
import 'heart.dart';
import 'bush_platform.dart';
import 'tree_block.dart';
import 'tree.dart';
import 'coin.dart';
import 'rectangular_moving_platform.dart';
import 'timer_component.dart';
import 'door.dart';
import 'dart:convert';
import 'pause_menu.dart';
import 'pause_button.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'host_join_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_manager.dart';

class ApeEscapeGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  late final JoystickComponent joystick;
  late final Monkey player;
  double gameWidth = 720;
  double gameHeight = 720;
  late final PositionComponent gameLayer;
  GameTimer timer = GameTimer();
  final NakamaWebsocketClient? socket;
  final String? matchId;
  final Session? session;
  final Map<String, Monkey> remotePlayers = {};
  static const updateRate = 1.0 / 60.0; // 30 updates per second
  double _timeSinceLastUpdate = 0.0;
  bool _isPaused = false;
  double _soundVolume = 0.5;
  bool _invertControls = false;

  // Platform height offset for different screen sizes
  double platformYOffset = 0.0;

  // Map to store other players' screen heights
  final Map<String, double> remoteScreenHeights = {};

  // Debug mode
  static bool showHitboxes = true;

  // World boundaries
  static const worldWidth = 8500.0;

  // Camera window settings
  static const double cameraWindowMarginRatio = 0.4;

  // Audio manager
  final _audioManager = AudioManager();

  double get soundVolume => _soundVolume;
  bool get invertControls => _invertControls;

  void setSoundVolume(double volume) {
    _soundVolume = volume;
    _audioManager.setVolume(volume);
  }

  void setInvertControls(bool inverted) {
    _invertControls = inverted;
    // TODO: Invert Controls
  }

  // Camera smoothing factor (lower = smoother but slower)
  static const double cameraSmoothingFactor = 0.05;

  // Target camera position - initialized to null to indicate it hasn't been set yet
  double? _targetCameraX;

  ApeEscapeGame({this.socket, this.matchId, this.session}) {
    gameLayer = PositionComponent();
    add(gameLayer);
  }

  @override
  Future<void> onLoad() async {
    // Preload images
    await images.load('jump_button.png');

    // Get actual screen dimensions
    gameWidth = size.x;
    gameHeight = size.y;

    // Print device screen dimensions for debugging
    print('Device screen dimensions: $gameWidth x $gameHeight');

    // Set up camera and viewport
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.zoom = 1.0;

    add(PauseButton());

    // Add timer to HUD
    add(timer);

    // Background image
    final background = SpriteComponent(
      sprite: await Sprite.load('Background/background.png'),
      position: Vector2.zero(),
      size: Vector2(worldWidth, gameHeight),
    );
    gameLayer.add(background);

    // Ground platform
    final groundPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 6,
      startPosition: Vector2(0, gameHeight - Platform.platformSize),
      heightInBlocks: 1,
    );
    gameLayer.add(groundPlatform);

    // Add vine
    final vine = Vine(
      pieceCount: 8,
      position: Vector2(
        Platform.platformSize * 8 + 90,
        gameHeight - Platform.platformSize * 5.4,
      ),
    );
    gameLayer.add(vine);

    // Higher platform after gap
    final higherPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 3,
      startPosition: Vector2(
        Platform.platformSize * 8,
        gameHeight - Platform.platformSize * 2,
      ),
      heightInBlocks: 2,
    );
    gameLayer.add(higherPlatform);

    // Top platform above vine
    final topPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 6,
      startPosition: Vector2(
        Platform.platformSize * 8,
        gameHeight - Platform.platformSize * 5.4 + 10,
      ),
      heightInBlocks: 1,
    );
    gameLayer.add(topPlatform);

    // Add moving platform
    final movingPlatform = MovingPlatform(
      worldWidth: worldWidth,
      worldHeight: gameHeight,
      startPosition: Vector2(
        Platform.platformSize * 15,
        gameHeight - Platform.platformSize * 2,
      ),
      moveDistance: Platform.platformSize * 4,
      moveSpeed: 80,
    );
    gameLayer.add(movingPlatform);

    // Add new platform after moving platform
    final afterMovingPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 8,
      startPosition: Vector2(
        Platform.platformSize * 22,
        gameHeight - Platform.platformSize * 2,
      ),
      heightInBlocks: 2,
    );
    gameLayer.add(afterMovingPlatform);

    // Add spikes on the platform
    final spikes = Spikes(
      startPosition: Vector2(
        Platform.platformSize * (22 + 4),
        gameHeight - Platform.platformSize * 3,
      ),
      numImages: 2,
    );
    gameLayer.add(spikes);

    // Add bouncy mushroom after the last platform
    final mushroom = Mushroom(
      worldWidth: worldWidth,
      height: gameHeight,
      startPosition: Vector2(
        Platform.platformSize * (22 + 8 + 3),
        gameHeight - Platform.platformSize,
      ),
    );
    gameLayer.add(mushroom);

    // Add tall platform after mushroom
    final tallPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 1,
      startPosition: Vector2(
        Platform.platformSize * (22 + 8 + 7),
        gameHeight - Platform.platformSize * 5,
      ),
      heightInBlocks: 5,
    );
    gameLayer.add(tallPlatform);

    // Add spikes on top of tall platform
    final tallPlatformSpikes = Spikes(
      startPosition: Vector2(
        Platform.platformSize * (22 + 8 + 7),
        gameHeight - Platform.platformSize * 6,
      ),
      numImages: 1,
    );
    gameLayer.add(tallPlatformSpikes);

    // Add wide platform after gap
    final widePlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 4,
      startPosition: Vector2(
        Platform.platformSize * (22 + 8 + 10),
        gameHeight - Platform.platformSize * 2,
      ),
      heightInBlocks: 2,
    );
    gameLayer.add(widePlatform);

    // Add a row of clouds after the wide platform
    final cloudStartX = Platform.platformSize * (22 + 8 + 15);
    final cloudY = gameHeight - Platform.platformSize * 3;
    final cloudSpacing = Platform.platformSize * 3.5;

    // Replace horizontal cloud row with a staircase pattern
    // Creating 3 clouds that ascend toward the blocks (removed last 2 clouds)
    for (int i = 0; i < 3; i++) {
      final cloudX =
          cloudStartX + (cloudSpacing * i * 0.6); // Tighten horizontal spacing
      final stepHeight =
          i *
          Platform.platformSize *
          0.7; // Each cloud is higher than the previous one

      final cloud = Cloud(
        worldWidth: worldWidth,
        height: gameHeight,
        startPosition: Vector2(
          cloudX,
          cloudY - stepHeight,
        ), // Progressively higher Y position
        numBlocks: i < 2 ? 3 : 2, // Slightly smaller clouds as we go up
      );
      gameLayer.add(cloud);
    }

    // Calculate position based on the third cloud
    final thirdCloudX = cloudStartX + (cloudSpacing * 2 * 0.6);
    final thirdCloudY = cloudY - (2 * Platform.platformSize * 0.7);

    // Define block height
    final blockHeight = gameHeight * 0.25;

    // Position blocks one block to the right and one block higher than third cloud
    // Also add 100 pixels to the right and make them lower
    final blocksX = thirdCloudX + Platform.platformSize + 100;
    final blocksY = thirdCloudY - Platform.platformSize - blockHeight + 150;

    // Add single block group
    final blocks = GameBlock(startPosition: Vector2(blocksX, blocksY));
    gameLayer.add(blocks);

    // Add bush near the top of the screen
    final bush = Bush(
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 5) + 100,
        gameHeight * 0.3 - (Platform.platformSize * 3),
      ),
      pieceCount: 13,
    );
    gameLayer.add(bush);

    // Add platform near the bush
    final heartPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 5,
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 9),
        gameHeight - Platform.platformSize * 2,
      ),
      heightInBlocks: 2,
    );
    gameLayer.add(heartPlatform);

    // Add heart on top of the platform
    final heart = Heart(
      position: Vector2(
        blocksX + (Platform.platformSize * 11),
        gameHeight - Platform.platformSize * 3,
      ),
    );
    gameLayer.add(heart);

    // Add bush platform after the heart
    final bushPlatform = BushPlatform(
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 16),
        gameHeight - Platform.platformSize * 2,
      ),
      numBlocks: 5,
      height: 1,
    );
    gameLayer.add(bushPlatform);

    // Add first tree block
    final treeBlock = TreeBlock(
      position: Vector2(
        blocksX + (Platform.platformSize * 21),
        gameHeight - Platform.platformSize * 4,
      ),
    );
    gameLayer.add(treeBlock);

    // Add decorative tree
    final tree = Tree(
      position: Vector2(
        blocksX + (Platform.platformSize * 25),
        gameHeight - Platform.platformSize * 4,
      ),
    );
    gameLayer.add(tree);

    // Add second tree block
    final treeBlock2 = TreeBlock(
      position: Vector2(
        blocksX + (Platform.platformSize * 37),
        gameHeight - Platform.platformSize * 2.5,
      ),
    );
    gameLayer.add(treeBlock2);

    // Add right-moving bush platform
    final movingRightBushPlatform = BushPlatform(
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 45),
        gameHeight - Platform.platformSize * 3.5,
      ),
      numBlocks: 3,
      moveRight: true,
    );
    gameLayer.add(movingRightBushPlatform);

    // Add wide platform after the moving right bush platform
    final widePlatformAfterBush = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: 6,
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 55),
        gameHeight - Platform.platformSize * 3.5,
      ),
      heightInBlocks: 2,
    );
    gameLayer.add(widePlatformAfterBush);

    // Add rectangular moving platform
    final rectangularPlatform = RectangularMovingPlatform(
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 65),
        gameHeight - Platform.platformSize * 4,
      ),
      width: Platform.platformSize * 4,
      height: Platform.platformSize * 3,
      moveSpeed: 80,
      numBlocks: 5,
    );
    gameLayer.add(rectangularPlatform);

    // Add floating mushroom platform above the rectangular platform's path
    final floatingMushroom = Mushroom(
      worldWidth: worldWidth,
      height: gameHeight,
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 67),
        gameHeight - Platform.platformSize * 8,
      ),
    );
    gameLayer.add(floatingMushroom);

    // Create the bush immediately but don't start moving it yet
    final puzzleBush = Bush(
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 75),
        gameHeight * 0.3,
      ),
      pieceCount: 13,
    );
    gameLayer.add(puzzleBush);

    // Add vertically moving platform after the bush
    final verticalMovingPlatform = BushPlatform(
      startPosition: Vector2(
        blocksX + (Platform.platformSize * 82),
        gameHeight - Platform.platformSize * 4,
      ),
      numBlocks: 5,
      height: 1,
      moveRight: false,
    );
    gameLayer.add(verticalMovingPlatform);

    // Add final platform at the end of the level
    final finalPlatformStartX = blocksX + (Platform.platformSize * 90);
    final remainingDistance = worldWidth - finalPlatformStartX;
    final numBlocksNeeded = (remainingDistance / Platform.platformSize).ceil();

    final finalPlatform = Platform(
      worldWidth: worldWidth,
      height: gameHeight,
      numBlocks: numBlocksNeeded,
      startPosition: Vector2(
        finalPlatformStartX,
        gameHeight - Platform.platformSize * 12,
      ),
      heightInBlocks: 2,
    );
    gameLayer.add(finalPlatform);

    // Add door at the end of the final platform
    final door = Door(
      Vector2(
        worldWidth - Platform.platformSize * 4,
        gameHeight - Platform.platformSize * 14,
      ),
      onPlayerEnter: () {},
    );
    gameLayer.add(door);

    // Add coins around the rectangular platform
    int coinsCollected = 0;
    final totalCoins = 4;
    final coinPositions = [
      Vector2(
        blocksX + (Platform.platformSize * 67),
        gameHeight - Platform.platformSize * 6,
      ),
      Vector2(
        blocksX + (Platform.platformSize * 71),
        gameHeight - Platform.platformSize * 4,
      ),
      Vector2(
        blocksX + (Platform.platformSize * 67),
        gameHeight - Platform.platformSize * 2,
      ),
      Vector2(
        blocksX + (Platform.platformSize * 63),
        gameHeight - Platform.platformSize * 4,
      ),
    ];

    // Add coins
    for (final coinPos in coinPositions) {
      final coin = Coin(
        position: coinPos,
        onCollected: () {
          coinsCollected++;
          if (coinsCollected >= totalCoins) {
            puzzleBush.startMoving();
          }
        },
      );
      gameLayer.add(coin);
    }

    // Add button on top of second block
    final button = Button(
      startPosition: Vector2(
        blocksX + Platform.platformSize * 0.5 + 80,
        blocksY - Button.buttonSize,
      ),
      targetBush: bush,
    );
    gameLayer.add(button);

    // Initialize joystick
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

    // Create player
    player =
        Monkey(joystick, worldWidth, gameHeight)
          ..position = Vector2(200, gameHeight - Platform.platformSize * 2)
          ..priority = 2;
    gameLayer.add(player);

    // Process update from remote player
    if (socket != null && matchId != null && session != null) {
      socket!.onMatchData.listen((event) {
        if (event.matchId == matchId) {
          try {
            final rawData = event.data;
            if (rawData == null) {
              print('Received null raw data');
              return;
            }

            final data =
                jsonDecode(String.fromCharCodes(rawData))
                    as Map<String, dynamic>;
            print('Raw data received: $data');

            final playerId = data['playerId'] as String?;
            if (playerId == null) {
              print('No playerId in data');
              return;
            }

            if (playerId == session!.userId) {
              print('Ignoring own update');
              return;
            }

            print('Processing update from player: $playerId');

            // Handle pause events
            if (event.opCode == 2) {
              final type = data['type'] as String?;
              if (type == 'pause') {
                final isPaused = data['isPaused'] as bool? ?? false;
                if (isPaused) {
                  _isPaused = true;
                  timer.pause();
                  player.disableControls();
                  overlays.add('pause');
                  pauseEngine();
                } else {
                  _isPaused = false;
                  timer.start();
                  player.enableControls();
                  overlays.remove('pause');
                  resumeEngine();
                }
                return;
              } else if (type == 'restart') {
                // Handle restart signal from other players
                resetLevel();
                return;
              } else if (type == 'return_to_menu') {
                // Handle return to menu signal from other players
                final BuildContext? ctx = buildContext;
                if (ctx != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Navigate to host join screen
                    Navigator.of(ctx).popUntil((route) => route.isFirst);

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
                      ctx,
                      MaterialPageRoute(
                        builder:
                            (context) => HostJoinScreen(
                              nakamaClient: nakamaClient,
                              session: session!,
                            ),
                      ),
                    );
                  });
                }
                return;
              }
            }

            final x = (data['x'] as num?)?.toDouble();
            final y = (data['y'] as num?)?.toDouble();

            if (x == null || y == null) {
              print('Invalid position data: x=$x, y=$y');
              return;
            }

            // Get remote screen height information
            final remoteScreenHeight =
                (data['screenHeight'] as num?)?.toDouble();
            if (remoteScreenHeight != null) {
              // Store the remote player's screen height
              remoteScreenHeights[playerId] = remoteScreenHeight;

              // Calculate the offset based on screen height difference
              platformYOffset = (gameHeight - remoteScreenHeight) / 2;
              print(
                'Updated platformYOffset to $platformYOffset based on screen height difference',
              );
            }

            final isMoving = data['isMoving'] as bool? ?? false;
            final isJumping = data['isJumping'] as bool? ?? false;
            final scaleX = (data['scaleX'] as num?)?.toDouble() ?? 1.0;

            // Apply the offset to the remote player's Y position
            final adjustedY = y + platformYOffset;

            if (!remotePlayers.containsKey(playerId)) {
              print('Creating new remote player: $playerId');
              final remotePlayer =
                  Monkey(
                      null,
                      worldWidth,
                      gameHeight,
                      playerId: playerId,
                      isRemotePlayer: true,
                    )
                    ..position = Vector2(x, adjustedY)
                    ..priority = 2;
              remotePlayers[playerId] = remotePlayer;
              gameLayer.add(remotePlayer);
            } else {
              print('Updating existing player: $playerId');
              final remotePlayer = remotePlayers[playerId]!;
              remotePlayer.updateRemoteState(
                Vector2(x, adjustedY),
                isMoving,
                isJumping,
                scaleX,
              );
            }
          } catch (e, stackTrace) {
            print('Error processing match data: $e');
            print('Stack trace: $stackTrace');
          }
        }
      });
    }

    // Set up the reset callback to also reset the button and timer
    player.setOnReset(() {
      button.reset();
      timer.reset();
    });

    // Jump button
    final jumpButton = HudButtonComponent(
      button: SpriteComponent(
        sprite: Sprite(images.fromCache('jump_button.png')),
        size: Vector2(gameHeight * 0.24, gameHeight * 0.24),
      ),
      position: Vector2(gameWidth * 0.85, gameHeight * 0.59),
      priority: 2,
      onPressed: player.jump,
    );
    add(jumpButton);
  }

  @override
  void onMount() {
    super.onMount();
    // Register the pause menu overlay
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    overlays.addEntry('pause', (context, game) => PauseMenu(game: this));
  }

  @override
  void update(double dt) {
    // Calculate the camera window boundaries
    final windowLeft =
        -gameLayer.position.x + gameWidth * cameraWindowMarginRatio;
    final windowRight =
        -gameLayer.position.x + gameWidth * (1 - cameraWindowMarginRatio);

    // Initialize target camera position if not set
    if (_targetCameraX == null) {
      _targetCameraX = gameLayer.position.x;
    }

    // Check if player is outside the camera window
    if (player.position.x < windowLeft) {
      // Set target position when player is outside left boundary
      _targetCameraX =
          -(player.position.x - gameWidth * cameraWindowMarginRatio);
    } else if (player.position.x > windowRight) {
      // Set target position when player is outside right boundary
      _targetCameraX =
          -(player.position.x - gameWidth * (1 - cameraWindowMarginRatio));
    }

    // Apply smooth camera movement using linear interpolation with safety checks
    if (_targetCameraX != null &&
        (_targetCameraX! - gameLayer.position.x).abs() > 0.01) {
      try {
        // Use a safer approach with explicit calculations instead of lerpDouble
        double currentX = gameLayer.position.x;
        double targetX = _targetCameraX!;
        double newX = currentX + (targetX - currentX) * cameraSmoothingFactor;

        // Assign the new position
        gameLayer.position.x = newX;
      } catch (e) {
        // Fallback to direct assignment if interpolation fails
        print('Camera interpolation error: $e');
        if (_targetCameraX != null) {
          gameLayer.position.x = _targetCameraX!;
        }
      }
    }

    // Clamp game layer position to world boundaries
    gameLayer.position.x = gameLayer.position.x.clamp(
      -(worldWidth - gameWidth),
      0,
    );

    // Send player position updates in multiplayer mode
    if (socket != null && matchId != null && session != null) {
      _timeSinceLastUpdate += dt;
      if (_timeSinceLastUpdate >= updateRate) {
        _timeSinceLastUpdate = 0;

        final data = {
          'playerId': session!.userId,
          'x': player.position.x,
          'y':
              player.position.y -
              platformYOffset, // Apply inverse offset when sending
          'isMoving': (joystick?.delta.x.abs() ?? 0) > 0,
          'isJumping': !player.isGrounded,
          'scaleX': player.scale.x,
          'screenHeight': gameHeight, // Send our screen height
          'isPaused': _isPaused,
        };

        socket!.sendMatchData(
          matchId: matchId!,
          opCode: 1,
          data: List<int>.from(utf8.encode(jsonEncode(data))),
        );
      }
    }

    if (_isPaused) return;
    super.update(dt);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        timer.pause();
        _audioManager.pauseMusic();
        break;
      case AppLifecycleState.resumed:
        timer.start();
        _audioManager.resumeMusic();
        break;
      default:
        break;
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isPaused) {
          resumeGame();
        } else {
          pauseGame();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.space && !_isPaused) {
        player.jump();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // Update remote players when offset changes
  void updateRemotePlayersWithOffset() {
    for (final remotePlayer in remotePlayers.values) {
      final originalY =
          remotePlayer.position.y - platformYOffset; // Remove old offset
      remotePlayer.position.y = originalY + platformYOffset; // Apply new offset
    }
  }

  // Override the setter to update all remote players when offset changes
  void setPlatformYOffset(double offset) {
    double oldOffset = platformYOffset;
    platformYOffset = offset;
    print('Platform Y offset set to: $offset (changed from $oldOffset)');

    if (oldOffset != offset) {
      updateRemotePlayersWithOffset();
    }
  }

  void pauseGame() {
    if (!_isPaused) {
      _isPaused = true;
      timer.pause();
      player.disableControls();
      overlays.add('pause');
      pauseEngine();

      // Send pause signal to other players
      if (socket != null && matchId != null && session != null) {
        final data = {
          'playerId': session!.userId,
          'type': 'pause',
          'isPaused': true,
        };

        socket!.sendMatchData(
          matchId: matchId!,
          opCode: 2,
          data: List<int>.from(utf8.encode(jsonEncode(data))),
        );
      }
    }
  }

  void resumeGame() {
    if (_isPaused) {
      _isPaused = false;
      timer.start();
      player.enableControls();
      overlays.remove('pause');
      resumeEngine();

      // Ensure player is visible and in correct state
      player.isVisible = true;
      player.opacity = 1.0;
      if ((player.joystick?.delta.x.abs() ?? 0) > 0) {
        player.animation = player.runAnimation;
      } else {
        player.animation = player.idleAnimation;
      }

      // Send resume signal to other players
      if (socket != null && matchId != null && session != null) {
        final data = {
          'playerId': session!.userId,
          'type': 'pause',
          'isPaused': false,
        };

        socket!.sendMatchData(
          matchId: matchId!,
          opCode: 2,
          data: List<int>.from(utf8.encode(jsonEncode(data))),
        );
      }
    }
  }

  void resetLevel() {
    // Reset the player
    player.reset();

    // Reset the timer
    timer.reset();

    // Reset the button if it exists
    final button = gameLayer.children.whereType<Button>().firstOrNull;
    if (button != null) {
      button.reset();
    }

    // Reset any other game state that needs to be reset
    _isPaused = false;
    timer.start();
    player.enableControls();
    overlays.remove('pause');
    resumeEngine();
  }

  void sendRestartSignal() {
    if (socket != null && matchId != null && session != null) {
      final data = {'playerId': session!.userId, 'type': 'restart'};

      socket!.sendMatchData(
        matchId: matchId!,
        opCode: 2,
        data: List<int>.from(utf8.encode(jsonEncode(data))),
      );
    }
  }

  @override
  Future<void> onRemove() async {
    super.onRemove();
  }
}
