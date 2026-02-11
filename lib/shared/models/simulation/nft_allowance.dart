import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/models/simulation/nft_metadata.dart';
import 'package:wallet/wallet.dart';

class NFTAllowance {
  EthereumAddress collection;
  EthereumAddress spender;
  BigInt? tokenId; // null for ApprovalForAll
  bool isApprovalForAll;
  bool approved; // only relevant for ApprovalForAll (true = grant, false = revoke)
  Network network;
  NFTMetadata? metadata;

  NFTAllowance({
    required this.collection,
    required this.spender,
    this.tokenId,
    this.isApprovalForAll = false,
    this.approved = true,
    required this.network,
    this.metadata
  });

  Future<void> fetchMetadata() async {
    metadata = await NFTMetadata.fromAddress(collection, tokenId ?? BigInt.zero, network);
    if (metadata != null){
      await metadata!.fetchTokenMetadata();
    }
  }
}