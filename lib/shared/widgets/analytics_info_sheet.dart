import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalyticsInfoSheet extends StatelessWidget {
  const AnalyticsInfoSheet({super.key});

  static const _docsUrl =
      'https://github.com/candidelabs/safe-opensig/blob/main/docs/analytics.md';

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: AnalyticsInfoSheet(),
          ),
        ),
      ),
    );
  }

  Future<void> _openDocs() async {
    final uri = Uri.parse(_docsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: mutedColor,
      height: 1.45,
    );
    final sectionTitleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('About usage data', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Off by default. You can change this in Settings at any time.',
          style: bodyStyle,
        ),
        const SizedBox(height: 20),
        Text('What we never send', style: sectionTitleStyle),
        const SizedBox(height: 8),
        _Bullet(text: 'Wallet, Safe, or owner addresses', style: bodyStyle),
        _Bullet(text: 'Transaction hashes or calldata', style: bodyStyle),
        _Bullet(
          text: 'Token amounts, recipients, or contract details',
          style: bodyStyle,
        ),
        _Bullet(
          text: 'RPC endpoints or custom network configuration',
          style: bodyStyle,
        ),
        _Bullet(text: 'Account names you entered', style: bodyStyle),
        const SizedBox(height: 20),
        Text('What we do send', style: sectionTitleStyle),
        const SizedBox(height: 8),
        Text(
          'Anonymous counters: which flows are used, which chains, and how '
          'long simulations take. No personal or onchain identifiers.',
          style: bodyStyle,
        ),
        const SizedBox(height: 20),
        Text('Where it goes', style: sectionTitleStyle),
        const SizedBox(height: 8),
        Text(
          'Directly to a self-hosted Aptabase instance run by Candide Labs. '
          'Open source, no third-party processing, no cookies, no advertising '
          'IDs.',
          style: bodyStyle,
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openDocs,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View full documentation'),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _Bullet({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
