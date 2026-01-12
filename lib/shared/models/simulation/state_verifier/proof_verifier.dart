import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'rlp.dart';

/// Represents a node in the Merkle Patricia Trie
sealed class MptNode {
  final Uint8List rlpEncoded;

  MptNode(this.rlpEncoded);

  factory MptNode.fromRlp(Uint8List rlpData) {
    final decoded = RLP.decode(rlpData);

    if (decoded.length == 17) {
      return BranchNode(rlpData, decoded);
    } else if (decoded.length == 2) {
      final encodedPath = decoded[0] as Uint8List;
      final isLeaf = (encodedPath[0] & 0x20) != 0;

      return isLeaf
        ? LeafNode(rlpData, decoded)
        : ExtensionNode(rlpData, decoded);
    } else {
      throw InvalidNodeException('Invalid node length: ${decoded.length}');
    }
  }

  Uint8List get hash => keccak256(rlpEncoded);
}

/// Branch node - 17 elements (16 children + 1 value)
class BranchNode extends MptNode {
  final List<dynamic> children;

  BranchNode(super.rlpEncoded, this.children);

  /// Get child at specific nibble (0-F)
  Uint8List? getChild(int nibble) {
    if (nibble < 0 || nibble > 15) return null;
    final child = children[nibble] as Uint8List;
    return child.isEmpty ? null : child;
  }

  /// Get value stored at this node
  Uint8List get value => children[16] as Uint8List;

  bool get hasValue => value.isNotEmpty;
}

/// Leaf node - stores final value
class LeafNode extends MptNode {
  final List<int> path;
  final Uint8List value;

  LeafNode(super.rlpEncoded, List<dynamic> decoded)
    : path = PathEncoder.decode(decoded[0] as Uint8List),
      value = decoded[1] as Uint8List;
}

/// Extension node - compresses long paths
class ExtensionNode extends MptNode {
  final List<int> path;
  final Uint8List next;

  ExtensionNode(super.rlpEncoded, List<dynamic> decoded)
    : path = PathEncoder.decode(decoded[0] as Uint8List),
      next = decoded[1] as Uint8List;
}

/// Handles path encoding/decoding in compact hex-prefix format
class PathEncoder {
  /// Decode compact hex-prefix encoded path to nibbles
  static List<int> decode(Uint8List encodedPath) {
    final nibbles = Nibbles.fromBytes(encodedPath);
    final prefix = nibbles[0];

    // Even length path (prefix 0x0_ or 0x2_)
    if (prefix == 0 || prefix == 2) {
      return nibbles.sublist(2);
    }
    // Odd length path (prefix 0x1_ or 0x3_)
    else {
      return nibbles.sublist(1);
    }
  }

  static bool isLeaf(Uint8List encodedPath) {
    return (encodedPath[0] & 0x20) != 0;
  }
}

/// Handles nibble operations (half-byte values 0-F)
class Nibbles {
  /// Convert bytes to nibbles (each byte → 2 nibbles)
  static List<int> fromBytes(Uint8List bytes) {
    final nibbles = <int>[];
    for (final byte in bytes) {
      nibbles.add(byte >> 4);      // High nibble
      nibbles.add(byte & 0x0f);    // Low nibble
    }
    return nibbles;
  }

  /// Check if nibble lists match starting at offset
  static bool match(List<int> key, int keyOffset, List<int> path) {
    if (keyOffset + path.length > key.length) return false;

    for (int i = 0; i < path.length; i++) {
      if (key[keyOffset + i] != path[i]) return false;
    }
    return true;
  }
}

/// Cryptographic operations
class Crypto {

  static bool bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Hex string utilities
class HexUtil {
  static Uint8List decode(String hex) {
    if (hex.startsWith('0x')) hex = hex.substring(2);
    if (hex.isEmpty) return Uint8List(0);
    return Uint8List.fromList(HEX.decode(hex));
  }

  static String encode(Uint8List bytes) {
    return '0x${HEX.encode(bytes)}';
  }

