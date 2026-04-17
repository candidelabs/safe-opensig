import 'package:flutter/material.dart';

void showOfflineCapabilitySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _OfflineCapabilitySheet(),
  );
}

class _OfflineCapabilitySheet extends StatelessWidget {
  const _OfflineCapabilitySheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.airplanemode_active, size: 18, color: dim),
              const SizedBox(width: 8),
              Text(
                'Can work air-gapped',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hash calculation and Ledger review run on device. When offline, the latest onchain nonce can\'t be verified, a banner will prompt you to confirm it manually.',
            style: theme.textTheme.bodySmall?.copyWith(color: dim, height: 1.5),
          ),
        ],
      ),
    );
  }
}
