import 'dart:convert';
import 'dart:math';

class CodeGenerator {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _codeLength = 5;
  
  /// Generates a 5-character code from any match ID
  static String generateCode(String matchId) {
    // Create a hash of the match ID
    final hash = matchId.hashCode;
    
    // Use the hash to generate a 5-character code
    final code = List<String>.generate(_codeLength, (index) {
      // Use different parts of the hash for each position
      final value = (hash >> (index * 6)) & 0x3F;
      return _alphabet[value % _alphabet.length];
    }).join();
    
    return code;
  }

  /// Decodes a 5-character code back to a match ID
  static String decodeCode(String code) {
    if (code.length != _codeLength) {
      throw ArgumentError('Code must be exactly $_codeLength characters long');
    }

    // Convert code back to hash
    int hash = 0;
    for (int i = 0; i < code.length; i++) {
      final char = code[i].toUpperCase();
      if (!_alphabet.contains(char)) {
        throw ArgumentError('Invalid character in code: $char');
      }
      final value = _alphabet.indexOf(char);
      hash |= (value % _alphabet.length) << (i * 6);
    }

    // Convert hash back to bytes
    final bytes = List<int>.generate(4, (i) => (hash >> (i * 8)) & 0xFF);
    
    // Convert to string
    return utf8.decode(bytes);
  }

  /// Validates if a code is valid
  static bool isValidCode(String code) {
    if (code.length != _codeLength) return false;
    return code.toUpperCase().split('').every((char) => _alphabet.contains(char));
  }
} 