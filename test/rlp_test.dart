import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_verify/shared/models/simulation/state_verifier/rlp.dart';

/// Helper to convert hex string to Uint8List
Uint8List hexToBytes(String hex) {
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.isEmpty) return Uint8List(0);

  final bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

/// Helper to convert Uint8List to hex string
String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

/// Helper to create a Uint8List from a list of integers
Uint8List bytes(List<int> data) => Uint8List.fromList(data);

/// Helper to convert ASCII string to Uint8List
Uint8List ascii(String str) => Uint8List.fromList(str.codeUnits);

void main() {
  group('RLP Encoding Tests', () {
    final encodingTests = [
      // Test 1: Empty string
      {
        'description': 'Empty string',
        'input': bytes([]),
        'expected': '80',
      },

      // Test 2: Single byte < 0x80
      {
        'description': 'Single byte 0x00',
        'input': bytes([0x00]),
        'expected': '00',
      },

      // Test 3: Single byte 0x7f
      {
        'description': 'Single byte 0x7f',
        'input': bytes([0x7f]),
        'expected': '7f',
      },

      // Test 4: Single byte 0x80
      {
        'description': 'Single byte 0x80',
        'input': bytes([0x80]),
        'expected': '8180',
      },

      // Test 5: Short string (< 55 bytes) - "dog"
      {
        'description': 'String "dog"',
        'input': ascii('dog'),
        'expected': '83646f67',
      },

      // Test 6: Short string - "Lorem ipsum dolor sit amet, consectetur adipisicing eli"
      {
        'description': 'String (55 bytes)',
        'input': ascii('Lorem ipsum dolor sit amet, consectetur adipisicing eli'),
        'expected': 'b74c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c69',
      },

      // Test 7: Long string (> 55 bytes) - "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
      {
        'description': 'String (56 bytes)',
        'input': ascii('Lorem ipsum dolor sit amet, consectetur adipisicing elit'),
        'expected': 'b8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974',
      },

      // Test 8: Empty list
      {
        'description': 'Empty list',
        'input': [],
        'expected': 'c0',
      },

      // Test 9: List with empty strings
      {
        'description': 'List of empty strings [[],[],[]]',
        'input': [bytes([]), bytes([]), bytes([])],
        'expected': 'c3808080',
      },

      // Test 10: Simple list ["cat", "dog"]
      {
        'description': 'List ["cat", "dog"]',
        'input': [ascii('cat'), ascii('dog')],
        'expected': 'c88363617483646f67',
      },

      // Test 11: List with single element [1]
      {
        'description': 'List with single byte [1]',
        'input': [bytes([0x01])],
        'expected': 'c101',
      },

      // Test 12: List with multiple single bytes [1, 2, 3]
      {
        'description': 'List [1, 2, 3]',
        'input': [bytes([0x01]), bytes([0x02]), bytes([0x03])],
        'expected': 'c3010203',
      },

      // Test 13: Nested list [[], [[]]]
      {
        'description': 'Nested list [[], [[]]]',
        'input': [[], [[]]],
        'expected': 'c3c0c1c0',
      },

      // Test 14: Nested list [[1, 2], [3, 4]]
      {
        'description': 'Nested list [[1, 2], [3, 4]]',
        'input': [
          [bytes([0x01]), bytes([0x02])],
          [bytes([0x03]), bytes([0x04])]
        ],
        'expected': 'c6c20102c20304',
      },

      // Test 15: Integer 0
      {
        'description': 'Integer 0 (empty byte array)',
        'input': bytes([]),
        'expected': '80',
      },

      // Test 16: Integer 15
      {
        'description': 'Integer 15 (0x0f)',
        'input': bytes([0x0f]),
        'expected': '0f',
      },

      // Test 17: Integer 1024
      {
        'description': 'Integer 1024 (0x0400)',
        'input': bytes([0x04, 0x00]),
        'expected': '820400',
      },

    ];

    for (int i = 0; i < encodingTests.length; i++) {
      final testCase = encodingTests[i];
      final description = testCase['description'] as String;
      final input = testCase['input'];
      final expected = testCase['expected'] as String;

      test('Encoding Test ${i + 1}: $description', () {
        final encoded = RLP.encode(input);
        final result = bytesToHex(encoded);

        expect(
          result,
          equals(expected),
          reason: 'Failed encoding "$description"\nExpected: $expected\nGot: $result',
        );
      });
    }
  });

  group('RLP Decoding Tests', () {
    final decodingTests = [
      // Test 1: Empty string
      {
        'description': 'Empty string',
        'input': '80',
        'expected': bytes([]),
        'isList': false,
      },

      // Test 2: Single byte 0x00
      {
        'description': 'Single byte 0x00',
        'input': '00',
        'expected': bytes([0x00]),
        'isList': false,
      },

      // Test 3: Single byte 0x7f
      {
        'description': 'Single byte 0x7f',
        'input': '7f',
        'expected': bytes([0x7f]),
        'isList': false,
      },

      // Test 4: Single byte 0x80
      {
        'description': 'Single byte 0x80',
        'input': '8180',
        'expected': bytes([0x80]),
        'isList': false,
      },

      // Test 5: String "dog"
      {
        'description': 'String "dog"',
        'input': '83646f67',
        'expected': ascii('dog'),
        'isList': false,
      },

      // Test 6: Empty list
      {
        'description': 'Empty list',
        'input': 'c0',
        'expected': [],
        'isList': true,
      },

      // Test 7: List with empty strings [[],[],[]]
      {
        'description': 'List of empty strings',
        'input': 'c3808080',
        'expected': [bytes([]), bytes([]), bytes([])],
        'isList': true,
      },

      // Test 8: List ["cat", "dog"]
      {
        'description': 'List ["cat", "dog"]',
        'input': 'c88363617483646f67',
        'expected': [ascii('cat'), ascii('dog')],
        'isList': true,
      },

      // Test 9: List [1]
      {
        'description': 'List [1]',
        'input': 'c101',
        'expected': [bytes([0x01])],
        'isList': true,
      },

      // Test 10: List [1, 2, 3]
      {
        'description': 'List [1, 2, 3]',
        'input': 'c3010203',
        'expected': [bytes([0x01]), bytes([0x02]), bytes([0x03])],
        'isList': true,
      },

      // Test 11: Nested list [[], [[]]]
      {
        'description': 'Nested list [[], [[]]]',
        'input': 'c3c0c1c0',
        'expected': [[], [[]]],
        'isList': true,
      },
    ];

    for (int i = 0; i < decodingTests.length; i++) {
      final testCase = decodingTests[i];
      final description = testCase['description'] as String;
      final input = testCase['input'] as String;
      final expected = testCase['expected'];
      final isList = testCase['isList'] as bool;

      test('Decoding Test ${i + 1}: $description', () {
        final decoded = RLP.decode(hexToBytes(input));

        // Deep comparison helper
        bool deepEqual(dynamic a, dynamic b) {
          // Check Uint8List first since it's a subtype of List
          if (a is Uint8List && b is Uint8List) {
            if (a.length != b.length) return false;
            for (int i = 0; i < a.length; i++) {
              if (a[i] != b[i]) return false;
            }
            return true;
          } else if (a is List && b is List) {
            if (a.length != b.length) return false;
            for (int i = 0; i < a.length; i++) {
              if (!deepEqual(a[i], b[i])) return false;
            }
            return true;
          }
          return a == b;
        }

        if (isList) {
          expect(
            decoded,
            isA<List>(),
            reason: 'Expected a list for "$description"',
          );

          // Debug output
          String formatValue(dynamic v) {
            if (v is Uint8List) {
              return 'Uint8List(${bytesToHex(v)})';
            } else if (v is List) {
              return '[${v.map(formatValue).join(', ')}]';
            }
            return v.toString();
          }

          expect(
            deepEqual(decoded, expected),
            isTrue,
            reason: 'Failed decoding "$description"\nExpected: ${formatValue(expected)}\nGot: ${formatValue(decoded)}',
          );
        } else {
          expect(
            decoded,
            isA<Uint8List>(),
            reason: 'Expected Uint8List for "$description"',
          );

          final result = decoded as Uint8List;
          final expectedBytes = expected as Uint8List;

          expect(
            bytesToHex(result),
            equals(bytesToHex(expectedBytes)),
            reason: 'Failed decoding "$description"\nExpected: ${bytesToHex(expectedBytes)}\nGot: ${bytesToHex(result)}',
          );
        }
      });
    }
  });

  group('RLP Round-trip Tests', () {
    final roundTripTests = [
      {
        'description': 'Empty string',
        'data': bytes([]),
      },
      {
        'description': 'Single byte',
        'data': bytes([0x42]),
      },
      {
        'description': 'Short string',
        'data': ascii('Hello'),
      },
      {
        'description': 'Empty list',
        'data': [],
      },
      {
        'description': 'Simple list',
        'data': [bytes([0x01]), bytes([0x02]), bytes([0x03])],
      },
      {
        'description': 'Nested list',
        'data': [
          [bytes([0x01])],
          [bytes([0x02]), bytes([0x03])]
        ],
      },
    ];

    for (int i = 0; i < roundTripTests.length; i++) {
      final testCase = roundTripTests[i];
      final description = testCase['description'] as String;
      final data = testCase['data'];

      test('Round-trip Test ${i + 1}: $description', () {
        // Encode
        final encoded = RLP.encode(data);

        // Decode
        final decoded = RLP.decode(encoded);

        // Deep comparison helper
        bool deepEqual(dynamic a, dynamic b) {
          // Check Uint8List first since it's a subtype of List
          if (a is Uint8List && b is Uint8List) {
            return bytesToHex(a) == bytesToHex(b);
          } else if (a is List && b is List) {
            if (a.length != b.length) return false;
            for (int i = 0; i < a.length; i++) {
              if (!deepEqual(a[i], b[i])) return false;
            }
            return true;
          }
          return a == b;
        }

        expect(deepEqual(decoded, data), isTrue,
            reason: 'Round-trip failed for "$description"');
      });
    }
  });

  group('RLP Error Handling Tests', () {
    test('Invalid input type throws exception', () {
      expect(
        () => RLP.encode("invalid string"),
        throwsA(isA<RlpException>()),
      );
    });

    test('Empty input to decode returns empty list', () {
      final result = RLP.decode(Uint8List(0));
      expect(result, isEmpty);
    });
  });
}
