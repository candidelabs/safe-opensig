import 'package:flutter/material.dart';

/// Enumerates what Safe OpenSig's simulation verifies and where it stops.
/// Rendered inside the About dialog and the simulation-results AppBar sheet
/// so the same content reaches users in both contexts.
class SimulationScopeContent extends StatelessWidget {
  const SimulationScopeContent({super.key});

  static const _checkedItems = [
    'Token and NFT transfers (ERC-20, ERC-721, ERC-1155)',
    'Token and NFT allowances (grants and revocations)',
    'Safe owner and signing-threshold changes',
    'Module, guard, and delegate-call warnings',
    'Safe singleton (implementation) changes',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('What we check', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ..._checkedItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: Colors.green[400],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Limits of simulation', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Results reflect the current block. Once broadcast, your transaction '
          'can be front-run, back-run, or sandwiched by MEV (Maximal Extractable '
          'Value, the profit extracted by reordering, inserting, or censoring '
          'transactions). The final onchain result may differ, especially for '
          'swaps and other price-sensitive actions.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mitigation: for price-sensitive transactions on Ethereum, consider '
          'broadcasting through an MEV-protected RPC such as Flashbots Protect '
          'to reduce this exposure.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Opens the scope content as a modal bottom sheet.
  static void showAsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulation scope',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                const SimulationScopeContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
