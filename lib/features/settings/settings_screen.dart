import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _docsUrl = 'https://github.com/candidelabs/safe-opensig';

  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/accounts')),
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
        child: Column(
          children: [
            _NetworkConfigCard(theme: theme),
            const SizedBox(height: ThemeConfig.spacingSmall),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Documentation',
              trailing: Icon(Icons.open_in_new, size: 18, color: mutedColor),
              onTap: () => _openDocs(),
            ),
            const SizedBox(height: ThemeConfig.spacingSmall),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Safe Opensig',
              trailing: _version.isNotEmpty
                  ? Text(
                      'v$_version',
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                    )
                  : null,
              onTap: () => _showAbout(context),
            ),
          ],
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

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AboutDialog(version: _version),
    );
  }
}

class _NetworkConfigCard extends StatelessWidget {
  final ThemeData theme;

  const _NetworkConfigCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: InkWell(
        onTap: () => context.go('/settings/node-settings'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.hub_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Configuration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage node endpoints and protocol RPCs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog({required this.version});

  final String version;

  static const _githubUrl = 'https://github.com/candidelabs/safe-opensig';
  static const _xUrl = 'https://x.com/candidelabs';
  static const _websiteUrl = 'https://candide.dev/opensig';

  static const _features = [
    ('Decode & verify Safe transactions before signing', Icons.verified_outlined),
    ('Simulate transactions with EVM tracing locally', Icons.play_circle_outline),
    ('Multi-node state verification for trust minimization', Icons.hub_outlined),
    ('Hardware wallet screen preview (Ledger)', Icons.security_outlined),
    ('13+ EVM chains supported', Icons.language),
    ('No data collection. Stored locally on device', Icons.lock_outline),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/ic_logo.png', width: 56, height: 56),
              const SizedBox(height: 12),
              Text(
                'Safe OpenSig',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                version.isNotEmpty ? 'v$version' : '',
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Eliminate blind signing for Safe multisig transactions',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Features',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              ..._features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(f.$2, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f.$1,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    icon: Icons.code,
                    label: 'GitHub',
                    onTap: () => _open(_githubUrl),
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    icon: Icons.alternate_email,
                    label: 'X',
                    onTap: () => _open(_xUrl),
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    icon: Icons.public,
                    label: 'Website',
                    onTap: () => _open(_websiteUrl),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Developed by Candide Labs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
