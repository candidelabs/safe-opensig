import 'package:flutter/material.dart';
import 'package:safe_opensig/shared/models/safe_api_transaction_model.dart';
import 'package:safe_opensig/shared/utils/utilities.dart';
import 'package:safe_opensig/shared/widgets/address_widget.dart';

class SafeAPITransactionCard extends StatelessWidget {
  final SafeAPITransaction transaction;
  final String nativeCurrencySymbol;
  final int chainId;
  final VoidCallback onSelect;

  const SafeAPITransactionCard({
    super.key,
    required this.transaction,
    required this.nativeCurrencySymbol,
    required this.chainId,
    required this.onSelect,
  });

  /// Determine the primary action description based on transaction data
  String get _primaryAction {
    final hasData = transaction.data.isNotEmpty && transaction.data != '0x';
    final hasValue = transaction.value > BigInt.zero;
    final formattedValue = Utilities.formatCryptoAmount(transaction.value, 18);

    if (hasValue && hasData) {
      return 'Send $formattedValue $nativeCurrencySymbol + Call';
    } else if (hasValue) {
      return 'Send $formattedValue $nativeCurrencySymbol';
    } else if (hasData) {
      return 'Contract call';
    } else {
      return 'Empty transaction';
    }
  }

  bool get _isDelegateCall => transaction.operation == 1;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month;
    final day = local.day;
    final year = local.year;
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year, $hour:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    final isReady = transaction.isFullyConfirmed;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isDelegateCall
              ? Colors.orange.shade400
              : Theme.of(context).dividerColor,
          width: _isDelegateCall ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning banner for DELEGATECALL
              if (_isDelegateCall) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, size: 14, color: Colors.orange.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'DELEGATECALL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Row 1: Nonce + Primary action + Confirmations
              Row(
                children: [
                  // Nonce
                  Text(
                    '#${transaction.nonce}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 8),
                  // Primary action
                  Expanded(
                    child: Text(
                      _primaryAction,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirmation status
                  _buildConfirmationBadge(context, isReady),
                ],
              ),

              const SizedBox(height: 10),

              // To address (subtle)
              Row(
                children: [
                  Text(
                    'To: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  AddressWidget(
                    address: transaction.to,
                    chainId: chainId,
                    truncateLength: 6,
                    showBlockies: false,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Created date (prominent) + Arrow
              Row(
                children: [
                  if (transaction.submissionDate != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(transaction.submissionDate!),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationBadge(BuildContext context, bool isReady) {
    if (isReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Ready',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              '${transaction.confirmations}/${transaction.confirmationsRequired}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }
  }
}
