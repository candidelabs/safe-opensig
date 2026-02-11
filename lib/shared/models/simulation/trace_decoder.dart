import 'package:safe_opensig/shared/constants/constants.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/models/simulation/nft_allowance.dart';
import 'package:safe_opensig/shared/models/simulation/nft_transfer.dart';
import 'package:safe_opensig/shared/models/simulation/safe_setting_change.dart';
import 'package:safe_opensig/shared/models/simulation/simulation_result.dart';
import 'package:safe_opensig/shared/models/simulation/token_allowance.dart';
import 'package:safe_opensig/shared/models/simulation/token_transfer.dart';
import 'package:safe_opensig/shared/models/simulation/warning_transaction.dart';
import 'package:safe_opensig/shared/utils/abi_utils.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

var _logsMapping = {
  "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "token-transfer",
  "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925": "token-allowance-change",
  //
  "0x9465fa0c962cc76958e6373a993326400c1c94f8be2fe3a952adfa7f60b2ea26": "safe-owner-addition",
  "0xf8d49fc529812e9a7c5c50e69c20f0dccc0db8fa95c98bc58cc9a4f1c1299eaf": "safe-owner-revocation",
  "0x610f7ff2b304ae8903c3de74c60c6ab1f7d6226b3f52c5161905bb5ad4039c93": "safe-threshold-change",
  //
  "0xecdf3a3effea5783a3c4c2140e677577666428d44ed9d474a0b3a4c9943f8440": "safe-module-enable",
  "0xaab4fa2b463f581b2b32cb3b7e3b704b9ce37cc209b5fb4d77e593ace4054276": "safe-module-disable",
  "0xcd1966d6be16bc0c030cc741a06c6e0efaf8d00de2c8b6a9e11827e125de8bb8": "safe-module-guard-change",
  //
  "0x1151116914515bc0891ff9047a6cb32cf902546f83066499bcf8ba33d2353fa2": "safe-guard-change",
};

var _trustedDelegatees = {
  // MultiSend
  "0x8D29bE29923b68abfDD21e541b9374737B49cdAD".toLowerCase(), // 1.1.1
  "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761".toLowerCase(), // 1.3.0
  "0x998739BFdAAdde7C933B942a68053933098f9EDa".toLowerCase(), // 1.3.0
  "0x0dFcccB95225ffB03c6FBB2559B530C2B7C8A912".toLowerCase(), // 1.3.0
  "0x38869bf66a61cF6bDB996A6aE40D5853Fd43B526".toLowerCase(), // 1.4.1
  "0x309D0B190FeCCa8e1D5D8309a16F7e3CB133E885".toLowerCase(), // 1.4.1
  "0x218543288004CD07832472D464648173c77D7eB7".toLowerCase(), // 1.5.0
  // MultiSendCallOnly
  "0x40A2aCCbd92BCA938b02010E17A5b8929b49130D".toLowerCase(), // 1.3.0
  "0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B".toLowerCase(), // 1.3.0
  "0xf220D3b4DFb23C4ade8C88E526C1353AbAcbC38F".toLowerCase(), // 1.3.0
  "0x9641d764fc13c8B624c04430C7356C1C7C8102e2".toLowerCase(), // 1.4.1
  "0x0408EF011960d02349d50286D20531229BCef773".toLowerCase(), // 1.4.1
  "0xA83c336B20401Af773B6219BA5027174338D1836".toLowerCase(), // 1.5.0
};

class TraceDecoder {
  String accountSingleton;
  List<TokenTransfer> transfers = [];
  List<TokenAllowance> allowances = [];
  List<NFTTransfer> nftTransfers = [];
  List<NFTAllowance> nftAllowances = [];
  List<SafeSettingChange> safeSettingsChanges = [];
  List<WarningTransaction> warningTransactions = [];


  TraceDecoder({required this.accountSingleton});

  // Remove any existing allowance (same token, same spender) in the list if exists
  // (This assumes that tokens follow the ERC-20 standard, and overwrites the allowance on multiple approvals)
  bool _removeExistingAllowance(EthereumAddress token, EthereumAddress spender){
    var index = -1;
    for (var i=0; i<allowances.length; i++){
      var allowance = allowances[i];
      if (allowance.token == token && allowance.spender == spender){
        index = i;
        break;
      }
    }
    if (index != -1){
      allowances.removeAt(index);
      return true;
    }
    return false;
  }

  // Deduct amount from existing allowance (same token, same spender) in the list if exists
  // (This assumes that tokens follow the ERC-20 standard, and amount is deducted when transferFrom is invoked)
  bool _deductAllowanceAmount(EthereumAddress token, EthereumAddress spender, BigInt amount){
    for (var allowance in allowances){
      if (allowance.token == token && allowance.spender == spender){
        if (allowance.amount < maxUint256){
          allowance.amount = allowance.amount - amount;
          if (allowance.amount == BigInt.zero){
            allowance.amount = BigInt.from(-1); // flag allowance to be later removed
          }
        }
        return true;
      }
    }
    return false;
  }

