import 'package:hive_ce_flutter/hive_flutter.dart';

class ThemeBox {
  static late Box _box;
  static const String boxName = 'box:theme';
  static const String _themeDarkModeKey = 'key:$boxName:dark-mode';

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  static Future<void> setDarkMode(bool isDarkMode) async {
    await _box.put(_themeDarkModeKey, isDarkMode);
  }

  static bool isDarkMode() {
    // return false;
    return _box.get(_themeDarkModeKey, defaultValue: false);
  }
}