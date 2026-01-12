import 'package:event_bus/event_bus.dart';
import 'package:safe_verify/shared/models/network_model.dart';

final EventBus eventBus = EventBus();

class OnAccountStorageChange {
  const OnAccountStorageChange();
}

class OnAddressNetworkDetected {
  final Network network;
  const OnAddressNetworkDetected(this.network);
}