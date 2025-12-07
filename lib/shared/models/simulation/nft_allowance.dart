import 'package:safe_verify/shared/models/network_model.dart';
import 'package:safe_verify/shared/models/simulation/nft_metadata.dart';
import 'package:wallet/wallet.dart';

class NFTAllowance {
  EthereumAddress collection;
  EthereumAddress spender;
  BigInt tokenId;
  Network network;
  NFTMetadata? metadata;

  NFTAllowance({
    required this.collection,
    required this.spender,
    required this.tokenId,
    required this.network,
    this.metadata
  });

  Future<void> fetchMetadata() async {
    metadata = await NFTMetadata.fromAddress(collection, tokenId, network);
    if (metadata != null){
      await metadata!.fetchTokenMetadata();
    }
  }
}