import 'dart:convert';
import 'dart:io';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_verify/core/storage/accounts_box.dart';
import 'package:safe_verify/core/storage/misc_box.dart';
import 'package:safe_verify/core/storage/theme_box.dart';

class BackupManager {
  /// Creates a backup of all user data boxes
  /// Returns the path to the created backup file
  static Future<String> createBackup(int currentVersion) async {
    final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('.', '');
    final filename = 'backup_v${currentVersion}_$timestamp.json.gz';

    final backupDir = await _getBackupDirectory();
    final backupPath = '${backupDir.path}/$filename';

    // Collect all box data
    final backupData = {
      'schemaVersion': currentVersion,
      'backupTimestamp': DateTime.now().toIso8601String(),
      'appVersion': await _getAppVersion(),
      'boxes': await _serializeAllBoxes(),
    };

    // Write compressed JSON
    final jsonString = jsonEncode(backupData);
    final compressedBytes = gzip.encode(utf8.encode(jsonString));

    final file = File(backupPath);
    await file.writeAsBytes(compressedBytes);

    return backupPath;
  }

  /// Restores data from a backup file
  /// This will close all boxes, delete existing data, and restore from backup
  static Future<void> restoreFromBackup(String backupPath) async {
    try {
      // Read and decompress backup
      final file = File(backupPath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $backupPath');
      }

      final compressedBytes = await file.readAsBytes();
      final jsonString = utf8.decode(gzip.decode(compressedBytes));
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Close all boxes before restoration
      await _closeAllBoxes();

      // Delete existing box files
      await _deleteBoxFiles();

      // Restore boxes from backup
      await _restoreBoxes(backupData['boxes'] as Map<String, dynamic>);

      // Restore schema version
      final miscBox = await Hive.openBox(MiscBox.boxName);
      await miscBox.put(
        MiscBox.schemaVersionKey,
        backupData['schemaVersion'],
      );
    } catch (e) {
      // Catastrophic failure - cannot recover automatically
      throw Exception(
        'CRITICAL: Backup restore failed. Manual recovery required. '
        'Backup file: $backupPath. Error: $e',
      );
    }
  }

  /// Serializes all boxes to JSON format
  static Future<Map<String, dynamic>> _serializeAllBoxes() async {
    final boxes = <String, dynamic>{};

    // Serialize AccountsBox
    if (Hive.isBoxOpen(AccountsBox.boxName)) {
      final accountsBox = Hive.box(AccountsBox.boxName);
      boxes[AccountsBox.boxName] = {
        'type': 'json',
        'entries': accountsBox.keys.map((key) {
          final json = accountsBox.get(key);
          return {'key': key, 'value': json};
        }).toList(),
      };
    }

    // Serialize MiscBox
    if (Hive.isBoxOpen(MiscBox.boxName)) {
      final miscBox = Hive.box(MiscBox.boxName);
      boxes[MiscBox.boxName] = {
        'type': 'generic',
        'entries': miscBox.keys
          .map((key) => {'key': key, 'value': miscBox.get(key)})
          .toList(),
      };
    }

    // Serialize ThemeBox
    if (Hive.isBoxOpen(ThemeBox.boxName)) {
      final themeBox = Hive.box(ThemeBox.boxName);
      boxes[ThemeBox.boxName] = {
        'type': 'generic',
        'entries': themeBox.keys
          .map((key) => {'key': key, 'value': themeBox.get(key)})
          .toList(),
      };
    }

    return boxes;
  }

  /// Restores boxes from serialized backup data
  static Future<void> _restoreBoxes(Map<String, dynamic> boxes) async {
    // Restore AccountsBox
    if (boxes.containsKey(AccountsBox.boxName)) {
      final boxData = boxes[AccountsBox.boxName] as Map<String, dynamic>;
      final accountsBox = await Hive.openBox(AccountsBox.boxName);

      for (final entry in boxData['entries']) {
        final key = entry['key'];
        final value = entry['value'] as Map<String, dynamic>;
        await accountsBox.put(key, value);
      }
    }

    // Restore MiscBox
    if (boxes.containsKey(MiscBox.boxName)) {
      final boxData = boxes[MiscBox.boxName] as Map<String, dynamic>;
      final miscBox = await Hive.openBox(MiscBox.boxName);

      for (final entry in boxData['entries']) {
        await miscBox.put(entry['key'], entry['value']);
      }
    }

    // Restore ThemeBox
    if (boxes.containsKey(ThemeBox.boxName)) {
      final boxData = boxes[ThemeBox.boxName] as Map<String, dynamic>;
      final themeBox = await Hive.openBox(ThemeBox.boxName);

      for (final entry in boxData['entries']) {
        await themeBox.put(entry['key'], entry['value']);
      }
    }
  }

