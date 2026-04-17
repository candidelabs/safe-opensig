import 'package:flutter/material.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';

/// Inline info banner used whenever the latest onchain nonce couldn't be
/// fetched, so the user is aware they need to confirm the nonce themselves.
class MissingLatestNonceBanner extends StatelessWidget {
  final String message;
  const MissingLatestNonceBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns the banner copy to display when we couldn't fetch the latest nonce,
/// or null when no banner is needed (latestNonce is known).
String? missingLatestNonceMessage(SafeTransaction transaction) {
  if (transaction.latestNonce != null) return null;
  if (transaction.nonceIsEditable) {
    if (transaction.nonce == null) {
      return "Couldn't reach the network to fetch the latest nonce. Set it manually and make "
          'sure it matches the latest onchain nonce.';
    }
    return "Couldn't reach the network to fetch the latest nonce. Make sure the value above "
        'matches the latest onchain nonce.';
  }
  return "Couldn't reach the network to fetch the latest nonce. Confirm this matches the "
      'latest onchain nonce before signing.';
}
