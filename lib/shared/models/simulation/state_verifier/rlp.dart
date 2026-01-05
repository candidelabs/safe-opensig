import 'dart:typed_data';

/// RLP (Recursive Length Prefix) encoding/decoding
///
/// RLP is the main encoding method used to serialize objects in Ethereum.
/// It can encode arbitrarily nested arrays of binary data.
class RLP {
  /// Decode RLP-encoded data into nested lists and byte arrays
  ///
  /// Example:
  /// ```dart
  /// final decoded = RLP.decode(hexToBytes('0xc50102'));
  /// // Returns: [Uint8List([1]), Uint8List([2])]
  /// ```
  static dynamic decode(Uint8List input) {
    if (input.isEmpty) return [];
    final result = _decodeItem(input, 0).$1;
    // RLP decode always returns the actual decoded structure
    // For strings, it returns Uint8List; for lists, it returns List<dynamic>
    return result;
  }

  static (dynamic, int) _decodeItem(Uint8List input, int offset) {
    if (offset >= input.length) {
      throw RlpException('Offset out of bounds');
    }

    final prefix = input[offset];

    if (prefix <= 0x7f) {
      // Single byte in [0x00, 0x7f] range
      return (Uint8List.fromList([prefix]), offset + 1);
    } else if (prefix <= 0xb7) {
      // String with length 0-55 bytes
      final length = prefix - 0x80;
      if (length == 0) return (Uint8List(0), offset + 1);
      return (
        Uint8List.fromList(input.sublist(offset + 1, offset + 1 + length)),
        offset + 1 + length
      );
    } else if (prefix <= 0xbf) {
      // String with length > 55 bytes
      final lengthOfLength = prefix - 0xb7;
      final length = _readLength(input, offset + 1, lengthOfLength);
      final dataStart = offset + 1 + lengthOfLength;
      return (
        Uint8List.fromList(input.sublist(dataStart, dataStart + length)),
        dataStart + length
      );
    } else if (prefix <= 0xf7) {
      // List with total payload length 0-55 bytes
      final length = prefix - 0xc0;
      final dataStart = offset + 1;
      return (
        _decodeList(input, dataStart, dataStart + length),
        dataStart + length
      );
    } else {
      // List with total payload length > 55 bytes
      final lengthOfLength = prefix - 0xf7;
      final length = _readLength(input, offset + 1, lengthOfLength);
      final dataStart = offset + 1 + lengthOfLength;
      return (
        _decodeList(input, dataStart, dataStart + length),
        dataStart + length
      );
    }
  }

  static int _readLength(Uint8List input, int offset, int lengthOfLength) {
    int length = 0;
    for (int i = 0; i < lengthOfLength; i++) {
      length = (length << 8) | input[offset + i];
    }
    return length;
  }

  static List<dynamic> _decodeList(Uint8List input, int start, int end) {
    final result = <dynamic>[];
    int offset = start;
    while (offset < end) {
      final decoded = _decodeItem(input, offset);
      result.add(decoded.$1);
      offset = decoded.$2;
    }
    return result;
  }

  /// Encode data into RLP format
  ///
  /// Accepts either Uint8List for byte strings or List for nested structures.
  ///
  /// Example:
  /// ```dart
  /// final encoded = RLP.encode([Uint8List.fromList([1]), Uint8List.fromList([2])]);
  /// // Returns: Uint8List corresponding to 0xc50102
  /// ```
  static Uint8List encode(dynamic input) {
    if (input is Uint8List) {
      return _encodeBytes(input);
    } else if (input is List) {
      return _encodeList(input);
    } else {
      throw RlpException('Invalid input type: ${input.runtimeType}. Expected Uint8List or List.');
    }
  }

  static Uint8List _encodeBytes(Uint8List input) {
    if (input.length == 1 && input[0] < 0x80) {
      // Single byte in [0x00, 0x7f] range
      return input;
    } else if (input.length <= 55) {
      // String with length 0-55 bytes
      return Uint8List.fromList([0x80 + input.length, ...input]);
    } else {
      // String with length > 55 bytes
      final lengthBytes = _intToBytes(input.length);
      return Uint8List.fromList([
        0xb7 + lengthBytes.length,
        ...lengthBytes,
        ...input
      ]);
    }
  }

  static Uint8List _encodeList(List<dynamic> input) {
    final encoded = <int>[];
    for (final item in input) {
      encoded.addAll(encode(item));
    }

    if (encoded.length <= 55) {
      // List with total payload length 0-55 bytes
      return Uint8List.fromList([0xc0 + encoded.length, ...encoded]);
    } else {
      // List with total payload length > 55 bytes
      final lengthBytes = _intToBytes(encoded.length);
      return Uint8List.fromList([
        0xf7 + lengthBytes.length,
        ...lengthBytes,
        ...encoded
      ]);
    }
  }

  static Uint8List _intToBytes(int value) {
    if (value == 0) return Uint8List(0);
    final bytes = <int>[];
    while (value > 0) {
      bytes.insert(0, value & 0xff);
      value >>= 8;
    }
    return Uint8List.fromList(bytes);
  }
}

class RlpException implements Exception {
  final String message;
  RlpException(this.message);

  @override
  String toString() => 'RlpException: $message';
}
