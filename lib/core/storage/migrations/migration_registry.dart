import 'package:safe_verify/core/storage/migrations/migration_base.dart';
import 'package:safe_verify/core/storage/migrations/versions/migration_0_to_1.dart';

/// Registry of all available migrations
/// Migrations should be added in chronological order
class MigrationRegistry {
  /// List of all migrations in chronological order
  /// When adding a new migration:
  /// 1. Create migration file in versions/migration_{from}_to_{to}.dart
  /// 2. Add it to this list
  /// 3. Update CURRENT_VERSION in HiveMigrationRunner
  static final List<HiveMigration> _migrations = [
    Migration_0_to_1(),
  ];

  /// Gets all migrations needed to go from [from] to [to] version
  /// Returns migrations in sequential order
  static List<HiveMigration> getMigrations(int from, int to) {
    if (from == to) return [];

    return _migrations
        .where((m) => m.sourceVersion >= from && m.targetVersion <= to)
        .toList()
      ..sort((a, b) => a.targetVersion.compareTo(b.targetVersion));
  }

  /// Checks if there's a migration path from [from] to [to]
  static bool hasPath(int from, int to) {
    if (from == to) return true;

    final migrations = getMigrations(from, to);
    if (migrations.isEmpty) return false;

    // Verify continuous path (no gaps)
    int currentVersion = from;
    for (final migration in migrations) {
      if (migration.sourceVersion != currentVersion) {
        return false; // Gap in migration chain
      }
      currentVersion = migration.targetVersion;
    }

    return currentVersion == to;
  }

  /// Gets all registered migrations (for debugging/testing)
  static List<HiveMigration> getAllMigrations() {
    return List.unmodifiable(_migrations);
  }

  /// Validates the migration registry for consistency
  /// Returns (valid, errorMessage)
  static (bool, String?) validate() {
    if (_migrations.isEmpty) {
      return (false, 'No migrations registered');
    }

    // Check for duplicate source/target pairs
    final seen = <String>{};
    for (final migration in _migrations) {
      final key = '${migration.sourceVersion}_${migration.targetVersion}';
      if (seen.contains(key)) {
        return (
          false,
          'Duplicate migration found: v${migration.sourceVersion}→v${migration.targetVersion}'
        );
      }
      seen.add(key);
    }

    // Check for sequential ordering
    final sorted = List<HiveMigration>.from(_migrations)
      ..sort((a, b) => a.targetVersion.compareTo(b.targetVersion));

    for (int i = 0; i < _migrations.length; i++) {
      if (_migrations[i].targetVersion != sorted[i].targetVersion) {
        return (
          false,
          'Migrations are not in chronological order. '
              'Expected v${sorted[i].sourceVersion}→v${sorted[i].targetVersion} '
              'at position $i'
        );
      }
    }

    return (true, null);
  }
}