  /// Closes all open boxes
  static Future<void> _closeAllBoxes() async {
    if (Hive.isBoxOpen(AccountsBox.boxName)) {
      await Hive.box(AccountsBox.boxName).close();
    }
    if (Hive.isBoxOpen(MiscBox.boxName)) {
      await Hive.box(MiscBox.boxName).close();
    }
    if (Hive.isBoxOpen(ThemeBox.boxName)) {
      await Hive.box(ThemeBox.boxName).close();
    }
  }

  /// Deletes all box files from disk
  static Future<void> _deleteBoxFiles() async {
    await Hive.deleteBoxFromDisk(AccountsBox.boxName);
    await Hive.deleteBoxFromDisk(MiscBox.boxName);
    await Hive.deleteBoxFromDisk(ThemeBox.boxName);
  }

  /// Gets the backup directory, creating it if necessary
  static Future<Directory> _getBackupDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(
      '${appDocDir.path}/safe_opensig_storage_backups',
    );

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// Gets the current app version
  static Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Cleans up old backups according to retention policy
  /// Keeps last 3 backups + all from last 7 days
  static Future<void> cleanupOldBackups() async {
    final backupDir = await _getBackupDirectory();
    final backups = await _listBackups(backupDir);

    if (backups.isEmpty) return;

    // Sort by timestamp (newest first)
    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final now = DateTime.now();
    final keepList = <File>[];

    // Keep last 3 backups unconditionally
    keepList.addAll(backups.take(3).map((b) => b.file));

    // Keep all backups from last 7 days
    for (final backup in backups) {
      if (now.difference(backup.timestamp).inDays <= 7) {
        if (!keepList.contains(backup.file)) {
          keepList.add(backup.file);
        }
      }
    }

    // Delete backups not in keep list
    for (final backup in backups) {
      if (!keepList.contains(backup.file)) {
        try {
          await backup.file.delete();
        } catch (e) {
          // Ignore deletion errors
        }
      }
    }
  }

  /// Lists all backup files in the backup directory
  static Future<List<_BackupInfo>> _listBackups(Directory backupDir) async {
    final backups = <_BackupInfo>[];

    if (!await backupDir.exists()) {
      return backups;
    }

    await for (final entity in backupDir.list()) {
      if (entity is File && entity.path.endsWith('.json.gz')) {
        final filename = entity.path.split(Platform.pathSeparator).last;
        final timestamp = _extractTimestamp(filename);
        if (timestamp != null) {
          backups.add(_BackupInfo(file: entity, timestamp: timestamp));
        }
      }
    }

    return backups;
  }

  /// Extracts timestamp from backup filename
  /// Format: backup_v{version}_{timestamp}.json.gz
  static DateTime? _extractTimestamp(String filename) {
    try {
      // Remove extension
      final nameWithoutExt = filename
          .replaceAll('.json.gz', '')
          .replaceAll('.json', '');

      // Extract timestamp part (after last underscore)
      final parts = nameWithoutExt.split('_');
      if (parts.length < 3) return null;

      final timestampStr = parts[2];

      // Parse timestamp (format: 20260113T103000000Z or similar)
      // Try to reconstruct ISO format
      if (timestampStr.length >= 15) {
        final year = timestampStr.substring(0, 4);
        final month = timestampStr.substring(4, 6);
        final day = timestampStr.substring(6, 8);
        final hour = timestampStr.substring(9, 11);
        final minute = timestampStr.substring(11, 13);
        final second = timestampStr.substring(13, 15);

        final isoString = '$year-$month-${day}T$hour:$minute:${second}Z';
        return DateTime.parse(isoString);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Internal class to hold backup file information
class _BackupInfo {
  final File file;
  final DateTime timestamp;

  _BackupInfo({required this.file, required this.timestamp});
}