  // Removes all allowances where amount == -1, these are flagged allowances for removal (check _deductAllowanceAmount)
  bool cleanAllowances(){
    allowances.removeWhere((allowance) => allowance.amount == BigInt.from(-1));
    return true;
  }

  dynamic processLog(String account, Network network, Map<String, dynamic> log){
    account = account.toLowerCase();
    var topics = (log["topics"] as List<dynamic>).cast<String>();
    var eventSignature = topics[0].toLowerCase();
    if (_logsMapping.containsKey(eventSignature)){
      var eventName = _logsMapping[eventSignature]!;
      var emittedBy = EthereumAddress.fromHex(log["address"]);
      if (eventName.startsWith("safe") && emittedBy.with0x.toLowerCase() != account) return null;
      if (eventName == "token-transfer"){
        var sender = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        var recipient = decodeAbi(["address"], hexToBytes(topics[2]))[0] as EthereumAddress;
        if (sender.with0x.toLowerCase() != account && recipient.with0x.toLowerCase() != account) return null;
        var isNFT = topics.length == 4; // ERC-721 Approval events can be distinguished from ERC-20 ones by topics length (NFT transfer events have all fields indexed, whilst the erc-20 events don't have the amount field indexed)
        if (!isNFT){
          var amount = decodeAbi(["uint256"], hexToBytes(log["data"]))[0] as BigInt;
          return TokenTransfer(
            token: emittedBy,
            sender: sender,
            recipient: recipient,
            amount: amount,
            network: network
          );
        }else{
          var tokenId = decodeAbi(["uint256"], hexToBytes(topics[3]))[0] as BigInt;
          return NFTTransfer(
            collection: emittedBy,
            sender: sender,
            recipient: recipient,
            tokenId: tokenId,
            network: network
          );
        }
      } else if (eventName == "token-allowance-change"){
        var owner = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        if (owner.with0x.toLowerCase() != account) return null;
        var spender = decodeAbi(["address"], hexToBytes(topics[2]))[0] as EthereumAddress;
        var isNFT = topics.length == 4; // ERC-721 Approval events can be distinguished from ERC-20 ones by topics length (NFT transfer events have all fields indexed, whilst the erc-20 events don't have the amount field indexed)
        if (!isNFT){
          var amount = decodeAbi(["uint256"], hexToBytes(log["data"]))[0] as BigInt;
          var removed = _removeExistingAllowance(emittedBy, spender);
          if (removed && amount == BigInt.zero) return null; // Approval and allowance was spent in same tx, in this case no warning is needed since it'll be shown in balance changes
          return TokenAllowance(
            token: emittedBy,
            spender: spender,
            amount: amount,
            network: network
          );
        }else{
          var tokenId = decodeAbi(["uint256"], hexToBytes(topics[3]))[0] as BigInt;
          return NFTAllowance(
            collection: emittedBy,
            spender: spender,
            tokenId: tokenId,
            network: network
          );
        }
      }else if (eventName == "safe-owner-addition"){
        var addedOwner = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        return SafeSettingChange(
          type: SafeSettingChangeType.OWNER_ADDITION,
          data: [addedOwner]
        );
      }else if (eventName == "safe-owner-revocation"){
        var revokedOwner = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        return SafeSettingChange(
          type: SafeSettingChangeType.OWNER_REVOCATION,
          data: [revokedOwner]
        );
      }else if (eventName == "safe-threshold-change"){
        var newThreshold = decodeAbi(["uint256"], hexToBytes(log["data"]))[0] as BigInt;
        return SafeSettingChange(
          type: SafeSettingChangeType.THRESHOLD_CHANGE,
          data: [newThreshold]
        );
      }else if (eventName == "safe-module-enable"){
        var newModule = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        return WarningTransaction(
          type: WarningTransactionType.MODULE_ADDITION,
          data: [newModule]
        );
      }else if (eventName == "safe-module-disable"){
        var disabledModule = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        return WarningTransaction(
          type: WarningTransactionType.MODULE_REVOCATION,
          data: [disabledModule]
        );
      }else if (eventName == "safe-module-guard-change"){
        var newModuleGuard = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        return WarningTransaction(
          type: WarningTransactionType.MODULE_GUARD_CHANGE,
          data: [newModuleGuard]
        );
      }else if (eventName == "safe-guard-change"){
        var newGuard = decodeAbi(["address"], hexToBytes(topics[1]))[0] as EthereumAddress;
        return WarningTransaction(
          type: WarningTransactionType.GUARD_CHANGE,
          data: [newGuard]
        );
      }
    }
    return null;
  }

