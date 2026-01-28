import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';

class SafeHashesVerifyScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction safeTransaction;

  const SafeHashesVerifyScreen({
    super.key,
    required this.safeAccount,
    required this.safeTransaction,
  });

  @override
  State<SafeHashesVerifyScreen> createState() => _SafeHashesVerifyScreenState();
}

class _SafeHashesVerifyScreenState extends State<SafeHashesVerifyScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Transaction')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _NonceControl(
                      initialValue: widget.safeTransaction.nonce,
                      latestNonce: widget.safeTransaction.latestNonce,
                      onChange: (_nonce) => setState(() => widget.safeTransaction.nonce = _nonce),
                    ),
                    const SizedBox(height: 16),
                    _AccountDetailsCard(safeAccount: widget.safeAccount),
                    const SizedBox(height: 16),
                    _TransactionHashesCard(
                      safeAccount: widget.safeAccount,
                      safeTransaction: widget.safeTransaction,
                    ),
                    const SizedBox(height: 16),
                    _TransactionJsonCard(safeTransaction: widget.safeTransaction),
                    const SizedBox(height: 16),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            GoRouter.of(context).go("/accounts",);
                          },
                          child: const Text('Finish'),
                        ),
                        SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () {
                            GoRouter.of(context).push(
                              "/verify-transaction/ledger",
                              extra: (widget.safeAccount, widget.safeTransaction)
                            );
                          },
                          child: const Text('Verify Ledger Screens'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}

class _AccountDetailsCard extends StatefulWidget {
  final SafeAccount safeAccount;

  const _AccountDetailsCard({required this.safeAccount});

  @override
  State<_AccountDetailsCard> createState() => _AccountDetailsCardState();
}

class _AccountDetailsCardState extends State<_AccountDetailsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(widget.safeAccount.name),
            subtitle: Text(
              '${widget.safeAccount.network.name} · Safe v${widget.safeAccount.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: IconButton(
              icon: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                child: const Icon(Icons.expand_more),
              ),
              onPressed: _toggleExpansion,
            ),
            onTap: _toggleExpansion,
          ),
          ClipRect(
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Account Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _AccountDetailRow(label: 'Name', value: widget.safeAccount.name),
                    _AccountDetailRow(
                      label: 'Address',
                      value: widget.safeAccount.address,
                    ),
                    _AccountDetailRow(
                      label: 'Network',
                      value: widget.safeAccount.network.name,
                    ),
                    _AccountDetailRow(
                      label: 'Version',
                      value: widget.safeAccount.version,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionHashesCard extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction safeTransaction;

  const _TransactionHashesCard({
    required this.safeAccount,
    required this.safeTransaction,
  });

  @override
  State<_TransactionHashesCard> createState() => _TransactionHashesCardState();
}

class _TransactionHashesCardState extends State<_TransactionHashesCard> {
  (bool, String, String, String)? _hashes;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.safeTransaction.calculateHashes(widget.safeAccount).then((result) {
      if (!mounted) return;
      setState(() => _hashes = result);
    });
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hashes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_hashes == null)
              const Center(child: CircularProgressIndicator())
            else if (!_hashes!.$1)
              const Text('Failed to calculate hashes')
            else
              Builder(
                builder: (context) {
                  final (_, domainHash, messageHash, txHash) = _hashes!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HashDetailRow(
                        label: 'Domain Hash',
                        value: domainHash,
                      ),
                      _HashDetailRow(
                        label: 'Message hash',
                        value: messageHash,
                      ),
                      _HashDetailRow(
                        label: 'safeTxHash',
                        value: txHash,
                      ),
                    ],
                  );
                }
              )
          ],
        ),
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _AccountDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _HashDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _HashDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    tooltip: 'Copy to clipboard',
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

class _TransactionJsonCard extends StatefulWidget {
  final SafeTransaction safeTransaction;

  const _TransactionJsonCard({required this.safeTransaction});

  @override
  State<_TransactionJsonCard> createState() => _TransactionJsonCardState();
}

class _TransactionJsonCardState extends State<_TransactionJsonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionData = {
      'to': widget.safeTransaction.to,
      'value': widget.safeTransaction.value.toString(),
      'data': widget.safeTransaction.data,
      'operation': widget.safeTransaction.operation,
      'safeTxGas': widget.safeTransaction.safeTxGas.toString(),
      'baseGas': widget.safeTransaction.baseGas.toString(),
      'gasPrice': widget.safeTransaction.gasPrice.toString(),
      'gasToken': widget.safeTransaction.gasToken,
      'refundReceiver': widget.safeTransaction.refundReceiver,
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(transactionData);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Transaction Data'),
            trailing: IconButton(
              icon: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                child: const Icon(Icons.expand_more),
              ),
              onPressed: _toggleExpansion,
            ),
            onTap: _toggleExpansion,
          ),
          ClipRect(
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        jsonString,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: jsonString));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                          tooltip: 'Copy JSON to clipboard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NonceControl extends StatefulWidget {
  final BigInt? initialValue;
  final BigInt? latestNonce;
  final Function(BigInt) onChange;

  const _NonceControl({this.initialValue, this.latestNonce, required this.onChange});

  @override
  State<_NonceControl> createState() => _NonceControlState();
}

class _NonceControlState extends State<_NonceControl> {
  late BigInt _nonce;
  Timer? _incrementTimer;
  Timer? _decrementTimer;

  @override
  void initState() {
    super.initState();
    _nonce = widget.initialValue ?? BigInt.zero;
  }

  @override
  void dispose() {
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    super.dispose();
  }

  void _startIncrementing() {
    _incrementTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _nonce = _nonce + BigInt.one;
      });
    });
  }

  void _startDecrementing() {
    _decrementTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        if (_nonce > BigInt.zero) {
          _nonce = _nonce - BigInt.one;
        }
      });
    });
  }

  void _stopChanging() {
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    widget.onChange(_nonce);
  }

  void _incrementNonce() {
    setState(() {
      _nonce = _nonce + BigInt.one;
    });
    widget.onChange(_nonce);
  }

  void _decrementNonce() {
    setState(() {
      if (_nonce > BigInt.zero) {
        _nonce = _nonce - BigInt.one;
      }
    });
    widget.onChange(_nonce);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Nonce',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                GestureDetector(
                  onTapDown: (_) => _startDecrementing(),
                  onTapUp: (_) => _stopChanging(),
                  onTapCancel: _stopChanging,
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementNonce,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 75, maxWidth: 120),
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        text: '$_nonce',
                        children: [
                          if (widget.latestNonce == _nonce)
                            TextSpan(
                              text: "\nlatest",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                              )
                            )
                        ]
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (_) => _startIncrementing(),
                  onTapUp: (_) => _stopChanging(),
                  onTapCancel: _stopChanging,
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementNonce,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}