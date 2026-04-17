import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/models/custom_network_config.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';

class NetworkConfigScreen extends StatefulWidget {
  final int chainId;

  const NetworkConfigScreen({super.key, required this.chainId});

  @override
  State<NetworkConfigScreen> createState() => _NetworkConfigScreenState();
}

class _NetworkConfigScreenState extends State<NetworkConfigScreen> {
  late Network _network;
  late StreamSubscription _configChangeSubscription;

  @override
  void initState() {
    super.initState();
    _network = getDefaultNetwork(widget.chainId);
    _configChangeSubscription = eventBus.on<OnNodeConfigChange>().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _configChangeSubscription.cancel();
    super.dispose();
  }

  bool get _isCustom => NetworkConfigBox.hasCustomConfig(widget.chainId);

  CustomNetworkConfig? get _customConfig =>
      NetworkConfigBox.getConfig(widget.chainId);

  Future<void> _revertToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revert to Recommended'),
        content: const Text(
          'This will remove your custom node configuration and revert to the recommended defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await NetworkConfigBox.removeConfig(widget.chainId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = _isCustom;
    final config = _customConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Configuration'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNetworkCard(theme, isCustom),

                  if (isCustom && config != null) ...[
                    const SizedBox(height: ThemeConfig.spacingLarge),
                    _buildCustomConfigDetails(theme, config),
                  ],

                  const SizedBox(height: ThemeConfig.spacingXLarge),
                  if (!isCustom)
                    _buildSecurityBadge(theme),
                ],
              ),
            ),
          ),
          _buildBottomActions(theme, isCustom),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(ThemeData theme, bool isCustom) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NetworkLogo(network: _network, size: 40),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Configuration',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _network.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCustom
                        ? 'Using custom node configuration. Override settings can be edited.'
                        : 'This configuration is optimized for high security and performance using verified nodes.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomConfigDetails(ThemeData theme, CustomNetworkConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary RPC URL
        _buildSectionLabel(theme, 'Primary RPC URL'),
        const SizedBox(height: ThemeConfig.spacingSmall),
        _buildUrlRow(theme, config.primaryNodeUrl),

        // Secondary Nodes
        if (config.secondaryNodeUrls.isNotEmpty) ...[
          const SizedBox(height: ThemeConfig.spacingLarge),
          _buildSectionLabel(theme, 'Secondary Nodes'),
          const SizedBox(height: ThemeConfig.spacingSmall),
          ...config.secondaryNodeUrls.map(
            (url) => Padding(
              padding: const EdgeInsets.only(bottom: ThemeConfig.spacingSmall),
              child: _buildUrlRow(theme, url),
            ),
          ),
        ],

        // Block Explorer
        if (config.explorerUrl != null &&
            config.explorerUrl!.isNotEmpty) ...[
          const SizedBox(height: ThemeConfig.spacingLarge),
          _buildSectionLabel(theme, 'Block Explorer URL'),
          const SizedBox(height: ThemeConfig.spacingSmall),
          _buildUrlRow(theme, config.explorerUrl!),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildUrlRow(ThemeData theme, String url) {
    return Text(
      url,
      style: theme.textTheme.bodyMedium,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSecurityBadge(ThemeData theme) {
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5);

    return Column(
      children: [
        Icon(
          Icons.verified_user,
          size: 32,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 10),
        Text(
          'Recommended Configuration Active',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _BadgeItem(
                icon: Icons.hub_outlined,
                label: '3+ Independent Nodes',
                description: 'for State verification',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              // todo review this badge whether should be kept or not
              child: _BadgeItem(
                icon: Icons.all_inclusive,
                label: 'Unlimited',
                description: 'Simulations / mo',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Multiple independent nodes cross-check every transaction, so no single node can mislead you.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme, bool isCustom) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ThemeConfig.spacingMedium,
          ThemeConfig.spacingSmall,
          ThemeConfig.spacingMedium,
          ThemeConfig.spacingMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go(
                    '/settings/node-settings/configure/override',
                    extra: widget.chainId,
                  );
                },
                icon: Icon(
                  isCustom ? Icons.edit : Icons.tune,
                  size: 20,
                ),
                label: Text(
                  isCustom ? 'Edit Configuration' : 'Override Configuration',
                ),
              ),
            ),
            if (isCustom) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _revertToDefault,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Revert to Recommended'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              isCustom
                  ? 'Custom nodes are active for this network'
                  : 'Overriding configuration is not recommended for most users',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final ThemeData theme;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 115,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}