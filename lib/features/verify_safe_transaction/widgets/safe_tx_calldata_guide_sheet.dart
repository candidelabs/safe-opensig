import 'package:flutter/material.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/guide_slideshow.dart';

class SafeTxCalldataGuideSheet extends StatelessWidget {
  const SafeTxCalldataGuideSheet({super.key});

  static const _slides = <GuideSlide>[
    GuideSlide(
      index: 1,
      text: 'On the Review details screen, click Execute. Do not sign '
          'yet with your signer.',
      assetName: 'guide_calldata_1_execute.png',
    ),
    GuideSlide(
      index: 2,
      text: 'In your signer, copy the Data (hex) field. If your wallet '
          'does not show it, enable the setting in your wallet '
          'preferences first.',
      assetName: 'guide_calldata_2_copy_data.png',
    ),
    GuideSlide(
      index: 3,
      text: 'Send the calldata from your desktop to your phone, using '
          'an encrypted method (for example, Signal), then paste it '
          'into OpenSig to verify.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to get the execution calldata',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You are the last signer. You are signing and executing.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          const GuideSlideshow(slides: _slides),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Other wallets (Rabby, WalletConnect, Ledger Live) expose the '
              'same Data field. The exact label may differ.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