  /// Remove leading zeros for minimal representation
  static Uint8List toMinimal(String hex) {
    if (hex.startsWith('0x')) hex = hex.substring(2);
    if (hex.isEmpty || hex == '0') return Uint8List(0);

    hex = hex.replaceFirst(RegExp(r'^0+'), '');
    if (hex.isEmpty) return Uint8List(0);
    if (hex.length % 2 != 0) hex = '0$hex';

    return hexToBytes(hex);
  }
}

// ============================================================================
// EXCEPTIONS
// ============================================================================

class ProofVerificationException implements Exception {
  final String message;
  ProofVerificationException(this.message);

  @override
  String toString() => 'ProofVerificationException: $message';
}

class InvalidNodeException extends ProofVerificationException {
  InvalidNodeException(super.message);
}

class HashMismatchException extends ProofVerificationException {
  final int nodeIndex;
  final String expected;
  final String actual;

  HashMismatchException(this.nodeIndex, this.expected, this.actual)
    : super('Hash mismatch at node $nodeIndex: expected $expected, got $actual');
}

class ProofVerifier {
  /// Verify a Merkle Patricia Trie proof
  ///
  /// Returns true if the proof is valid, false otherwise.
  /// Throws ProofVerificationException with details on failure.
  static bool verifyProof({
    required Uint8List rootHash,
    required Uint8List key,
    required List<String> proof,
    Uint8List? expectedValue,
  }) {
    // Convert key to nibbles and hash it
    final keyNibbles = Nibbles.fromBytes(keccak256(key));

    // Track our position in the key path
    int nibbleIndex = 0;

    // Start verification from the root
    Uint8List expectedHash = rootHash;

    // Walk through each node in the proof
    for (int i = 0; i < proof.length; i++) {
      final nodeRlp = HexUtil.decode(proof[i]);

      // Verify this node hashes to what we expect
      _verifyNodeHash(i, nodeRlp, expectedHash);

      // Parse the node
      final node = MptNode.fromRlp(nodeRlp);

      // Process based on node type
      switch (node) {
        case BranchNode():
          final result = _processBranchNode(
            node,
            keyNibbles,
            nibbleIndex,
            expectedValue,
          );
          nibbleIndex = result.nibbleIndex;
          expectedHash = result.nextHash;

          // If nextHash is empty, key doesn't exist - verification complete
          if (expectedHash.isEmpty) {
            return true;
          }

        case ExtensionNode():
          final result = _processExtensionNode(
            node,
            keyNibbles,
            nibbleIndex,
            expectedValue,
          );
          nibbleIndex = result.nibbleIndex;
          expectedHash = result.nextHash;

          // If nextHash is empty, key doesn't exist - verification complete
          if (expectedHash.isEmpty) {
            return true;
          }

        case LeafNode():
          return _processLeafNode(
            node,
            keyNibbles,
            nibbleIndex,
            expectedValue,
          );
      }
    }

    // If we get here, proof is incomplete
    return false;
  }

  /// Verify node hash matches expected
  static void _verifyNodeHash(int index, Uint8List nodeRlp, Uint8List expectedHash) {
    final actualHash = nodeRlp.length >= 32
      ? keccak256(nodeRlp)
      : nodeRlp;

    if (!Crypto.bytesEqual(expectedHash, actualHash)) {
      throw HashMismatchException(
        index,
        HexUtil.encode(expectedHash),
        HexUtil.encode(actualHash),
      );
    }
  }

  /// Process branch node
  static ({int nibbleIndex, Uint8List nextHash}) _processBranchNode(
    BranchNode node,
    List<int> keyNibbles,
    int nibbleIndex,
    Uint8List? expectedValue,
  ) {
    // If we've consumed all nibbles, check the value at this branch
    if (nibbleIndex >= keyNibbles.length) {
      final matches = expectedValue == null
        ? node.value.isEmpty
        : Crypto.bytesEqual(node.value, expectedValue);

      if (!matches) {
        throw ProofVerificationException('Value mismatch at branch node');
      }
      return (nibbleIndex: nibbleIndex, nextHash: Uint8List(0));
    }

    // Follow the path based on next nibble
    final nibble = keyNibbles[nibbleIndex];
    final child = node.getChild(nibble);

    if (child == null) {
      // Path doesn't exist
      if (expectedValue != null && expectedValue.isNotEmpty) {
        throw ProofVerificationException('Path not found in branch node');
      }
      return (nibbleIndex: nibbleIndex + 1, nextHash: Uint8List(0));
    }

    return (
      nibbleIndex: nibbleIndex + 1,
      nextHash: child,
    );
  }

