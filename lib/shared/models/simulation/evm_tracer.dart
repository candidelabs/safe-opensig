import 'dart:convert';

import 'package:revm_tracer/revm_tracer.dart';
import 'package:safe_opensig/shared/utils/extensions/bigint_extensions.dart';
import 'package:safe_opensig/shared/utils/utilities.dart';
import 'package:web3dart/web3dart.dart';

/// Upper bound on the gas given to a simulated transaction.
const int maxSimulationGas = 100000000;

/// Gas limit for the simulated transaction: the block's gas limit, capped at [maxSimulationGas].
/// Arbitrum reports a block gas limit of 2^50; at the simulated gas price, prepaying that much gas
/// costs more than the simulated sender's balance, and the simulation fails before it starts.
BigInt simulationGasLimit(BigInt blockGasLimit) {
  final cap = BigInt.from(maxSimulationGas);
  return blockGasLimit < cap ? blockGasLimit : cap;
}

class EVMTracer {
  static bool rustLibInitiated = false;
  late Web3Client provider;

  EVMTracer({required this.provider});

  Future<(Map<String, dynamic>, Map<String, dynamic>)> getTransactionPrestate(
    String from,
    String to,
    String data,
    Map<String, dynamic> overrides
  ) async {
    var _blockNumberHex = await provider.makeRPCCall("eth_blockNumber", []);
    var blockNumber = BigInt.parse(_blockNumberHex.replaceFirst("0x", ""), radix: 16) - BigInt.one;
    Map<String, dynamic>? prestate;
    int retries = 0;
    while (retries < 10){
      try {
        prestate = (await provider.makeRPCCall(
          'debug_traceCall',
          [
            {
              "from": from,
              "to": to,
              "data": data,
            },
            blockNumber.toHex(),
            {
              "tracer": "prestateTracer",
              "stateOverrides": overrides
            },
          ],
        )) as Map<String, dynamic>;
        break;
      } catch (e) {
        print("Retrying debug_traceCall ($retries): $e");
        retries++;
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    if (prestate == null){
      throw "debug_traceCall failed to fetch prestate at block #$blockNumber";
    }
    var block = (await provider.makeRPCCall("eth_getBlockByNumber", [blockNumber.toHex(), false])) as Map<String, dynamic>;
    return (block, prestate);
  }

  Future<dynamic> revmTrace(
      String from,
      String to,
      String data,
      (Map<String, dynamic>, Map<String, dynamic>)? prestate,
      bool isOpStack,
  ) async {
    prestate ??= await getTransactionPrestate(from, to, data, {});
    if (!rustLibInitiated){
      await RustLib.init();
      rustLibInitiated = true;
    }
    var block = prestate.$1;
    var baseFeePerGas = Utilities.decodeBigInt(block["baseFeePerGas"])!.scale(1.25);
    var gasLimit = simulationGasLimit(Utilities.decodeBigInt(block["gasLimit"])!);
    var blockRaw = jsonEncode(prestate.$1);
    var traceRaw = jsonEncode(prestate.$2);
    var chainId = await provider.getChainId();
    var traceResult = RevmTracer.revmTrace(
      chainId: chainId,
      from: from,
      fromNonce: BigInt.from(0),
      to: to,
      data: data,
      gasLimit: gasLimit,
      gasPrice: baseFeePerGas,
      gasPriorityFee: baseFeePerGas,
      latestBlockEnv: blockRaw,
      prestateTracerResult: traceRaw,
      isOpStack: isOpStack
    );
    return traceResult;
  }

}