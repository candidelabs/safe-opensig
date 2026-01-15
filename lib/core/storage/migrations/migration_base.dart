abstract class HiveMigration {
  /// Source version (migrating FROM)
  int get sourceVersion;

  /// Target version (migrating TO)
  int get targetVersion;

  /// Human-readable description for logging
  String get description;

  /// Validate preconditions before migration
  /// Returns (valid, errorMessage)
  /// This should check that:
  /// - Required boxes are open
  /// - Data is in expected state
  /// - No conflicting conditions exist
  Future<(bool, String?)> validatePreconditions();

  /// Execute the migration
  /// Returns (success, errorMessage)
  /// This should:
  /// - Transform data as needed
  /// - Handle errors gracefully
  /// - Leave data in consistent state
  Future<(bool, String?)> migrate();

  /// Validate postconditions after migration
  /// Returns (valid, errorMessage)
  /// This should verify:
  /// - Migration completed successfully
  /// - Data is in expected new state
  /// - No data corruption occurred
  Future<(bool, String?)> validatePostconditions();

  /// Optional cleanup after successful migration
  /// This can be used to:
  /// - Remove temporary data
  /// - Log completion
  Future<void> cleanup() async {}
}
