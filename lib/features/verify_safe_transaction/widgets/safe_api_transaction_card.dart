import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_verify/shared/models/safe_api_transaction_model.dart';
import 'package:safe_verify/shared/utils/utilities.dart';

class SafeAPITransactionCard extends StatefulWidget {
  final SafeAPITransaction transaction;
  final bool isSelected;
  final String nativeCurrencySymbol;
  final VoidCallback onTap;

  const SafeAPITransactionCard({
    super.key,
    required this.transaction,
    required this.isSelected,
    required this.nativeCurrencySymbol,
    required this.onTap,
  });

  @override
  State<SafeAPITransactionCard> createState() =>
      _SafeAPITransactionCardState();
}

class _SafeAPITransactionCardState extends State<SafeAPITransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade300,
          width: widget.isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildBasicInfo(),
              const SizedBox(height: 12),
              _buildConfirmationsInfo(),
              if (_isExpanded) ...[
                const Divider(height: 24),
                _buildExpandedDetails(),
              ],
              const SizedBox(height: 8),
              _buildExpandButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Selection indicator
        Icon(
          widget.isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: widget.isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 12),

        // Nonce
        Text(
          'Nonce: ${widget.transaction.nonce}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),

        // Operation type badge
        _buildOperationBadge(),
      ],
    );
  }

  Widget _buildOperationBadge() {
    final isCall = widget.transaction.operation == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCall ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCall ? Colors.blue.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCall ? Icons.call_made : Icons.swap_calls,
            size: 12,
            color: isCall ? Colors.blue.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            widget.transaction.operationType,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCall ? Colors.blue.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // To address
        Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'To:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Utilities.truncateIfAddress(widget.transaction.to),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _copyToClipboard(widget.transaction.to),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Value
        Row(
          children: [
            Icon(Icons.monetization_on, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Value:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Utilities.formatCryptoAmount(widget.transaction.value, 18),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),

        // Safe tx hash
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Hash:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Utilities.truncate(widget.transaction.safeTxHash),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _copyToClipboard(widget.transaction.safeTxHash),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmationsInfo() {
    final progress = widget.transaction.confirmationProgress;
    final isFullyConfirmed = widget.transaction.isFullyConfirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isFullyConfirmed ? Icons.check_circle : Icons.pending,
              size: 16,
              color: isFullyConfirmed ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Confirmations: ${widget.transaction.confirmations}/${widget.transaction.confirmationsRequired}',
              style: TextStyle(
                fontSize: 13,
                color: isFullyConfirmed ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isFullyConfirmed ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas Parameters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Safe Tx Gas', widget.transaction.safeTxGas.toString()),
        const SizedBox(height: 6),
        _buildDetailRow('Base Gas', widget.transaction.baseGas.toString()),
        const SizedBox(height: 6),
        _buildDetailRow('Gas Price', '${widget.transaction.gasPrice} wei'),
        const SizedBox(height: 6),
        _buildDetailRow('Gas Token', Utilities.truncateIfAddress(widget.transaction.gasToken)),
        const SizedBox(height: 6),
        _buildDetailRow('Refund Receiver', Utilities.truncateIfAddress(widget.transaction.refundReceiver)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        icon: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          size: 18,
        ),
        label: Text(
          _isExpanded ? 'Show less' : 'Show gas parameters',
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
