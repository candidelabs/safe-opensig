import 'package:safe_verify/shared/models/network_model.dart';
import 'package:safe_verify/shared/models/simulation/nft_metadata.dart';
import 'package:wallet/wallet.dart';

class NFTTransfer {
  EthereumAddress collection;
  EthereumAddress sender;
  EthereumAddress recipient;
  BigInt tokenId;
  Network network;
  NFTMetadata? metadata;

  NFTTransfer({
    required this.collection,
    required this.sender,
    required this.recipient,
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