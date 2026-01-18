import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:safe_verify/core/storage/migrations/backup_manager.dart';
import 'package:safe_verify/core/storage/migrations/migration_base.dart';
import 'package:safe_verify/core/storage/migrations/migration_registry.dart';
import 'package:safe_verify/core/storage/misc_box.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';
import 'package:safe_verify/shared/models/migration_models.dart';

/// Central migration coordinator
/// Handles version detection, migration execution, backup, and rollback
class HiveMigrationRunner {
  /// Current target schema version
  /// Increment this when adding new migrations
  ///
  /// Version History:
  /// v0: Implicit (pre-migration)
  /// v1: Initial migration system installed
  static const int CURRENT_VERSION = 1;
  static bool? bNeedsMigration;

  /// Main entry point for migrations
  /// Call this from main.dart after Hive initialization
  /// Returns MigrationResult with success status
  static Future<MigrationResult> runMigrations() async {
    try {
      final startTime = DateTime.now();

      eventBus.fire(const OnMigrationStatusChange(
        MigrationStatus.INITIALIZING,
        'Preparing migration...',
      ));

      // Get current storage version
      final currentVersion = await _getCurrentStorageVersion();
      final targetVersion = CURRENT_VERSION;

      // Check if migration is needed
      if (!_needsMigration(currentVersion, targetVersion)) {
        return MigrationResult.successResult(
          currentVersion,
          currentVersion,
          Duration.zero,
        );
      }

      // Validate migration registry
      final (registryValid, registryError) = MigrationRegistry.validate();
      if (!registryValid) {
        return MigrationResult.failure(
          currentVersion,
          targetVersion,
          'Migration registry invalid: $registryError',
          Duration.zero,
        );
      }

      // Validate migration path exists
      if (!MigrationRegistry.hasPath(currentVersion, targetVersion)) {
        return MigrationResult.failure(
          currentVersion,
          targetVersion,
          'No migration path from v$currentVersion to v$targetVersion',
          Duration.zero,
        );
      }

      // Execute migration chain
      final result = await _executeMigrationChain(currentVersion, targetVersion);

      final totalTime = DateTime.now().difference(startTime);

      if (result.success) {
        eventBus.fire(const OnMigrationStatusChange(
          MigrationStatus.COMPLETED,
          'Migration completed successfully',
        ));
      } else {
        eventBus.fire(OnMigrationStatusChange(
          MigrationStatus.FAILED,
          result.errorMessage ?? 'Migration failed',
        ));
      }

      bNeedsMigration = false;

      return MigrationResult(
        success: result.success,
        startVersion: currentVersion,
        endVersion: result.success ? targetVersion : currentVersion,
        totalTime: totalTime,
        errorMessage: result.errorMessage,
      );
    } on HiveError catch (e) {
      return MigrationResult.failure(
        0,
        CURRENT_VERSION,
        'Hive error: ${e.message}',
        Duration.zero,
      );
    } catch (e) {
      return MigrationResult.failure(
        0,
        CURRENT_VERSION,
        'Unexpected error: $e',
        Duration.zero,
      );
    }
  }

  /// Checks if migration is needed
  /// Call this from main.dart to determine if MigrationApp should be launched
  static Future<bool> needsMigration() async {
    if (bNeedsMigration != null){
      return bNeedsMigration!;
    }
    try {
      final currentVersion = await _getCurrentStorageVersion();
      bNeedsMigration = _needsMigration(currentVersion, CURRENT_VERSION);
      return bNeedsMigration!;
    } catch (e) {
      // If we can't determine version, assume no migration needed
      // This allows app to continue on error
      return false;
    }
  }

  /// Gets the current storage schema version
  static Future<int> _getCurrentStorageVersion() async {
    if (!Hive.isBoxOpen(MiscBox.boxName)) {
      throw Exception('MiscBox must be open to check schema version');
    }
    return MiscBox.getSchemaVersion();
  }

  /// Determines if migration is needed
  static bool _needsMigration(int currentVersion, int targetVersion) {
    return currentVersion < targetVersion;
  }