  /// Process extension node
  static ({int nibbleIndex, Uint8List nextHash}) _processExtensionNode(
    ExtensionNode node,
    List<int> keyNibbles,
    int nibbleIndex,
    Uint8List? expectedValue,
  ) {
    // Verify path matches
    if (!Nibbles.match(keyNibbles, nibbleIndex, node.path)) {
      // Path doesn't match - key doesn't exist
      if (expectedValue != null && expectedValue.isNotEmpty) {
        throw ProofVerificationException('Path mismatch in extension node');
      }
      return (nibbleIndex: nibbleIndex, nextHash: Uint8List(0));
    }

    return (
      nibbleIndex: nibbleIndex + node.path.length,
      nextHash: node.next,
    );
  }

  /// Process leaf node (final check)
  static bool _processLeafNode(
    LeafNode node,
    List<int> keyNibbles,
    int nibbleIndex,
    Uint8List? expectedValue,
  ) {
    // Verify path matches
    if (!Nibbles.match(keyNibbles, nibbleIndex, node.path)) {
      return expectedValue == null || expectedValue.isEmpty;
    }

    // Verify we've consumed entire key
    if (nibbleIndex + node.path.length != keyNibbles.length) {
      return false;
    }

    // Verify value matches
    if (expectedValue == null) {
      return node.value.isEmpty;
    }

    return Crypto.bytesEqual(node.value, expectedValue);
  }

  /// Verify account proof against state root
  static bool verifyAccountProof({
    required String stateRoot,
    required String address,
    required Map<String, dynamic> proof,
  }) {
    final stateRootBytes = HexUtil.decode(stateRoot);
    final addressBytes = HexUtil.decode(address);
    final accountProof = (proof['accountProof'] as List).cast<String>();

    final nonce = proof['nonce'] as String;
    final balance = proof['balance'] as String;
    final storageHash = proof['storageHash'] as String;
    final codeHash = proof['codeHash'] as String;

    // Check if account doesn't exist (all default/empty values)
    // keccak256(RLP(Uint8List(0))), verify the value here https://github.com/ethereum/go-ethereum/blob/v1.16.7/core/types/hashes.go, or run an eth_getProof request on a fresh EOA
    const emptyStorageHash = '0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421';
    // keccak256(Uint8List(0)), verify the value here https://github.com/ethereum/go-ethereum/blob/v1.16.7/core/types/hashes.go, or run an eth_getProof request on a fresh EOA
    const emptyCodeHash = '0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470';
    const zeroHash = '0x0000000000000000000000000000000000000000000000000000000000000000';

    final accountDoesNotExist =
      (nonce == '0x0' || nonce == '0x') &&
      (balance == '0x0' || balance == '0x') &&
      (storageHash.toLowerCase() == emptyStorageHash || storageHash.toLowerCase() == zeroHash) &&
      (codeHash.toLowerCase() == emptyCodeHash || codeHash.toLowerCase() == zeroHash);

    Uint8List? accountRlp;
    if (!accountDoesNotExist) {
      // Account exists - verify its values
      accountRlp = RLP.encode([
        HexUtil.toMinimal(nonce),
        HexUtil.toMinimal(balance),
        HexUtil.decode(storageHash),
        HexUtil.decode(codeHash),
      ]);
    }
    // If accountDoesNotExist, accountRlp stays null to verify absence

    return verifyProof(
      rootHash: stateRootBytes,
      key: addressBytes,
      proof: accountProof,
      expectedValue: accountRlp,
    );
  }

  /// Verify storage proof against storage root
  static bool verifyStorageProof({
    required String storageHash,
    required String storageKey,
    required String storageValue,
    required List<String> storageProof,
  }) {
    final storageRootBytes = HexUtil.decode(storageHash);
    final keyBytes = HexUtil.decode(storageKey);
    final valueBytes = HexUtil.decode(storageValue);

    // Encode value in RLP if not empty
    Uint8List? expectedValue;
    if (valueBytes.isNotEmpty &&
        !(valueBytes.length == 1 && valueBytes[0] == 0)) {
      expectedValue = RLP.encode(valueBytes);
    }

    return verifyProof(
      rootHash: storageRootBytes,
      key: keyBytes,
      proof: storageProof,
      expectedValue: expectedValue,
    );
  }
}
