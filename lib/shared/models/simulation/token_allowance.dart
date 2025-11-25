import 'package:safe_verify/shared/models/network_model.dart';
import 'package:safe_verify/shared/models/simulation/token_metadata.dart';
import 'package:wallet/wallet.dart';

class TokenAllowance {
  EthereumAddress token;
  EthereumAddress spender;
  BigInt amount;
  Network network;
  TokenMetadata? metadata;

  TokenAllowance({
    required this.token,
    required this.spender,
    required this.amount,
    required this.network,
    this.metadata
  });

  Future<void> fetchMetadata() async {
    metadata = await TokenMetadata.fromAddress(token, network);
  }
}