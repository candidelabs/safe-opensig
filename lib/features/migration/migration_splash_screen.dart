import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_verify/core/storage/migrations/migration_runner.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';

class MigrationSplashScreen extends StatefulWidget {
  const MigrationSplashScreen({super.key});

  @override
  State<MigrationSplashScreen> createState() => _MigrationSplashScreenState();
}

class _MigrationSplashScreenState extends State<MigrationSplashScreen> {
  String _status = 'Initializing...';
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    // Listen for migration events
    _subscription = eventBus.on<OnMigrationStatusChange>().listen((event) {
      if (mounted) {
        setState(() {
          _status = _getStatusMessage(event.status, event.message);
        });
      }

      if (event.status == MigrationStatus.COMPLETED) {
        _onMigrationComplete();
      } else if (event.status == MigrationStatus.FAILED) {
        _onMigrationFailed(event.message);
      }
    });

    // Start migration asynchronously
    _runMigration();
  }

  Future<void> _runMigration() async {
    await HiveMigrationRunner.runMigrations();
  }

  Future<void> _onMigrationComplete() async {
    try {
      // Wait a moment for UI to show completion
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate back to root - router will redirect to appropriate screen
      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        _onMigrationFailed('Failed to initialize app: $e');
      }
    }
  }

  void _onMigrationFailed(String error) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildErrorDialog(error),
    );
  }

  Widget _buildErrorDialog(String error) {
    return AlertDialog(
      title: const Text('Migration Failed'),
      content: Text(
        'Failed to upgrade storage. Your data has been restored '
        'to the previous version. Please contact support if this '
        'issue persists.\n\nError: $error',
      ),
      actions: [
        TextButton(
          onPressed: () => exit(0),
          child: const Text('Close App'),
        ),
      ],
    );
  }

  String _getStatusMessage(MigrationStatus status, String message) {
    switch (status) {
      case MigrationStatus.INITIALIZING:
        return 'Preparing...';
      case MigrationStatus.BACKING_UP:
        return 'Backing up data...';
      case MigrationStatus.MIGRATING:
        return 'Upgrading storage...';
      case MigrationStatus.VERIFYING:
        return 'Verifying integrity...';
      case MigrationStatus.ROLLING_BACK:
        return 'Restoring previous state...';
      case MigrationStatus.COMPLETED:
        return 'Complete';
      case MigrationStatus.FAILED:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/ic_logo.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if logo not found
                return const Icon(
                  Icons.storage,
                  size: 80,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 40),

            // Status text
            Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 80),
            // Subtle warning
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Please do not close the app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
