import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';

class NetworksListingConfigScreen extends StatefulWidget {
  const NetworksListingConfigScreen({super.key});

  @override
  State<NetworksListingConfigScreen> createState() => _NetworksListingConfigScreenState();
}

class _NetworksListingConfigScreenState extends State<NetworksListingConfigScreen> {
  late StreamSubscription _configChangeSubscription;

  @override
  void initState() {
    super.initState();
    _configChangeSubscription = eventBus.on<OnNodeConfigChange>().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _configChangeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networks = availableNetworks.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Networks Configurations', style: TextStyle(fontSize: 20),),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
        itemCount: networks.length,
        itemBuilder: (context, index) {
          final network = networks[index];
          return Column(
            children: [
              _NetworkCard(network: network),
              if (index < (networks.length-1))
                Divider()
            ],
          );
        },
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final Network network;

  const _NetworkCard({required this.network});

  @override
  Widget build(BuildContext context) {
    final isCustom = NetworkConfigBox.hasCustomConfig(network.chainId);

    return InkWell(
      onTap: () {
        context.go('/settings/node-settings/configure', extra: network.chainId);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ThemeConfig.spacingSmall, vertical: ThemeConfig.spacingXSmall),
        child: Row(
          children: [
            NetworkLogo(network: network, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chain ID: ${network.chainId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(isCustom: isCustom),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isCustom;

  const _StatusChip({required this.isCustom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCustom
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCustom ? 'Custom' : 'Default',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isCustom
              ? Theme.of(context).textTheme.labelSmall?.color
              : Theme.of(context).colorScheme.onPrimaryContainer
        ),
      ),
    );
  }
}
