import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_verify/core/storage/accounts_box.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';

class MiscBox {
  static late Box _box;
  static const String _miscBox = 'box:misc';
  static const String _onboardingCompletedKey = 'key:$_miscBox:onboarding:completed';
  static const String _selectedAccountIdKey = 'key:$_miscBox:accounts:selected-account-id';

  static Future<void> init() async {
    _box = await Hive.openBox(_miscBox);
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
}