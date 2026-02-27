import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/constants/popular_safes.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/services/safe_transaction_service.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';

class PopularSafesSection extends StatefulWidget {
  const PopularSafesSection({super.key});

  @override
  State<PopularSafesSection> createState() => _PopularSafesSectionState();
}

class _PopularSafesSectionState extends State<PopularSafesSection> {
  // null = loading, non-null = resolved (may be absent if none found)
  PopularSafe? _safe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _findFirstWithTransactions();
  }

  Future<void> _findFirstWithTransactions() async {
    final service = SafeTransactionService();
    // Check only Yearn — it's reliably active and resolves quickly
    final yearn = popularSafes.first;
    final (success, txs, _) = await service.getQueuedTransactions(
      safeAddress: yearn.address,
      chainId: yearn.chainId,
    );
    final safe = (success && txs != null && txs.isNotEmpty)
        ? yearn
        : popularSafes.last; // guaranteed demo Safe fallback
    if (mounted) setState(() { _safe = safe; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_safe == null) return const SizedBox.shrink();
    return _PopularSafeCard(safe: _safe!);
  }
}

class _PopularSafeCard extends StatelessWidget {
  final PopularSafe safe;

  const _PopularSafeCard({required this.safe});

  void _onExplore(BuildContext context) {
    final ephemeral = SafeAccount(
      id: const Uuid().v4(),
      name: safe.displayName,
      address: safe.address,
      chainId: safe.chainId,
      version: safe.version,
    );
    GoRouter.of(context).push('/verify-transaction', extra: ephemeral);
  }

  String _truncateAddress(String addr, {int length = 4}) {
    if (addr.length <= length * 2 + 2) return addr;
    final without0x = addr.startsWith('0x') ? addr.substring(2) : addr;
    return '0x${without0x.substring(0, length)}...${without0x.substring(without0x.length - length)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final network = availableNetworks[safe.chainId];
    final metaParts = [
      _truncateAddress(safe.address),
      if (network != null) network.name,
      'v${safe.version}',
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (network != null) ...[
                  NetworkLogo(network: network, size: 32),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safe.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        safe.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metaParts,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.textTheme.labelSmall?.color
                              ?.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _onExplore(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
