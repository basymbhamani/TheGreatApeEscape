import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pre_game_lobby.dart'; // Import the PreGameLobby screen
import 'package:flame/game.dart';
import 'game.dart';
import 'dart:math';
import 'dart:convert';

// Create a wrapper class to hold our current session
class SessionWrapper {
  Session session;

  SessionWrapper(this.session);
}

class HostJoinScreen extends StatefulWidget {
  final NakamaBaseClient nakamaClient;
  final Session session;

  const HostJoinScreen({
    Key? key,
    required this.nakamaClient,
    required this.session,
  }) : super(key: key);

  @override
  _HostJoinScreenState createState() => _HostJoinScreenState();
}

class _HostJoinScreenState extends State<HostJoinScreen> {
  late NakamaWebsocketClient socket;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  late SessionWrapper _sessionWrapper;
  // Add FocusNodes for the text fields
  final FocusNode _groupNameFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();

  String generateShortCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  void initState() {
    super.initState();
    _sessionWrapper = SessionWrapper(widget.session);
    _initializeWebSocket();
  }

  Future<Session> _refreshSession() async {
    try {
      print('Refreshing expired session token...');
      final refreshedSession = await widget.nakamaClient.sessionRefresh(
        session: _sessionWrapper.session,
      );

      // Update our session wrapper with the new session
      _sessionWrapper.session = refreshedSession;

      // Create a new socket with the refreshed token
      await socket.close();

      // Create a new socket with the refreshed token
      socket = NakamaWebsocketClient.init(
        host: dotenv.env['NAKAMA_HOST']!,
        ssl: dotenv.env['NAKAMA_SSL']!.toLowerCase() == 'true',
        token: refreshedSession.token,
      );

      print(
        'Session refreshed successfully with new token: ${refreshedSession.token}',
      );
      return refreshedSession;
    } catch (e) {
      print('Error refreshing session: $e');
      throw e;
    }
  }

  Future<String> storeMatchCode(String shortCode, String matchId) async {
    try {
      shortCode = shortCode.toUpperCase(); // Ensure the key is uppercase
      matchId = matchId.trim(); // Remove any trailing whitespace or characters
      print('Storing match code: $shortCode for match: $matchId');

      try {
        final writeObject = StorageObjectWrite(
          collection: 'match_codes',
          key: shortCode,
          value: jsonEncode({
            'matchId': matchId,
            'createdAt': DateTime.now().toIso8601String(),
          }),
          permissionRead: StorageReadPermission.publicRead,
          permissionWrite: StorageWritePermission.ownerWrite,
        );

        await widget.nakamaClient.writeStorageObjects(
          session: _sessionWrapper.session,
          objects: [writeObject],
        );

        print('Successfully stored match code: $shortCode -> $matchId');
      } catch (e) {
        if (e.toString().contains('UNAUTHENTICATED') ||
            e.toString().contains('Auth token invalid')) {
          print('Token expired, refreshing session and retrying...');
          await _refreshSession();

          // Create a fresh match with the new socket/session
          print('Creating a fresh match with the new session...');
          final newMatch = await socket.createMatch();
          final newMatchId = newMatch.matchId;
          print('New match created: $newMatchId replacing: $matchId');

          // Store with the new match ID
          final writeObject = StorageObjectWrite(
            collection: 'match_codes',
            key: shortCode,
            value: jsonEncode({
              'matchId': newMatchId,
              'createdAt': DateTime.now().toIso8601String(),
            }),
            permissionRead: StorageReadPermission.publicRead,
            permissionWrite: StorageWritePermission.ownerWrite,
          );

          await widget.nakamaClient.writeStorageObjects(
            session: _sessionWrapper.session,
            objects: [writeObject],
          );

          print(
            'Successfully stored match code after session refresh: $shortCode -> $newMatchId',
          );
          // Return the new match ID to the caller
          matchId = newMatchId;
        } else {
          throw e; // Re-throw if it's not a token issue
        }
      }
      return matchId;
    } catch (e, stackTrace) {
      print('Error storing match code: $e');
      print('Stack trace: $stackTrace');
      return matchId; // Return the original matchId in case of errors
    }
  }

