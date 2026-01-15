class MigrationResult {
  final bool success;
  final String? errorMessage;
  final int startVersion;
  final int endVersion;
  final Duration totalTime;

  MigrationResult({
    required this.success,
    required this.startVersion,
    required this.endVersion,
    required this.totalTime,
    this.errorMessage,
  });

  factory MigrationResult.successResult(
    int startVersion,
    int endVersion,
    Duration totalTime,
  ) {
    return MigrationResult(
      success: true,
      startVersion: startVersion,
      endVersion: endVersion,
      totalTime: totalTime,
      errorMessage: null,
    );
  }

  factory MigrationResult.failure(
    int startVersion,
    int endVersion,
    String errorMessage,
    Duration totalTime,
  ) {
    return MigrationResult(
      success: false,
      startVersion: startVersion,
      endVersion: endVersion,
      totalTime: totalTime,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'MigrationResult(success: true, v$startVersion→v$endVersion, ${totalTime.inMilliseconds}ms)';
    } else {
      return 'MigrationResult(success: false, v$startVersion→v$endVersion, error: $errorMessage)';
    }
  }
}

class MigrationHistoryEntry {
  final int version;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;
  final Duration executionTime;

  MigrationHistoryEntry({
    required this.version,
    required this.timestamp,
    required this.success,
    this.errorMessage,
    required this.executionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'errorMessage': errorMessage,
      'executionTimeMs': executionTime.inMilliseconds,
    };
  }

  factory MigrationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MigrationHistoryEntry(
      version: json['version'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      executionTime: Duration(milliseconds: json['executionTimeMs'] as int),
    );
  }
}
