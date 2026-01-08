import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_verify/core/theme/theme_config.dart';
import 'package:safe_verify/shared/models/safe_transaction_model.dart';
import 'package:safe_verify/shared/utils/utilities.dart';
import 'package:toastification/toastification.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class SafeTxCalldataInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool legacyJson; // for Safe versions < 1.0.0 (`baseGas` was then called `dataGas`)
  final Function(SafeTransaction) onValidInput;

  const SafeTxCalldataInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.legacyJson,
    required this.onValidInput,
  });

  @override
  State<SafeTxCalldataInput> createState() => _SafeTxCalldataInputState();
}

class _SafeTxCalldataInputState extends State<SafeTxCalldataInput> {
  SafeTransaction? safeTransaction;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    safeTransaction = null;
    var callData = widget.controller.text;
    if (callData.isEmpty) {
      setState(() {
        _validationError = null;
      });
      return;
    }
    if (callData.startsWith("0x")){
      callData = callData.replaceFirst("0x", "");
    }
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(callData)) {
      setState(() {
        _validationError = 'Error parsing hex data';
      });
      return;
    }
    final safeTxJson = Utilities.decodeSafeTxCalldata(callData, widget.legacyJson);
    if (safeTxJson == null){
      setState(() {
        _validationError = 'Error parsing hex data';
      });
    }else{
      safeTransaction = SafeTransaction.fromJson(safeTxJson, widget.legacyJson);
      setState(() {
        _validationError = null;
      });
      widget.onValidInput(safeTransaction!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 15),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLines: 15,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              errorText: _validationError,
            ),
          ),
        ),
        Positioned(
          right: 15,
          child: IconButton(
            onPressed: () {
              if (safeTransaction == null){
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  style: ToastificationStyle.flatColored,
                  title: Text("Error"),
                  description: Text("CallData is not a valid Safe transaction"),
                  alignment: Alignment.bottomCenter,
                  borderRadius: BorderRadius.circular(1000),
                  autoCloseDuration: const Duration(seconds: 2),
                  animationDuration: Duration(milliseconds: 400),
                  closeOnClick: true
                );
                return;
              }
              WoltModalSheet.show(
                context: context,
                enableDrag: true,
                showDragHandle: true,
                barrierDismissible: true,
                modalTypeBuilder: (_) => WoltBottomSheetType().copyWith(
                  minFlingVelocity: 900,
                  closeProgressThreshold: 0.9,
                  reverseTransitionDuration: Duration(milliseconds: 350)
                ),
                pageListBuilder: (bottomSheetContext) => [
                  WoltModalSheetPage(
                    navBarHeight: 20,
                    child: _SafeTransactionJsonSheet(
                      safeTransaction: safeTransaction!,
                      legacyJson: widget.legacyJson,
                    ),
                  ),
                ],
              );
            },
            tooltip: "Analyze calldata",
            color: Theme.of(context).colorScheme.primary,
            style: ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: Theme.of(context).primaryColor
                )
              )),
              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surface)
            ),
            icon: Icon(Icons.remove_red_eye_outlined, size: 16),
          ),
        )
      ],
    );
  }
}

class _SafeTransactionJsonSheet extends StatelessWidget {
  final bool legacyJson; // for Safe versions < 1.0.0 (`baseGas` was then called `dataGas`)
  final SafeTransaction safeTransaction;
  const _SafeTransactionJsonSheet({required this.safeTransaction, required this.legacyJson});

  @override
  Widget build(BuildContext context) {
    final transactionData = {
      'to': safeTransaction.to,
      'value': safeTransaction.value.toString(),
      'data': bytesToHex(hexToBytes(safeTransaction.data), include0x: true),
      'operation': safeTransaction.operation,
      'safeTxGas': safeTransaction.safeTxGas.toString(),
      'baseGas': safeTransaction.baseGas.toString(),
      'dataGas': safeTransaction.baseGas.toString(),
      'gasPrice': safeTransaction.gasPrice.toString(),
      'gasToken': safeTransaction.gasToken,
      'refundReceiver': safeTransaction.refundReceiver,
    };
    if (legacyJson){
      transactionData.remove("baseGas");
    }else{
      transactionData.remove("dataGas");
    }
    final jsonString = const JsonEncoder.withIndent('  ').convert(transactionData);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Transaction Data', style: ThemeConfig.textTheme.titleLarge,),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
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
      ],
    );
  }
}
