import 'package:event_bus/event_bus.dart';
import 'package:safe_opensig/shared/models/network_model.dart';

final EventBus eventBus = EventBus();

class OnAccountStorageChange {
  const OnAccountStorageChange();
}

class OnFirstVerificationCompleted {
  const OnFirstVerificationCompleted();
}

class OnAddressNetworkDetected {
  final Network network;
  const OnAddressNetworkDetected(this.network);
}

enum MigrationStatus {
  INITIALIZING,
  BACKING_UP,
  MIGRATING,
  VERIFYING,
  ROLLING_BACK,
  COMPLETED,
  FAILED,
}

class OnNodeConfigChange {
  const OnNodeConfigChange();
}

class OnMigrationStatusChange {
  final MigrationStatus status;
  final String message;

  const OnMigrationStatusChange(this.status, this.message);
}