import 'package:safe_verify/shared/models/simulation/nft_allowance.dart';
import 'package:safe_verify/shared/models/simulation/nft_transfer.dart';
import 'package:safe_verify/shared/models/simulation/safe_setting_change.dart';
import 'package:safe_verify/shared/models/simulation/token_allowance.dart';
import 'package:safe_verify/shared/models/simulation/token_transfer.dart';
import 'package:safe_verify/shared/models/simulation/warning_transaction.dart';

enum DangerousTransactionType {
  SINGLETON_CHANGE,
}

class SimulationResult {
  bool success;
  String revertReason;
  (bool, DangerousTransactionType?, dynamic) dangerous;
  List<TokenTransfer> transfers;
  List<TokenAllowance> allowances;
  List<NFTTransfer> nftTransfers;
  List<NFTAllowance> nftAllowances;
  List<SafeSettingChange> safeSettingsChanges;
  List<WarningTransaction> warningTransactions;

  SimulationResult({
    required this.success,
    required this.revertReason,
    required this.dangerous,
    required this.transfers,
    required this.allowances,
    required this.nftTransfers,
    required this.nftAllowances,
    required this.safeSettingsChanges,
    required this.warningTransactions,
  });

  Future<void> loadTokenMetadatas() async {
    var futures = <Future>[];
    var visitedTokens = <String>{};
    var visitedNFTs = <String>{};

    // Load ERC20 token metadata
    for (var transfer in transfers){
      var tokenAddress = transfer.token.with0x;
      if (visitedTokens.contains(tokenAddress)) continue;
      visitedTokens.add(tokenAddress);
      futures.add(transfer.fetchMetadata());
    }
    for (var allowance in allowances){
      var tokenAddress = allowance.token.with0x;
      if (visitedTokens.contains(tokenAddress)) continue;
      visitedTokens.add(tokenAddress);
      futures.add(allowance.fetchMetadata());
    }

    // Load NFT metadata
    for (var nftTransfer in nftTransfers){
      var nftIdentifier = '${nftTransfer.collection.with0x}_${nftTransfer.tokenId}';
      if (visitedNFTs.contains(nftIdentifier)) continue;
      visitedNFTs.add(nftIdentifier);
      futures.add(nftTransfer.fetchMetadata());
    }
    for (var nftAllowance in nftAllowances){
      var nftIdentifier = '${nftAllowance.collection.with0x}_${nftAllowance.tokenId}';
      if (visitedNFTs.contains(nftIdentifier)) continue;
      visitedNFTs.add(nftIdentifier);
      futures.add(nftAllowance.fetchMetadata());
    }

    // Fetch metadata of distinct set of tokens and NFTs
    await Future.wait(futures);

    // Then fetch metadata that are still null (recurring tokens, will fetch from cache)
    for (var transfer in transfers){
      if (transfer.metadata == null){
        await transfer.fetchMetadata();
      }
    }
    for (var allowance in allowances){
      if (allowance.metadata == null){
        await allowance.fetchMetadata();
      }
    }
    for (var nftTransfer in nftTransfers){
      if (nftTransfer.metadata == null){
        await nftTransfer.fetchMetadata();
      }
    }
    for (var nftAllowance in nftAllowances){
      if (nftAllowance.metadata == null){
        await nftAllowance.fetchMetadata();
      }
    }
  }
}
