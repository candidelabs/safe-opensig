import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_verify/core/storage/migrations/migration_base.dart';
import 'package:safe_verify/core/storage/misc_box.dart';

/// Bootstrap migration that initializes the migration system
/// Sets the initial schema version to 1
class Migration_0_to_1 extends HiveMigration {
  @override
  int get sourceVersion => 0;

  @override
  int get targetVersion => 1;

  @override
  String get description => 'Initialize migration system';

  @override
  Future<(bool, String?)> validatePreconditions() async {
    // Check that MiscBox is open
    if (!Hive.isBoxOpen(MiscBox.boxName)) {
      return (false, 'MiscBox must be open before migration');
    }

    // Check that we're actually at version 0
    final currentVersion = MiscBox.getSchemaVersion();
    if (currentVersion != 0) {
      return (false, 'Expected schema version 0, got $currentVersion');
    }

    return (true, null);
  }

  @override
  Future<(bool, String?)> migrate() async {
    try {
      // Set initial schema version
      await MiscBox.setSchemaVersion(1);
      return (true, null);
    } catch (e) {
      return (false, 'Failed to set schema version: $e');
    }
  }

  @override
  Future<(bool, String?)> validatePostconditions() async {
    // Verify version was set correctly
    final version = MiscBox.getSchemaVersion();
    if (version != 1) {
      return (false, 'Schema version not set to 1 (current: $version)');
    }

    return (true, null);
  }

  @override
  Future<void> cleanup() async {
    // No cleanup needed for this migration
  }
}
