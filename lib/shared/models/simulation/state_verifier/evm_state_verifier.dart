import 'dart:math';

import 'package:safe_opensig/shared/models/simulation/state_verifier/proof_verifier.dart';
import 'package:safe_opensig/shared/utils/extensions/bigint_extensions.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class EVMStateVerifier {
  Web3Client proofNodeClient;
  List<Web3Client> verificationNodesClients;

  EVMStateVerifier({required this.proofNodeClient, required this.verificationNodesClients});

  Future<(bool, String, String)> getConsensusStateRoot({required BigInt blockNumber}) async {
    String? stateRoot;
    if (verificationNodesClients.isEmpty){
      return (false, "", "State root is not provided and verification nodes list is empty");
    }
    var consensusThreshold = max((verificationNodesClients.length / 2).floor(), 1);
    var index = 0;
    var failedClients = 0;
    for (var client in verificationNodesClients){
      try {
        final block = await client.makeRPCCall('eth_getBlockByNumber', [blockNumber.toHex(), false]);
        final _stateRoot = block['stateRoot'] as String;
        if (stateRoot == null){
          stateRoot = _stateRoot;
        }else{
          if (stateRoot != _stateRoot){
            return (false, "", "Verification nodes do not agree on the state root!");
          }
        }
      } catch (e) {
        print("Fetching stateRoot for node #$index");
        failedClients++;
      }
      index++;
    }
    if ((verificationNodesClients.length-failedClients) < consensusThreshold){
      return (false, "", "Not enough verification nodes are available to reach consensus on the block's state root");
    }
    return (true, stateRoot!, "");
  }

  Future<(bool, String)> verify({
    required EthereumAddress account,
    required Set<String> storageKeys,
    required Map<String, String> expectedStorageValues,
    required BigInt blockNumber,
    String? stateRoot
  }) async {
    try {
      // Get proof from proof node
      final proof = await proofNodeClient.makeRPCCall('eth_getProof', [
        account.with0x,
        storageKeys.toList(),
        blockNumber.toHex(),
      ]);

      // Fetch state roots from all verification nodes and verify state root consensus (or use provided state root if available)
      if (stateRoot == null){
        var (_succcess, _stateRoot, _error) = await getConsensusStateRoot(blockNumber: blockNumber);
        if (!_succcess){
          return (false, _error);
        }
        stateRoot = _stateRoot;
      }

      // Verify account proof
      final accountValid = ProofVerifier.verifyAccountProof(
        stateRoot: stateRoot,
        address: account.with0x,
        proof: proof,
      );

      if (!accountValid) {
        return (false, "Account proof for ${account.with0x} is INVALID");
      }

      // Verify storage proofs
      final storageProofs = proof['storageProof'] as List;
      for (var i = 0; i < storageProofs.length; i++) {
        final storageProof = storageProofs[i] as Map<String, dynamic>;
        final key = storageProof['key'] as String;
        final value = storageProof['value'] as String;
        final proofArray = (storageProof['proof'] as List).cast<String>();
        // Verify the storage proof
        final storageValid = ProofVerifier.verifyStorageProof(
          storageHash: proof['storageHash'],
          storageKey: key,
          storageValue: value,
          storageProof: proofArray,
        );

        if (storageValid) {
          // Check if value matches expected
          final expectedValue = expectedStorageValues[key];
          if (expectedValue != null) {
            // Normalize both values by removing leading zeros for comparison
            String normalizedValue = _normalizeHex(value);
            String normalizedExpected = _normalizeHex(expectedValue);

            if (normalizedValue != normalizedExpected) {
              return (false, "Expected values mismatch, expected $expectedValue, got $value (${account.with0x})");
            }
          }
        } else {
          return (false, "Storage proof is INVALID for key $key (${account.with0x})");
        }
      }
      return (true, '');
    } catch (e) {
      return (false, "eth_getProof RPC call failed: $e");
    }
  }
}

String _normalizeHex(String hex) {
  if (hex.startsWith('0x')) {
    hex = hex.substring(2);
  }
  // Remove leading zeros but keep at least one zero for '0x0'
  hex = hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  if (hex.isEmpty) {
    hex = '0';
  }
  return '0x$hex'.toLowerCase();
}