  Future<String?> getMatchId(String shortCode) async {
    try {
      shortCode = shortCode.toUpperCase(); // Ensure the key is uppercase
      print('Attempting to read match code: $shortCode');

      try {
        final readObject = StorageObjectId(
          collection: 'match_codes',
          key: shortCode,
        );

        final result = await widget.nakamaClient.readStorageObjects(
          session: _sessionWrapper.session,
          objectIds: [readObject],
        );

        if (result.isNotEmpty && result[0].value != null) {
          final data = jsonDecode(result[0].value);
          final matchId = data['matchId'] as String?;
          print('Found match ID: $matchId for code: $shortCode');
          return matchId;
        }
      } catch (e) {
        if (e.toString().contains('UNAUTHENTICATED') ||
            e.toString().contains('Auth token invalid')) {
          print('Token expired, refreshing session and retrying...');
          await _refreshSession();

          // After refreshing the session, try again
          final readObject = StorageObjectId(
            collection: 'match_codes',
            key: shortCode,
          );

          final result = await widget.nakamaClient.readStorageObjects(
            session: _sessionWrapper.session,
            objectIds: [readObject],
          );

          if (result.isNotEmpty && result[0].value != null) {
            final data = jsonDecode(result[0].value);
            final matchId = data['matchId'] as String?;
            print(
              'Found match ID after refresh: $matchId for code: $shortCode',
            );

            // Pre-join the match with our new socket to ensure we're connected properly
            try {
              print('Pre-joining match with refreshed session...');
              await socket.joinMatch(matchId!);
              print('Successfully pre-joined match after session refresh');
            } catch (joinError) {
              print('Error pre-joining match: $joinError');
              // Continue anyway, we'll try to join again when the user clicks Join
            }

            return matchId;
          }
        } else {
          print('Error reading match code: $e');
        }
      }

      // Fallback: Search manually in the listStorageObjects result
      try {
        final storageObjects = await widget.nakamaClient.listStorageObjects(
          session: _sessionWrapper.session,
          collection: 'match_codes',
          limit: 100,
        );

        for (var obj in storageObjects.objects) {
          if (obj.key == shortCode) {
            final data = jsonDecode(obj.value);
            final matchId = data['matchId'] as String?;
            print('Fallback found match ID: $matchId for code: $shortCode');
            return matchId;
          }
        }
      } catch (e) {
        if (e.toString().contains('UNAUTHENTICATED') ||
            e.toString().contains('Auth token invalid')) {
          print(
            'Token expired during fallback, refreshing session and retrying...',
          );
          await _refreshSession();

          final storageObjects = await widget.nakamaClient.listStorageObjects(
            session: _sessionWrapper.session,
            collection: 'match_codes',
            limit: 100,
          );

          for (var obj in storageObjects.objects) {
            if (obj.key == shortCode) {
              final data = jsonDecode(obj.value);
              final matchId = data['matchId'] as String?;
              print(
                'Fallback found match ID after refresh: $matchId for code: $shortCode',
              );

              // Pre-join the match with our new socket to ensure we're connected properly
              try {
                print(
                  'Pre-joining match with refreshed session (fallback path)...',
                );
                await socket.joinMatch(matchId!);
                print(
                  'Successfully pre-joined match after session refresh (fallback path)',
                );
              } catch (joinError) {
                print('Error pre-joining match (fallback path): $joinError');
                // Continue anyway, we'll try to join again when the user clicks Join
              }

              return matchId;
            }
          }
        } else {
          print('Error in fallback search: $e');
        }
      }

      print('No match found for code: $shortCode');
      return null;
    } catch (e) {
      print('Error reading match code: $e');
      return null;
    }
  }

