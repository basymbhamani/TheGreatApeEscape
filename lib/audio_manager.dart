import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  final AudioPlayer _bgMusic = AudioPlayer();
  bool _isMusicInitialized = false;
  double _volume = 0.5;

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal();

  double get volume => _volume;

  Future<void> initializeMusic() async {
    if (!_isMusicInitialized) {
      try {
        await _bgMusic.setSource(AssetSource('bg_sound.mp3'));
        await _bgMusic.setVolume(_volume);
        await _bgMusic.setReleaseMode(ReleaseMode.loop);
        await _bgMusic.resume();
        _isMusicInitialized = true;
      } catch (e) {
        print('Error initializing background music: $e');
      }
    }
  }

  void setVolume(double volume) {
    _volume = volume;
    _bgMusic.setVolume(volume);
  }

  void pauseMusic() {
    _bgMusic.pause();
  }

  void resumeMusic() {
    _bgMusic.resume();
  }

  Future<void> dispose() async {
    await _bgMusic.dispose();
  }
}
