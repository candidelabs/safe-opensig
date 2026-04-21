import 'package:flutter/material.dart';

class SafeTxAPIGuideSheet extends StatelessWidget {
  const SafeTxAPIGuideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.cloud_queue,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'About Safe API',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // What is it?
            _buildSection(
              context,
              icon: Icons.info_outline,
              title: 'What is this?',
              content:
                'The Safe API tab automatically fetches queued (non-executed) transactions '
                'from the Safe Transaction Service for your Safe account. This allows you to '
                'verify and simulate transactions without manually entering transaction data.',
            ),
            const SizedBox(height: 20),

            // How it works
            _buildSection(
              context,
              icon: Icons.sync,
              title: 'How it works',
              content:
                'When you select this tab, the app connects to the Safe Transaction Service API '
                'and retrieves all pending transactions for your Safe account on the current network. '
                'You can then select any transaction from the list to verify its details and simulate its execution.',
            ),
            const SizedBox(height: 20),

            // Security note
            _buildSection(
              context,
              icon: Icons.security,
              title: 'Security considerations',
              content:
                'Transaction data is fetched directly from the Safe Transaction Service API. '
                'The app performs cryptographic verification and, when supported, simulation '
                'to show you what the transaction is expected to do before you sign it with '
                'your hardware wallet. Actual execution onchain can still differ (see the '
                'MEV note on the simulation screen).',
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 32),

            // Close button
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Got it'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    final sectionColor = color ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: sectionColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: sectionColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
