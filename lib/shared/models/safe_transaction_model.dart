import 'dart:convert';
import 'dart:typed_data';

import 'package:safe_verify/shared/constants/safe_hashes.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';
import 'package:safe_verify/shared/models/simulation/evm_tracer.dart';
import 'package:safe_verify/shared/models/simulation/simulation_phase.dart';
import 'package:safe_verify/shared/models/simulation/simulation_result.dart';
import 'package:safe_verify/shared/models/simulation/state_verifier/evm_state_verifier.dart';
import 'package:safe_verify/shared/models/simulation/trace_decoder.dart';
import 'package:safe_verify/shared/utils/abi_utils.dart';
import 'package:safe_verify/shared/utils/extensions/bigint_extensions.dart';
import 'package:safe_verify/shared/utils/utilities.dart';
import 'package:version/version.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class SafeTransaction {
  String to;
  BigInt value;
  String data;
  int operation;
  BigInt safeTxGas;
  BigInt baseGas;
  BigInt gasPrice;
  String gasToken;
  String refundReceiver;
  BigInt? nonce;
  BigInt? latestNonce;

  SafeTransaction({
    required this.to,
    required this.value,
    required this.data,
    required this.operation,
    required this.safeTxGas,
    required this.baseGas,
    required this.gasPrice,
    required this.gasToken,
    required this.refundReceiver,
    this.nonce,
    this.latestNonce,
  });

  factory SafeTransaction.fromJson(Map<String, dynamic> json, bool legacyJson) {
    return SafeTransaction(
      to: json['to'] as String,
      value: json['value'] as BigInt,
      data: json['data'] as String,
      operation: json['operation'] as int,
      safeTxGas: json['safeTxGas'] as BigInt,
      baseGas: (legacyJson ? json['dataGas'] : json['baseGas']) as BigInt,
      gasPrice: json['gasPrice'] as BigInt,
      gasToken: json['gasToken'] as String,
      refundReceiver: json['refundReceiver'] as String,
      nonce: json.containsKey('nonce') ? BigInt.from(json['nonce'] as int) : null,
    );
  }

  /// Ensures nonce is set by fetching it from the account if not already set
  /// Also fetches and stores the latest nonce from the account for simulation
  Future<(bool, String)> ensureNonce(SafeAccount account) async {
    final fetchedNonce = await account.getNonce();
    if (fetchedNonce == null) {
      return (false, 'Failed to fetch nonce');
    }
    latestNonce = fetchedNonce;
    // If nonce is not set (CallData input), use the latest nonce
    if (nonce == null) {
      nonce = fetchedNonce;
    }
    return (true, '');
  }

  bool get hasNonceMismatch => nonce != null && latestNonce != null && nonce != latestNonce;

  Future<(List<String>, List<(String, String)>)> _getTransactionTracingSignatures(SafeAccount account, String transactionHash) async {
    List<String> signatures = [];
    List<(String, String)> storageLocationsOverrides = [];
    //
    var _owners = await account.network.provider.callRaw(
      contract: EthereumAddress.fromHex(account.address),
      data: hexToBytes("0xa0e67e2b")
    );
    var owners = (decodeAbi(["address[]"], hexToBytes(_owners))[0] as List<dynamic>).cast<EthereumAddress>();
    owners.sort((a, b) => a.compareTo(b));
    //
    var _threshold = await account.network.provider.callRaw(
      contract: EthereumAddress.fromHex(account.address),
      data: hexToBytes("0xe75235b8")
    );
    var threshold = Utilities.decodeBigInt(_threshold)!.toInt();
    //
    for (int i=0; i<threshold; i++){
      var owner = owners[i];
      var base = keccak256(encodeAbi(["uint256", "uint256"], [Utilities.decodeBigInt(owner.with0x), BigInt.from(8)]));
      var storageLocation = keccak256(encodeAbi(["uint256", "uint256"], [Utilities.decodeBigInt(transactionHash), Utilities.decodeBigInt(bytesToHex(base, include0x: true))]));
      storageLocationsOverrides.add((bytesToHex(storageLocation, include0x: true), "0x0000000000000000000000000000000000000000000000000000000000000001"));
      signatures.add("0x000000000000000000000000${owner.without0x}000000000000000000000000000000000000000000000000000000000000000001");
    }
    //
    return (signatures, storageLocationsOverrides);
  }

  String getTransactionCallData(SafeAccount account, List<String> signatures) {
    Uint8List callData = encodeAbi(
      [
        "address",
        "uint256",
        "bytes",
        "uint8",
        "uint256",
        "uint256",
        "uint256",
        "address",
        "address",
        "bytes",
      ],
      [
        EthereumAddress.fromHex(to),
        value,
        hexToBytes(data),
        BigInt.from(operation),
        safeTxGas,
        baseGas,
        gasPrice,
        EthereumAddress.fromHex(gasToken),
        EthereumAddress.fromHex(refundReceiver),
        hexToBytes("0x${signatures.map((e) => e.replaceFirst("0x", "")).join("")}"),
      ]
    );
    return "0x6a761202${bytesToHex(callData, include0x: false)}";
  }

  Future<(bool, String)> getMessageHash(SafeAccount account, {bool useLatestNonce = false}) async {
    String safeTxTypeHash = SAFE_TX_TYPEHASH;
    var accountVersion = Version.parse(account.version);
    if (accountVersion < Version.parse("1.0.0")){
      safeTxTypeHash = SAFE_TX_TYPEHASH_OLD;
    }
    final (success, error) = await ensureNonce(account);
    if (!success) {
      return (false, error);
    }
    // Use latestNonce for simulation, nonce for hash verification
    final nonceToUse = useLatestNonce ? latestNonce! : nonce!;
    Uint8List message = encodeAbi(
        [
          "bytes32",
          "address",
          "uint256",
          "bytes32",
          "uint8",
          "uint256",
          "uint256",
          "uint256",
          "address",
          "address",
          "uint256",
        ],
        [
          hexToBytes(safeTxTypeHash),
          EthereumAddress.fromHex(to),
          value,
          keccak256(hexToBytes(data)),
          BigInt.from(operation),
          safeTxGas,
          baseGas,
          gasPrice,
          EthereumAddress.fromHex(gasToken),
          EthereumAddress.fromHex(refundReceiver),
          nonceToUse,
        ]
    );
    var messageHash = bytesToHex(keccak256(message), include0x: true);
    return (true, messageHash);
  }

  String getTransactionHash(String domainHash, String messageHash) {
    var transactionData = solidityPack(
        ["bytes1", "bytes1", "bytes32", "bytes32"],
        [Uint8List.fromList([0x19]), Uint8List.fromList([0x01]), hexToBytes(domainHash), hexToBytes(messageHash)]
    );
    var txHash = bytesToHex(keccak256(transactionData), include0x: true);
    return txHash;
  }

  Future<(bool, String, String, String)> calculateHashes(SafeAccount account, {bool useLatestNonce = false}) async {
    final (success, error) = await ensureNonce(account);
    if (!success) {
      return (false, error, '', '');
    }
    var domainHash = account.getDomainHash();
    var (msgSuccess, messageHash) = await getMessageHash(account, useLatestNonce: useLatestNonce);
    if (!msgSuccess){
      return (false, "Failed to calculate message hash", '', '');
    }
    var txHash = getTransactionHash(domainHash, messageHash);
    return (true, domainHash, messageHash, txHash);
  }

  Future<(bool, SimulationResult?, String)> simulate(
    SafeAccount account, {
    void Function(SimulationPhase)? onPhaseChange,
  }) async {
    try {
      final (nonceSuccess, nonceError) = await ensureNonce(account);
      if (!nonceSuccess) return (false, null, nonceError);
      // Fetching prestate
      onPhaseChange?.call(SimulationPhase.fetchingPrestate);
      // Use latestNonce for simulation to bypass on-chain nonce verification
      var (hashesSuccess, domainHash, messageHash, txHash) = await calculateHashes(account, useLatestNonce: true);
      if (!hashesSuccess) return (false, null, domainHash);
      var (signatures, storageLocationsOverrides) = await _getTransactionTracingSignatures(account, txHash);
      var evmTracer = EVMTracer(provider: account.network.provider);
      var from = Utilities.generateRandomEthereumAddress();
      var callData  = getTransactionCallData(account, signatures);
      var accountAddress = account.address.toLowerCase();
      var stateOverrides = <String, dynamic>{};
      stateOverrides[accountAddress] = {"stateDiff":{}};
      stateOverrides[from] = {"balance": BigInt.parse("1000000000000000000000").toHex()};
      for (var locationOverride in storageLocationsOverrides){
        stateOverrides[accountAddress]["stateDiff"][locationOverride.$1] = locationOverride.$2;
      }
      var (block, prestate) = await evmTracer.getTransactionPrestate(
        from,
        accountAddress,
        callData,
        stateOverrides
      );
      // Verifying state
      onPhaseChange?.call(SimulationPhase.verifyingState);
      // Create state verifier
      var stateVerifier = EVMStateVerifier(
        proofNodeClient: account.network.provider,
        verificationNodesClients: account.network.providers,
      );
      // Extract block number and state root for verification
      var blockNumber = BigInt.parse(block['number']);
      var (_stateRootSucccess, stateRoot, _stateRootError) = await stateVerifier.getConsensusStateRoot(blockNumber: blockNumber);
      if (!_stateRootSucccess) {
        return (false, null, _stateRootError);
      }
      // Verify accounts in prestate with cryptographic proofs
      for (var entry in prestate.entries) {
        var prestateAccountAddress = EthereumAddress.fromHex(entry.key);
        var accountData = jsonDecode(jsonEncode(entry.value)) as Map<String, dynamic>;
        if (prestateAccountAddress.with0x == from.toLowerCase()) continue; // skip the "from" account since this account is just for simulation purposes and doesn't have to be verified
        var storage = (accountData['storage'] ?? <String, dynamic>{}) as Map<String, dynamic>;
        // Remove overridden storage values from prestate
        if (stateOverrides.containsKey(prestateAccountAddress.with0x)){
          var stateDiff = ((stateOverrides[prestateAccountAddress.with0x]["stateDiff"] ?? {}) as Map<dynamic, dynamic>).cast<String, String>();
          for (var stateDiffKey in stateDiff.keys){
            storage.remove(stateDiffKey);
          }
        }
        //
        var storageKeys = storage.keys.toSet();
        var expectedStorageValues = storage.cast<String, String>();
        // Avoid verifying storage values for accounts that have no code; these accounts are not yet deployed and appear in the prestate because they are created by the transaction.
        if (!accountData.containsKey("code")){
          storageKeys = {};
          expectedStorageValues = {};
        }
        // Verify account state with cryptographic proof
        var (success, error) = await stateVerifier.verify(
          account: prestateAccountAddress,
          storageKeys: storageKeys,
          expectedStorageValues: expectedStorageValues,
          blockNumber: blockNumber,
          stateRoot: stateRoot,
        );
        if (!success) {
          return (false, null, "State verification failed for ${prestateAccountAddress.with0x}: $error");
        }
      }
      var accountSingleton = decodeAbi(["address"], hexToBytes(prestate[accountAddress]["storage"]["0x0000000000000000000000000000000000000000000000000000000000000000"]))[0] as EthereumAddress;
      onPhaseChange?.call(SimulationPhase.simulating);
      var trace = await evmTracer.revmTrace(from, accountAddress, callData, (block, prestate), false);
      // Decode the simulation result
      var simulationResult = TraceDecoder(accountSingleton: accountSingleton.with0x.toLowerCase()).decode(
        account.address,
        this,
        account.network,
        jsonDecode(trace)
      );
      return (true, simulationResult, "");
    } catch (e) {
      print(e);
      return (false, SimulationResult(
          success: false,
          revertReason: "0x",
          dangerous: (false, null, null),
          transfers: [],
          allowances: [],
          nftTransfers: [],
          nftAllowances: [],
          safeSettingsChanges: [],
          warningTransactions: []
      ), e.toString());
    }
  }

}
