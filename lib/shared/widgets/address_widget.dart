import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blockies/blockies.dart';
import 'package:safe_opensig/shared/utils/utilities.dart';
import 'package:safe_opensig/shared/widgets/address_detail_sheet.dart';

/// A reusable widget for displaying EVM addresses with consistent UX.
///
/// Features:
/// - Tap: Opens bottom sheet with full address, blockies, copy, and explorer link
/// - Long press: Instantly copies address to clipboard
/// - Consistent truncation and styling across the app
class AddressWidget extends StatelessWidget {
  /// The EVM address to display
  final String address;

  /// Optional chain ID for network-aware block explorer links
  final int? chainId;

  /// Whether to show the blockies avatar
  final bool showBlockies;

  /// Number of characters to show on each end (e.g., 6 = "0x1234...5678")
  final int truncateLength;

  /// Optional custom text style
  final TextStyle? style;

  /// Size of the blockies avatar in pixels
  final double blockiesSize;

  /// Whether to enable tap/long press interactions
  final bool interactive;

  const AddressWidget({
    Key? key,
    required this.address,
    this.chainId,
    this.showBlockies = true,
    this.truncateLength = 6,
    this.style,
    this.blockiesSize = 24,
    this.interactive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validate address
    final isValid = Utilities.isValidAddress(address);

    // If invalid or non-interactive, display as plain text
    if (!isValid || !interactive) {
      return _buildContent(context);
    }

    // Wrap with gesture detector for interactions
    return GestureDetector(
      onTap: () => _handleTap(context),
      onLongPress: () => _handleLongPress(context),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final truncatedAddress = _truncateAddress(address);
    final isValid = Utilities.isValidAddress(address);

    // Add dotted underline for interactive addresses
    final TextStyle effectiveStyle = (style ?? const TextStyle()).copyWith(
      decoration: (interactive && isValid) ? TextDecoration.underline : style?.decoration,
      decorationStyle: (interactive && isValid) ? TextDecorationStyle.dotted : style?.decorationStyle,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBlockies) ...[
          _buildBlockies(),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            truncatedAddress,
            softWrap: true,
            maxLines: 3,
            style: effectiveStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockies() {
    return SizedBox(
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
    );
  }

  String _truncateAddress(String addr) {
    if (addr.length <= truncateLength * 2 + 2) {
      return addr;
    }

    final prefix = addr.startsWith('0x') ? '0x' : '';
    final withoutPrefix = addr.startsWith('0x') ? addr.substring(2) : addr;

    if (withoutPrefix.length <= truncateLength * 2) {
      return addr;
    }

    final start = withoutPrefix.substring(0, truncateLength);
    final end = withoutPrefix.substring(withoutPrefix.length - truncateLength);

    return '$prefix$start...$end';
  }

  void _handleTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AddressDetailSheet(
        address: address,
        chainId: chainId,
        blockiesSize: 64,
      ),
    );
  }

  void _handleLongPress(BuildContext context) {
    try {
      Clipboard.setData(ClipboardData(text: address));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to copy address'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
