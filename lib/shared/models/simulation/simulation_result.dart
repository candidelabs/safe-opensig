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
  List<SafeSettingChange> safeSettingsChanges;
  List<WarningTransaction> warningTransactions;

  SimulationResult({
    required this.success,
    required this.revertReason,
    required this.dangerous,
    required this.transfers,
    required this.allowances,
    required this.safeSettingsChanges,
    required this.warningTransactions,
  });

  Future<void> loadTokenMetadatas() async {
    var futures = <Future>[];
    var visitedTokens = <String>{};
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
    // Fetch metadata of distinct set of tokens
    await Future.wait(futures);
    // Then fetch metadata of metadata that are still null (recurring tokens, will fetch from cache)
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
  }
}
