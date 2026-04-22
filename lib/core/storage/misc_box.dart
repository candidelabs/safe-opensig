import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_opensig/core/storage/accounts_box.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';

class MiscBox {
  static late Box _box;
  static const String boxName = 'box:misc';
  static const String _onboardingCompletedKey = 'key:$boxName:onboarding:completed';
  static const String _selectedAccountIdKey = 'key:$boxName:safe-accounts:selected-account-id';
  static const String schemaVersionKey = 'key:$boxName:storage:schema-version';
  static const String _analyticsOptedInKey = 'key:$boxName:analytics:opted-in';
  static const String _analyticsNudgeShownKey = 'key:$boxName:analytics:nudge-shown';

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
      } else {
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

  static Future<void> setAnalyticsOptedIn(bool optedIn) async {
    await _box.put(_analyticsOptedInKey, optedIn);
  }

  static bool isAnalyticsOptedIn() {
    return _box.get(_analyticsOptedInKey, defaultValue: false);
  }

  static Future<void> markAnalyticsNudgeShown() async {
    await _box.put(_analyticsNudgeShownKey, true);
  }

  static bool isAnalyticsNudgeShown() {
    return _box.get(_analyticsNudgeShownKey, defaultValue: false);
  }
}
