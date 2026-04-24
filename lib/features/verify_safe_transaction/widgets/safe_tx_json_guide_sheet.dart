import 'package:flutter/material.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/guide_slideshow.dart';

class SafeTxJsonGuideSheet extends StatelessWidget {
  const SafeTxJsonGuideSheet({super.key});

  static const _slides = <GuideSlide>[
    GuideSlide(
      index: 1,
      text: 'Create a new transaction',
      assetName: 'guide_json_1_create.png',
    ),
    GuideSlide(
      index: 2,
      text: 'Confirm the transaction.',
      assetName: 'guide_json_2_confirm.png',
    ),
    GuideSlide(
      index: 3,
      text: 'On the Review details screen, click the JSON tab and copy '
          'the transaction.',
      assetName: 'guide_json_3_review.png',
    ),
    GuideSlide(
      index: 4,
      text: 'Send the JSON from your desktop to your phone, using an '
          'encrypted method (for example, Signal), then paste it into '
          'OpenSig to verify.',
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
            'How to get the Transaction JSON',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From Safe{Wallet} at app.safe.global.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          const GuideSlideshow(slides: _slides),
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
