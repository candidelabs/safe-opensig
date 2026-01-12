import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_verify/core/storage/misc_box.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';

class AccountsBox {
  static late Box<SafeAccount> _box;
  static const String _accountsBox = 'box:accounts';

  static Future<void> init() async {
    _box = await Hive.openBox<SafeAccount>(_accountsBox);
  }

  static Future<void> addAccount(SafeAccount account) async {
    var selectAccount = false;
    if (_box.isEmpty){
      selectAccount = true;
    }
    await _box.put(account.id, account);
    if (selectAccount){
      await MiscBox.setSelectedAccountId(account.id);
    }
    eventBus.fire(OnAccountStorageChange());
  }

  static Future<void> removeAccount(String accountId) async {
    await _box.delete(accountId);
    eventBus.fire(OnAccountStorageChange());
  }

  static List<SafeAccount> getAccounts() {
    return _box.values.toList();
  }

  static SafeAccount? getAccount(String accountId) {
    return _box.get(accountId);
  }

  static bool accountExists(String address, int chainId) {
    return _box.values.any((account) => 
      account.address.toLowerCase() == address.toLowerCase() && 
      account.network.chainId == chainId
    );
  }

  static Future<void> clearAll() async {
    await _box.clear();
    eventBus.fire(OnAccountStorageChange());
  }
}