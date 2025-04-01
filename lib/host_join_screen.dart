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
  late SessionWrapper _sessionWrapper;
  
  String generateShortCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
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
      final refreshedSession = await widget.nakamaClient.sessionRefresh(session: _sessionWrapper.session);
      
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
      
      print('Session refreshed successfully with new token: ${refreshedSession.token}');
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
        value: jsonEncode({'matchId': matchId, 'createdAt': DateTime.now().toIso8601String()}),
        permissionRead: StorageReadPermission.publicRead,
        permissionWrite: StorageWritePermission.ownerWrite,
      );
      
      await widget.nakamaClient.writeStorageObjects(
        session: _sessionWrapper.session,
        objects: [writeObject],
      );
      
      print('Successfully stored match code: $shortCode -> $matchId');
    } catch (e) {
      if (e.toString().contains('UNAUTHENTICATED') || e.toString().contains('Auth token invalid')) {
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
          value: jsonEncode({'matchId': newMatchId, 'createdAt': DateTime.now().toIso8601String()}),
          permissionRead: StorageReadPermission.publicRead,
          permissionWrite: StorageWritePermission.ownerWrite,
        );
        
        await widget.nakamaClient.writeStorageObjects(
          session: _sessionWrapper.session,
          objects: [writeObject],
        );
        
        print('Successfully stored match code after session refresh: $shortCode -> $newMatchId');
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
      if (e.toString().contains('UNAUTHENTICATED') || e.toString().contains('Auth token invalid')) {
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
          print('Found match ID after refresh: $matchId for code: $shortCode');
          
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
      if (e.toString().contains('UNAUTHENTICATED') || e.toString().contains('Auth token invalid')) {
        print('Token expired during fallback, refreshing session and retrying...');
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
            print('Fallback found match ID after refresh: $matchId for code: $shortCode');
            
            // Pre-join the match with our new socket to ensure we're connected properly
            try {
              print('Pre-joining match with refreshed session (fallback path)...');
              await socket.joinMatch(matchId!);
              print('Successfully pre-joined match after session refresh (fallback path)');
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
  print('Connecting to Nakama server at ${dotenv.env['NAKAMA_HOST']}:${dotenv.env['NAKAMA_HTTP_PORT']}');

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

  void _startGame(String matchId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameWidget(
          game: ApeEscapeGame(
            socket: socket,
            matchId: matchId,
            session: _sessionWrapper.session,
          ),
          backgroundBuilder: (context) => Container(
            color: const Color(0xFF87CEEB),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(bool isHost) async {
    if (isHost) {
      // Generate code and create match outside of the dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        // Create match first
        final match = await socket.createMatch();
        String matchId = match.matchId;
        
        // Generate a single code
        final shortCode = generateShortCode();
        
        // Store the code and get possibly updated matchId (in case of session refresh)
        matchId = await storeMatchCode(shortCode, matchId);
        
        // Remove loading indicator
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Now show the host dialog with pre-generated code
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HOST',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Share this code with other players:'),
                const SizedBox(height: 8),
                Text(
                  shortCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startGame(matchId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('START GAME'),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        // Remove loading indicator if it's still showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        print('Error creating match: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create game: $e')),
        );
      }
    } else {
      // Join flow remains the same
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'JOIN',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter 6-digit Code',
                ),
                style: const TextStyle(letterSpacing: 4),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final code = _codeController.text.trim().toUpperCase();
                  if (code.length == 6) {
                    try {
                      print('Attempting to join with code: $code');
                      
                      // Display loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      
                      // Get the match ID from Nakama storage
                      final matchId = await getMatchId(code);
                      
                      // Safely remove loading indicator
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      
                      if (matchId != null) {
                        print('Found match ID: $matchId, attempting to join...');
                        try {
                          final match = await socket.joinMatch(matchId);
                          print('Successfully joined match: ${match.matchId}');
                          Navigator.pop(context); // Close the join dialog
                          _startGame(match.matchId);
                        } catch (e) {
                          print('Error joining match: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Game exists but cannot be joined: $e')),
                          );
                        }
                      } else {
                        // No match found in Nakama storage
                        print('No match found for code: $code');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid game code. Ask the host for the correct code.')),
                        );
                      }
                    } catch (e) {
                      // Remove loading indicator if it's still showing
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      
                      print('Error joining game: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to join game: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a 6-digit code')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('JOIN GAME'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 300,
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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
              _buildButton('HOST', Colors.orange, () => _handleAction(true)),
              const SizedBox(height: 40),
              _buildButton('JOIN', Colors.green, () => _handleAction(false)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
