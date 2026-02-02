import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blockies/blockies.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';

class AddressDetailSheet extends StatelessWidget {
  final String address;
  final int? chainId;
  final double blockiesSize;

  const AddressDetailSheet({
    Key? key,
    required this.address,
    this.chainId,
    this.blockiesSize = 64,
  }) : super(key: key);

  void _handleCopy(BuildContext context) {
    try {
      Clipboard.setData(ClipboardData(text: address));
      Navigator.of(context).pop(); // Close the bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to copy address'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleExplorer(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open block explorer'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String getBlockExplorerUrl(int chainId, String address) {
    final network = availableNetworks[chainId]!;
    final baseUrl = network.explorers[0].$2;
    return '$baseUrl/address/$address';
  }

  @override
  Widget build(BuildContext context) {
    final explorerUrl = chainId != null
        ? getBlockExplorerUrl(chainId!, address)
        : null;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(ThemeConfig.spacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large blockies avatar
            SizedBox(
              width: blockiesSize,
              height: blockiesSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(blockiesSize / 2),
                child: Blockies(
                  seed: address.toLowerCase(),
                  color: Colors.teal,
                  spotColor: Colors.white,
                  bgColor: Colors.greenAccent,
                  size: 8,
                ),
              ),
            ),

            SizedBox(height: ThemeConfig.spacingMedium),

            // Full address display with background
            Container(
              padding: EdgeInsets.all(ThemeConfig.spacingSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: ThemeConfig.borderRadiusMedium,
              ),
              child: SelectableText(
                address,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),

            SizedBox(height: ThemeConfig.spacingMedium),

            // Copy address button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleCopy(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Address'),
              ),
            ),

            // Block explorer button (only if URL exists)
            if (explorerUrl != null) ...[
              SizedBox(height: ThemeConfig.spacingSmall),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleExplorer(context, explorerUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View on Block Explorer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
