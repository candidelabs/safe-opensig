import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_verify/core/storage/misc_box.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';

class AccountsBox {
  static late Box _box;
  static const String boxName = 'box:safe-accounts';

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  static Future<void> addAccount(SafeAccount account) async {
    var selectAccount = false;
    if (_box.isEmpty){
      selectAccount = true;
    }
    await _box.put(account.id, account.toJson());
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
    return _box.values
      .map((json) => SafeAccount.fromJson((json as Map<dynamic, dynamic>).cast()))
      .toList();
  }

  static SafeAccount? getAccount(String accountId) {
    final json = _box.get(accountId);
    if (json == null) return null;
    return SafeAccount.fromJson((json as Map<dynamic, dynamic>).cast());
  }

  static bool accountExists(String address, int chainId) {
    return _box.values.any((json) {
      final account = SafeAccount.fromJson((json as Map<dynamic, dynamic>).cast());
      return account.address.toLowerCase() == address.toLowerCase() && account.network.chainId == chainId;
    });
  }

  static Future<void> clearAll() async {
    await _box.clear();
    eventBus.fire(OnAccountStorageChange());
  }
}
