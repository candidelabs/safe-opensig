import 'package:flutter/material.dart';

class MevProtectionNote extends StatelessWidget {
  const MevProtectionNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.amber[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulation does not protect from MEV',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[300],
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MEV (Maximal Extractable Value) is the profit a block producer or searcher can extract by reordering, inserting, or censoring transactions. Results show the expected outcome at the current block. Once broadcast, your transaction can still be front-run, back-run, or sandwiched, so the actual onchain result may differ, especially for swaps and other price-sensitive actions.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
