import 'package:flutter_test/flutter_test.dart';
import 'package:safe_opensig/shared/models/simulation/evm_tracer.dart';

void main() {
  group('simulationGasLimit', () {
    test('uses the block gas limit when it is below the cap (Ethereum, OP-stack)', () {
      expect(simulationGasLimit(BigInt.from(36000000)), BigInt.from(36000000));
    });

    test('caps a huge block gas limit (Arbitrum reports 2^50)', () {
      expect(simulationGasLimit(BigInt.two.pow(50)), BigInt.from(maxSimulationGas));
    });

    test('the capped prepayment fits the simulated sender balance at Arbitrum gas prices', () {
      final gasPrice = BigInt.from(25000000); // 0.02 gwei x 1.25
      final senderBalance = BigInt.parse('1000000000000000000000'); // 1000 ETH, as in the simulation
      expect(simulationGasLimit(BigInt.two.pow(50)) * gasPrice < senderBalance, isTrue);
      expect(BigInt.two.pow(50) * gasPrice < senderBalance, isFalse); // the old behavior
    });
  });
}
