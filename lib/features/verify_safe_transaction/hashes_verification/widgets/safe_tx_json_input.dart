import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_verify/shared/models/safe_transaction_model.dart';
import 'package:wallet/wallet.dart';

class SafeTxJsonInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool legacyJson; // for Safe versions < 1.0.0 (`baseGas` was then called `dataGas`)
  final Function(SafeTransaction) onValidInput;

  const SafeTxJsonInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.legacyJson,
    required this.onValidInput,
  });

  @override
  State<SafeTxJsonInput> createState() => _SafeTxJsonInputState();
}

class _SafeTxJsonInputState extends State<SafeTxJsonInput> {
  List<(String, String)> requiredFields = [];
  String? _validationError;

  @override
  void initState() {
    requiredFields = [
      ("to", "address"),
      ("value", "bigint"),
      ("data", "bytes"),
      ("operation", "int"),
      (widget.legacyJson ? "dataGas" : "baseGas", "bigint"),
      ("gasPrice", "bigint"),
      ("gasToken", "address"),
      ("refundReceiver", "address"),
      ("nonce", "int"),
      ("safeTxGas", "bigint"),
    ];
    widget.controller.addListener(_validateInput);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      setState(() {
        _validationError = null;
      });
      return;
    }
    var errors = [];
    try {
      var json = jsonDecode(text) as Map<String, dynamic>;
      if (json.containsKey("message")){
        json = json["message"];
      }
      Map<String, dynamic> safeTxJson = {};
      for (var field in requiredFields){
        if (!json.containsKey(field.$1)){
          errors.add("Missing '${field.$1}' field (${field.$2})");
          continue;
        }
        var fieldData = json[field.$1];
        if (field.$2 == "int"){
          if (fieldData.runtimeType != int){
            errors.add("Error parsing '${field.$1}' field (${field.$2})");
            continue;
          }
        }else{
          if (fieldData.runtimeType != String){
            errors.add("Error parsing '${field.$1}' field (${field.$2})");
            continue;
          }
        }
        var errorString = "";
        switch (field.$2) {
          case "address":
            fieldData = (fieldData as String).replaceAll("0x", "");
            if (fieldData.length > 40){
              errorString = "Field '${field.$1}' is not a properly formatted address";
              break;
            }
            var isValidAddress = EthereumAddress.isEip55ValidEthereumAddress(fieldData);
            if (!isValidAddress){
              errorString = "Field '${field.$1}' is not a properly formatted address";
            }
            safeTxJson[field.$1] = "0x$fieldData";
            break;
          case "bigint":
            var bigIntValue = BigInt.tryParse(fieldData);
            if (bigIntValue == null){
              errorString = "Field '${field.$1}' is not a properly formatted BigInt (radix-10 and radix-16 are accepted)";
            }
            safeTxJson[field.$1] = bigIntValue;
            break;
          case "int":
            if (fieldData < 0){
              errorString = "Field '${field.$1}' cannot have negative values";
            }
            safeTxJson[field.$1] = fieldData;
            break;
          case "bytes":
            String cleanedInput = fieldData.toLowerCase().replaceFirst("0x", "");
            final hexPattern = RegExp(r'^[0-9a-f]*$');
            final validHex = hexPattern.hasMatch(cleanedInput);
            if (!validHex){
              errorString = "Field '${field.$1}' is not a properly formatted bytes hex string";
            }
            safeTxJson[field.$1] = fieldData;
            break;
        }
        if (errorString.isNotEmpty){
          errors.add(errorString);
        }
      }
      setState(() {
        if (errors.isEmpty){
          widget.onValidInput(SafeTransaction.fromJson(safeTxJson, widget.legacyJson));
          _validationError = null;
        }else{
          _validationError = errors.join("\n");
        }
      });
    } catch (e) {
      setState(() {
        _validationError = 'Invalid JSON format';
      });
    }
  }

  void prettifyJson() {
    try {
      final dynamic parsedJson = jsonDecode(widget.controller.text);
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final prettifiedJson = encoder.convert(parsedJson);
      setState(() => widget.controller.text = prettifiedJson);
    } catch (e) {
      return;
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
            onPressed: () => prettifyJson(),
            tooltip: "Prettify JSON",
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
            icon: Icon(Icons.code_sharp, size: 16),
          ),
        )
      ],
    );
  }
}