  /// Executes the migration chain from [fromVersion] to [toVersion]
  /// Returns MigrationResult indicating success or failure
  static Future<MigrationResult> _executeMigrationChain(
    int fromVersion,
    int toVersion,
  ) async {
    final startTime = DateTime.now();

    // Get required migrations
    final migrations = MigrationRegistry.getMigrations(fromVersion, toVersion);

    if (migrations.isEmpty) {
      return MigrationResult.successResult(
        fromVersion,
        toVersion,
        Duration.zero,
      );
    }

    // Create backup before ANY migrations
    eventBus.fire(const OnMigrationStatusChange(
      MigrationStatus.BACKING_UP,
      'Backing up data...',
    ));

    String? backupPath;
    try {
      backupPath = await BackupManager.createBackup(fromVersion);
    } catch (e) {
      return MigrationResult.failure(
        fromVersion,
        toVersion,
        'Backup creation failed: $e',
        DateTime.now().difference(startTime),
      );
    }

    try {
      // Execute migrations sequentially
      for (final migration in migrations) {
        final success = await _runSingleMigration(migration, backupPath);

        if (!success) {
          // Migration failed - rollback
          eventBus.fire(const OnMigrationStatusChange(
            MigrationStatus.ROLLING_BACK,
            'Restoring previous state...',
          ));

          await BackupManager.restoreFromBackup(backupPath);

          return MigrationResult.failure(
            fromVersion,
            migration.targetVersion,
            'Migration to v${migration.targetVersion} failed. Data restored.',
            DateTime.now().difference(startTime),
          );
        }

        // Update version after successful migration
        await _updateStorageVersion(migration.targetVersion);
      }

      // All migrations successful - cleanup backup
      try {
        await BackupManager.cleanupOldBackups();
      } catch (e) {
        // Cleanup failure is non-fatal
      }

      return MigrationResult.successResult(
        fromVersion,
        toVersion,
        DateTime.now().difference(startTime),
      );
    } catch (e) {
      // Catastrophic failure - restore backup
      eventBus.fire(const OnMigrationStatusChange(
        MigrationStatus.ROLLING_BACK,
        'Critical error - restoring data...',
      ));

      try {
        await BackupManager.restoreFromBackup(backupPath);
      } catch (restoreError) {
        return MigrationResult.failure(
          fromVersion,
          toVersion,
          'CRITICAL: Migration failed and backup restoration failed. '
              'Backup file: $backupPath. '
              'Migration error: $e. '
              'Restore error: $restoreError',
          DateTime.now().difference(startTime),
        );
      }

      return MigrationResult.failure(
        fromVersion,
        toVersion,
        'Critical migration error: $e. Data restored from backup.',
        DateTime.now().difference(startTime),
      );
    }
  }

  /// Runs a single migration with validation
  /// Returns true if successful, false if failed
  static Future<bool> _runSingleMigration(
    HiveMigration migration,
    String backupPath,
  ) async {
    try {
      eventBus.fire(OnMigrationStatusChange(
        MigrationStatus.MIGRATING,
        'Upgrading to v${migration.targetVersion}...',
      ));

      // Validate preconditions
      final (preValid, preError) = await migration.validatePreconditions();
      if (!preValid) {
        print('Migration v${migration.sourceVersion}→v${migration.targetVersion} '
            'precondition failed: $preError');
        return false;
      }

      // Execute migration
      final (migrationSuccess, migrationError) = await migration.migrate();
      if (!migrationSuccess) {
        print('Migration v${migration.sourceVersion}→v${migration.targetVersion} '
            'failed: $migrationError');
        return false;
      }

      // Validate postconditions
      eventBus.fire(const OnMigrationStatusChange(
        MigrationStatus.VERIFYING,
        'Verifying integrity...',
      ));

      final (postValid, postError) = await migration.validatePostconditions();
      if (!postValid) {
        print('Migration v${migration.sourceVersion}→v${migration.targetVersion} '
            'postcondition failed: $postError');
        return false;
      }

      // Cleanup
      await migration.cleanup();

      print('Migration v${migration.sourceVersion}→v${migration.targetVersion} '
          'completed successfully');

      return true;
    } catch (e) {
      print('Migration v${migration.sourceVersion}→v${migration.targetVersion} '
          'threw exception: $e');
      return false;
    }
  }

  /// Updates the storage schema version
  static Future<void> _updateStorageVersion(int version) async {
    await MiscBox.setSchemaVersion(version);
  }
}
