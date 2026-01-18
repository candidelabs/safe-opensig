import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_verify/core/storage/accounts_box.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';

class MiscBox {
  static late Box _box;
  static const String boxName = 'box:misc';
  static const String _onboardingCompletedKey = 'key:$boxName:onboarding:completed';
  static const String _selectedAccountIdKey = 'key:$boxName:safe-accounts:selected-account-id';
  static const String schemaVersionKey = 'key:$boxName:storage:schema-version';

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  static Future<void> markOnboardingAsCompleted() async {
    await _box.put(_onboardingCompletedKey, true);
  }

  static bool isOnboardingCompleted() {
    return _box.get(_onboardingCompletedKey, defaultValue: false);
  }

  static Future<void> setSelectedAccountId(String? accountId) async {
    if (accountId == null) {
      var accounts = AccountsBox.getAccounts();
      if (accounts.isEmpty) {
        await _box.delete(_selectedAccountIdKey);
      }else{
        await _box.put(_selectedAccountIdKey, accounts.first.id);
      }
    } else {
      await _box.put(_selectedAccountIdKey, accountId);
    }
    eventBus.fire(OnAccountStorageChange());
  }

  static String? getSelectedAccountId() {
    return _box.get(_selectedAccountIdKey, defaultValue: null);
  }

  static Future<void> setSchemaVersion(int version) async {
    await _box.put(schemaVersionKey, version);
  }

  static int getSchemaVersion() {
    return _box.get(schemaVersionKey, defaultValue: 0);
  }
}