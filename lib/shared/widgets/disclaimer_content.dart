import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DisclaimerContent extends StatefulWidget {
  const DisclaimerContent({super.key});

  static const termsUrl = 'https://www.candide.dev/legal/tos';

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
                  'Terms & Disclaimer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                const DisclaimerContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<DisclaimerContent> createState() => _DisclaimerContentState();
}

class _DisclaimerContentState extends State<DisclaimerContent> {
  late final TapGestureRecognizer _termsTapRecognizer;

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer = TapGestureRecognizer()..onTap = _openTerms;
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final uri = Uri.parse(DisclaimerContent.termsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    final body = theme.textTheme.bodySmall?.copyWith(
      color: mutedColor,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Disclaimer', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Safe OpenSig is an open-source verification tool provided "as is" '
          'by Candide Labs, without warranty of any kind. It is informational '
          'only and does not constitute financial, legal, or tax advice.',
          style: body,
        ),
        const SizedBox(height: 8),
        Text(
          'You are solely responsible for reviewing every transaction and for '
          'the consequences of signing or broadcasting it. Candide Labs is '
          'not liable for any losses arising from the use of this software.',
          style: body,
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: body,
            children: [
              const TextSpan(text: 'Full terms: '),
              TextSpan(
                text: 'candide.dev/legal/tos',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: _termsTapRecognizer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
