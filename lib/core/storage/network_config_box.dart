import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/models/custom_network_config.dart';

class NetworkConfigBox {
  static late Box _box;
  static const String boxName = 'box:network-configs';

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  static Future<void> setConfig(CustomNetworkConfig config) async {
    await _box.put(config.chainId.toString(), config.toJson());
    eventBus.fire(const OnNodeConfigChange());
  }

  static Future<void> removeConfig(int chainId) async {
    await _box.delete(chainId.toString());
    eventBus.fire(const OnNodeConfigChange());
  }

  static CustomNetworkConfig? getConfig(int chainId) {
    final json = _box.get(chainId.toString());
    if (json == null) return null;
    return CustomNetworkConfig.fromJson(
      (json as Map<dynamic, dynamic>).cast<String, dynamic>(),
    );
  }

  static Map<int, CustomNetworkConfig> getAllConfigs() {
    final configs = <int, CustomNetworkConfig>{};
    for (final key in _box.keys) {
      final json = _box.get(key);
      if (json != null) {
        final config = CustomNetworkConfig.fromJson(
          (json as Map<dynamic, dynamic>).cast<String, dynamic>(),
        );
        configs[config.chainId] = config;
      }
    }
    return configs;
  }

  static bool hasCustomConfig(int chainId) {
    return _box.containsKey(chainId.toString());
  }

  static Future<void> clearAll() async {
    await _box.clear();
    eventBus.fire(const OnNodeConfigChange());
  }
}
