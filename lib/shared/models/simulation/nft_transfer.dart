import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/models/simulation/nft_metadata.dart';
import 'package:safe_opensig/shared/utils/abi_utils.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class NFTTransfer {
  EthereumAddress collection;
  EthereumAddress sender;
  EthereumAddress recipient;
  BigInt tokenId;
  BigInt? amount; // ERC-1155 quantity (null for ERC-721, which is always 1)
  int? decimals; // ERC-1155 decimals (fetched best-effort, null if not available)
  Network network;
  NFTMetadata? metadata;

  NFTTransfer({
    required this.collection,
    required this.sender,
    required this.recipient,
    required this.tokenId,
    this.amount,
    this.decimals,
    required this.network,
    this.metadata
  });

  Future<void> fetchMetadata() async {
    metadata = await NFTMetadata.fromAddress(collection, tokenId, network);
    if (metadata != null){
      await metadata!.fetchTokenMetadata();
    }
    // Try to fetch decimals for ERC-1155 tokens
    if (amount != null && decimals == null) {
      try {
        // decimals() selector: 0x313ce567
        var result = await network.provider.callRaw(
          contract: collection,
          data: hexToBytes("0x313ce567"),
        );
        var decoded = decodeAbi(["uint8"], hexToBytes(result));
        decimals = (decoded[0] as BigInt).toInt();
      } catch (_) {
        // Not implemented - leave decimals as null
      }
    }
  }
}