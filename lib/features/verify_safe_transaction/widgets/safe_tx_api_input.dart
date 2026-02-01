import 'package:flutter/material.dart';
import 'package:safe_opensig/features/verify_safe_transaction/widgets/safe_api_transaction_card.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_api_transaction_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/services/safe_transaction_service.dart';

enum LoadingState { idle, loading, success, error }

class SafeTxAPIInput extends StatefulWidget {
  final SafeAccount safeAccount;
  final Function(SafeTransaction) onValidInput;

  const SafeTxAPIInput({
    super.key,
    required this.safeAccount,
    required this.onValidInput,
  });

  @override
  State<SafeTxAPIInput> createState() => _SafeTxAPIInputState();
}

class _SafeTxAPIInputState extends State<SafeTxAPIInput> {
  LoadingState _state = LoadingState.idle;
  List<SafeAPITransaction>? _transactions;
  String? _errorMessage;
  final SafeTransactionService _service = SafeTransactionService();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _state = LoadingState.loading;
      _errorMessage = null;
    });

    final (success, transactions, error) = await _service.getQueuedTransactions(
      safeAddress: widget.safeAccount.address,
      chainId: widget.safeAccount.network.chainId,
      minNonce: (await widget.safeAccount.getNonce())?.toInt()
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _state = LoadingState.success;
        _transactions = transactions;
      });
    } else {
      setState(() {
        _state = LoadingState.error;
        _errorMessage = error;
      });
    }
  }

  void _onTransactionSelected(SafeAPITransaction transaction) {
    final safeTx = transaction.toSafeTransaction();
    widget.onValidInput(safeTx);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case LoadingState.idle:
      case LoadingState.loading:
        return _buildLoadingState();
      case LoadingState.error:
        return _buildErrorState();
      case LoadingState.success:
        if (_transactions == null || _transactions!.isEmpty) {
          return _buildEmptyState();
        }
        return _buildSuccessState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching queued transactions...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No queued transactions found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a transaction in your Safe wallet to see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Groups transactions by nonce for conflict detection
  Map<BigInt, List<SafeAPITransaction>> _groupByNonce(List<SafeAPITransaction> transactions) {
    final Map<BigInt, List<SafeAPITransaction>> grouped = {};
    for (final tx in transactions) {
      final nonce = tx.nonce ?? BigInt.zero;
      grouped.putIfAbsent(nonce, () => []);
      grouped[nonce]!.add(tx);
    }
    return grouped;
  }

  Widget _buildSuccessState() {
    final groupedByNonce = _groupByNonce(_transactions!);
    final sortedNonces = groupedByNonce.keys.toList()..sort();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_transactions!.length} ${_transactions!.length == 1 ? 'transaction' : 'transactions'} found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchTransactions,
                  tooltip: 'Refresh transactions',
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final nonce in sortedNonces)
              _buildNonceGroup(nonce, groupedByNonce[nonce]!),
          ],
        ),
      ),
    );
  }

  Widget _buildNonceGroup(BigInt nonce, List<SafeAPITransaction> transactions) {
    final isConflicting = transactions.length > 1;

    if (!isConflicting) {
      // Single transaction - no grouping needed
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SafeAPITransactionCard(
          transaction: transactions.first,
          nativeCurrencySymbol: widget.safeAccount.network.nativeCurrencySymbol,
          onSelect: () => _onTransactionSelected(transactions.first),
        ),
      );
    }

    // Multiple transactions with same nonce - show conflict group
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conflict warning banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade400.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conflicting transactions. Select the one you want executed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Transaction cards
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (int i = 0; i < transactions.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i < transactions.length - 1 ? 8 : 0),
                    child: SafeAPITransactionCard(
                      transaction: transactions[i],
                      nativeCurrencySymbol: widget.safeAccount.network.nativeCurrencySymbol,
                      onSelect: () => _onTransactionSelected(transactions[i]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
