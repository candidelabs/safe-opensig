import 'package:flutter/material.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';
import 'package:safe_verify/shared/models/safe_transaction_model.dart';

class SafeLedgerVerifyScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction safeTransaction;
  final BigInt nonce;
  const SafeLedgerVerifyScreen({super.key, required this.safeAccount, required this.safeTransaction, required this.nonce});

  @override
  State<SafeLedgerVerifyScreen> createState() => _SafeLedgerVerifyScreenState();
}

class _SafeLedgerVerifyScreenState extends State<SafeLedgerVerifyScreen> {

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
