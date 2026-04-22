import 'package:flutter/material.dart';
import 'package:safe_opensig/core/storage/misc_box.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/shared/services/analytics_service.dart';
import 'package:safe_opensig/shared/widgets/m2_switch.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalyticsSettingsScreen extends StatefulWidget {
  const AnalyticsSettingsScreen({super.key});

  @override
  State<AnalyticsSettingsScreen> createState() =>
      _AnalyticsSettingsScreenState();
}

class _AnalyticsSettingsScreenState extends State<AnalyticsSettingsScreen> {
  static const _docsUrl =
      'https://github.com/candidelabs/safe-opensig/blob/main/docs/analytics.md';

  bool _enabled = MiscBox.isAnalyticsOptedIn();

  Future<void> _onToggle(bool value) async {
    setState(() => _enabled = value);
    await MiscBox.setAnalyticsOptedIn(value);
    Analytics.setEnabled(value);
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
    final dimColor = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor, width: 1),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Share anonymous usage',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    M2Switch(value: _enabled, onChanged: _onToggle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Help improve Safe OpenSig by sharing anonymous app-usage '
                'events. No wallet addresses, no transaction hashes, no '
                'amounts, just which flows are used and how they perform. '
                'Off by default.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingMedium),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor, width: 1),
              ),
              child: InkWell(
                onTap: _openDocs,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'View what gets collected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.open_in_new, size: 18, color: dimColor),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