  Future<void> _initializeWebSocket() async {
    print(
      'Connecting to Nakama server at ${dotenv.env['NAKAMA_HOST']}:${dotenv.env['NAKAMA_HTTP_PORT']}',
    );

    socket = NakamaWebsocketClient.init(
      host: dotenv.env['NAKAMA_HOST']!,
      ssl: dotenv.env['NAKAMA_SSL']!.toLowerCase() == 'true',
      token: _sessionWrapper.session.token,
    );

    try {
      // Fetch all storage objects in the 'match_codes' collection
      final storageObjects = await widget.nakamaClient.listStorageObjects(
        session: _sessionWrapper.session,
        collection: 'match_codes',
        limit: 100, // Adjust the limit as needed
      );

      if (storageObjects.objects.isNotEmpty) {
        print('Storage objects in "match_codes" collection:');
        for (var obj in storageObjects.objects) {
          print('Key: ${obj.key}, Value: ${obj.value}');
        }
      } else {
        print('No storage objects found in "match_codes" collection.');
      }
    } catch (e) {
      print('Error fetching storage objects: $e');
    }
  }

  // Function to show the Host dialog
  void _showHostDialog(BuildContext context) {
    // Create a ScrollController to control scrolling
    final ScrollController scrollController = ScrollController();

    // Focus listener to scroll when keyboard appears
    _groupNameFocusNode.addListener(() {
      if (_groupNameFocusNode.hasFocus) {
        // Small delay to wait for keyboard to show up
        Future.delayed(const Duration(milliseconds: 300), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.black, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 24),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.topLeft,
                  ),
                  const Center(
                    child: Text(
                      'HOST',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please enter a group name:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groupNameController,
                    focusNode: _groupNameFocusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Group Name',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        try {
                          // Create match
                          final match = await socket.createMatch();
                          String matchId = match.matchId;

                          // Generate a code
                          final shortCode = generateShortCode();

                          // Store the code
                          matchId = await storeMatchCode(shortCode, matchId);

                          // Remove loading indicator
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          // Close the host dialog
                          Navigator.pop(context);

                          // Navigate to pre-game lobby
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PreGameLobby(
                                    code: matchId,
                                    displayCode: shortCode,
                                    socket: socket,
                                    isHost: true,
                                    groupName: _groupNameController.text,
                                    session: _sessionWrapper.session,
                                  ),
                            ),
                          );
                        } catch (e) {
                          // Remove loading indicator
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          print('Error creating match: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create game: $e'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'START',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to show the Join dialog
  void _showJoinDialog(BuildContext context) {
    // Create a ScrollController to control scrolling
    final ScrollController scrollController = ScrollController();

    // Focus listener to scroll when keyboard appears
    _codeFocusNode.addListener(() {
      if (_codeFocusNode.hasFocus) {
        // Small delay to wait for keyboard to show up
        Future.delayed(const Duration(milliseconds: 300), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.black, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 24),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.topLeft,
                  ),
                  const Center(
                    child: Text(
                      'JOIN',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please enter a lobby code:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    focusNode: _codeFocusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Lobby Code',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        String lobbyCode = _codeController.text.trim();
                        if (lobbyCode.isNotEmpty) {
                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          try {
                            // Get the match ID from the code
                            final matchId = await getMatchId(lobbyCode);

                            if (matchId != null) {
                              // Join the match
                              final match = await socket.joinMatch(matchId);

                              // Remove loading indicator
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              // Close the join dialog
                              Navigator.pop(context);

                              // Navigate to pre-game lobby
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PreGameLobby(
                                        code: matchId,
                                        displayCode: lobbyCode,
                                        socket: socket,
                                        isHost: false,
                                        session: _sessionWrapper.session,
                                      ),
                                ),
                              );
                            } else {
                              // Remove loading indicator
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid game code'),
                                ),
                              );
                            }
                          } catch (e) {
                            // Remove loading indicator
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }

                            print('Error joining match: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to join game: $e'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'START',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            image: AssetImage("assets/images/main_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Host Button
              SizedBox(
                width: 300,
                height: 100,
                child: ElevatedButton(
                  onPressed: () => _showHostDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Join Button
              SizedBox(
                width: 300,
                height: 100,
                child: ElevatedButton(
                  onPressed: () => _showJoinDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'JOIN',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _groupNameController.dispose();
    _groupNameFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }
}