  void processCall(String account, Network network, Map<String, dynamic> call){
    var from = call["from"].toString().toLowerCase();
    var to = call["to"].toLowerCase();
    var callType = call["type"].toString();
    var accountAddress = account.toLowerCase();
    if (callType == "DELEGATECALL"){
      if (from == accountAddress){
        if (to != accountSingleton && !_trustedDelegatees.contains(to)){
          warningTransactions.add(
            WarningTransaction(
              type: WarningTransactionType.DELEGATE_CALL,
              data: [
                EthereumAddress.fromHex(to),
                call["input"]
              ]
            )
          );
        }
      }
    }
    if (callType == "CALL"){
      var input = call["input"].toString();
      // Transfers (inflows and outflows)
      if (from == accountAddress || to == accountAddress){
        var amount = BigInt.parse(call["value"].toString().replaceFirst("0x", ''), radix: 16);
        if (amount > BigInt.zero){
          var sender = EthereumAddress.fromHex(from);
          var recipient = EthereumAddress.fromHex(to);
          if (sender != recipient){
            transfers.add(
              TokenTransfer(
                token: EthereumAddress.fromHex("0x0000000000000000000000000000000000000000"),
                sender: sender,
                recipient: recipient,
                amount: amount,
                network: network
              )
            );
          }
        }
      }
      if (input.replaceFirst("0x", '').length >= 8){
        var selector = "0x${call["input"].toString().replaceAll("0x", '').substring(0, 8)}".toLowerCase();
        var callData = call["input"].toString().replaceFirst("0x", '').substring(8);
        // ERC-20 transferFrom
        if (selector == "0x23b872dd"){
          // Place in a try-catch clause because abi decoding might throw in case another function other than transferFrom has a similar selector
          try {
            var params = decodeAbi(["address", "address", "uint256"], hexToBytes(callData));
            if ((params[0] as EthereumAddress).with0x == accountAddress){
              _deductAllowanceAmount(EthereumAddress.fromHex(to), params[1] as EthereumAddress, params[2] as BigInt);
            }
          } catch (e) {/*do nothing*/}
        }
      }
    }
    //
    var logs = call["logs"];
    for (var log in logs){
      var decodedLog = processLog(account, network, log);
      if (decodedLog == null) continue;
      if (decodedLog is TokenTransfer){
        transfers.add(decodedLog);
      }else if (decodedLog is TokenAllowance){
        allowances.add(decodedLog);
      }else if (decodedLog is NFTTransfer){
        nftTransfers.add(decodedLog);
      }else if (decodedLog is NFTAllowance){
        nftAllowances.add(decodedLog);
      }else if (decodedLog is SafeSettingChange){
        safeSettingsChanges.add(decodedLog);
      }else if (decodedLog is WarningTransaction){
        warningTransactions.add(decodedLog);
      }
    }
    //
    if (call["calls"] != null && call["calls"].length > 0){
      for (var _internalCall in call["calls"]){
        processCall(account, network, _internalCall);
      }
    }
  }

  SimulationResult decode(String account, SafeTransaction transaction, Network network, Map<String, dynamic> trace){
    // Handle REVM-level errors (e.g. gas limit exceeded, validation failures)
    if (trace["error"] == true) {
      return SimulationResult(
        success: false,
        revertReason: trace["message"] as String? ?? "REVM execution error",
        dangerous: (false, null, ""),
        transfers: [],
        allowances: [],
        nftTransfers: [],
        nftAllowances: [],
        safeSettingsChanges: [],
        warningTransactions: [],
      );
    }
    var executionResult = trace["executionResult"] as Map<String, dynamic>;
    if (!executionResult.containsKey("Success")) {
      String revertReason = executionResult["Revert"]["output"];
      if (revertReason.startsWith("0x08c379a0")){
        revertReason = decodeAbi(["string"], hexToBytes(revertReason.substring(10)))[0];
      }
      return SimulationResult(
        success: false,
        revertReason: revertReason,
        dangerous: (false, null, ""),
        transfers: transfers,
        allowances: allowances,
        nftTransfers: nftTransfers,
        nftAllowances: nftAllowances,
        safeSettingsChanges: safeSettingsChanges,
        warningTransactions: warningTransactions
      );
    }
    //
    var isDangerous = false;
    DangerousTransactionType? dangerousType;
    dynamic dangerousData;
    var stateDiff = trace["stateDiff"] as Map<String, dynamic>;
    if (stateDiff.containsKey(account.toLowerCase())){
      var accountStorageDiff = stateDiff[account.toLowerCase()]["storage"] as Map<String, dynamic>;
      if (accountStorageDiff.containsKey("0x0")){
        var slotZeroDiff = accountStorageDiff["0x0"] as Map<String, dynamic>;
        if (slotZeroDiff["original_value"] != slotZeroDiff["present_value"]){
          if (slotZeroDiff["present_value"] != accountSingleton){
            isDangerous = true;
            dangerousType = DangerousTransactionType.SINGLETON_CHANGE;
            dangerousData = (EthereumAddress.fromHex(accountSingleton), EthereumAddress.fromHex(slotZeroDiff["present_value"]));
          }
        }
      }
    }
    //
    var callFrame = trace["calls"];
    processCall(account, network, callFrame);
    //
    cleanAllowances();
    //
    return SimulationResult(
      success: true,
      revertReason: "0x",
      dangerous: (isDangerous, dangerousType, dangerousData),
      transfers: transfers,
      allowances: allowances,
      nftTransfers: nftTransfers,
      nftAllowances: nftAllowances,
      safeSettingsChanges: safeSettingsChanges,
      warningTransactions: warningTransactions
    );
  }
}