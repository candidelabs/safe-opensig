import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur/bc_ur.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';

/// Decodes a reconstructed BC-UR eth-sign-request into a [SafeTransaction].
///
/// ERC-4527 defines eth-sign-request as a CBOR map with integer keys:
///
///   key 1: request-id   (uuid, optional)
///   key 2: sign-data    (bytes)  ← the payload we want
///   key 3: data-type    (tag 401 wrapping an int enum)
///   key 4: chain-id     (int, default 1)
///   key 5: derivation-path (tag 304, optional)
///   key 6: address      (20-byte address, optional)
///   key 7: origin       (text, optional)
///
/// For Safe signing, data-type is 2 (eth-typed-data) and sign-data is
/// the EIP-712 typed-data JSON. Its `message` object contains the SafeTx
/// fields that OpenSig already uses in [SafeTransaction.getMessageHash]:
///
///   SafeTx(address to, uint256 value, bytes data, uint8 operation,
///           uint256 safeTxGas, uint256 baseGas, uint256 gasPrice,
///           address gasToken, address refundReceiver, uint256 nonce)
class UrPayloadDecoder {
  UrPayloadDecoder._();

  /// ERC-4527 eth-sign-request CBOR field indices.
  static const _keyRequestId = 1;
  static const _keySignData = 2;
  static const _keyDataType = 3;
  static const _keyChainId = 4;
  static const _keyDerivationPath = 5;
  static const _keyAddress = 6;
  static const _keyOrigin = 7;

  /// data-type enum values (ERC-4527).
  static const _dataTypeTransactionData = 1; // eth-transaction-data
  static const _dataTypeTypedData = 2; // eth-typed-data (EIP-712)
  static const _dataTypeRawBytes = 3; // eth-raw-bytes (EIP-191)
  static const _dataTypeTypedTransaction = 4; // eth-typed-transaction

  /// Decode a reconstructed [BCUR] into a [SafeTransaction].
  ///
  /// [legacyJson] should match the Safe account version (< 1.0.0 uses
  /// `dataGas` instead of `baseGas`).
  ///
  /// Throws [FormatException] if the UR is not an eth-sign-request, the
  /// data-type is not eth-typed-data, or the sign-data is not a valid
  /// EIP-712 SafeTx payload.
  static SafeTransaction decode(BCUR ur, {required bool legacyJson}) {
    if (ur.type != 'eth-sign-request') {
      throw FormatException(
        'Expected UR type "eth-sign-request", got "${ur.type}".',
      );
    }

    final decoded = ur.decodeData();
    if (decoded is! Map) {
      throw FormatException(
        'Expected eth-sign-request CBOR map, got ${decoded.runtimeType}.',
      );
    }

    // Extract sign-data from CBOR key 2 per the ERC-4527 CDDL.
    final signData = decoded[_keySignData];
    if (signData is! Uint8List) {
      throw FormatException(
        'eth-sign-request is missing sign-data (CBOR key $_keySignData).',
      );
    }

    // Verify data-type if present. We only support eth-typed-data (2)
    // for Safe signing. bc_ur decodes tagged values as {'tag': N, 'value': V}.
    final dataType = decoded[_keyDataType];
    if (dataType != null) {
      final dataTypeValue = dataType is Map ? dataType['value'] : dataType;
      if (dataTypeValue != _dataTypeTypedData) {
        throw FormatException(
          'Unsupported data-type $dataTypeValue. '
          'OpenSig only supports eth-typed-data ($_dataTypeTypedData) '
          'for Safe transaction verification.',
        );
      }
    }

    return _decodeEip712SignData(signData, legacyJson);
  }

  /// Parse the sign-data bytes as EIP-712 typed-data JSON and build a
  /// [SafeTransaction] from the SafeTx `message` object.
  static SafeTransaction _decodeEip712SignData(
      Uint8List bytes, bool legacyJson) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } catch (e) {
      throw FormatException(
        'sign-data is not valid UTF-8 (expected EIP-712 JSON): $e',
      );
    }

    final Map<String, dynamic> typedData;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object, got ${decoded.runtimeType}.');
      }
      typedData = decoded;
    } catch (e) {
      throw FormatException(
        'sign-data is not valid EIP-712 JSON: $e',
      );
    }

    // Unwrap the EIP-712 message. Full typed data has {types, domain, message};
    // some wallets send just the message object directly.
    final Map<String, dynamic> message;
    if (typedData.containsKey('message') && typedData['message'] is Map) {
      message = (typedData['message'] as Map).cast<String, dynamic>();
    } else {
      message = typedData;
    }

    // Validate required SafeTx fields are present.
    final required = ['to', 'value', 'data', 'operation', 'safeTxGas',
        legacyJson ? 'dataGas' : 'baseGas',
        'gasPrice', 'gasToken', 'refundReceiver', 'nonce'];
    final missing = required.where((f) => !message.containsKey(f)).toList();
    if (missing.isNotEmpty) {
      throw FormatException(
        'EIP-712 message is missing SafeTx fields: $missing',
      );
    }

    return _safeTxFromMessage(message, legacyJson);
  }

  /// Build a [SafeTransaction] from the EIP-712 message map, coercing
  /// string-encoded values to the types [SafeTransaction.fromJson] expects.
  static SafeTransaction _safeTxFromMessage(
      Map<String, dynamic> msg, bool legacyJson) {
    final bigIntFields = <String>{
      'value', 'safeTxGas', 'gasPrice',
    };
    bigIntFields.add(legacyJson ? 'dataGas' : 'baseGas');

    final cleaned = <String, dynamic>{};
    for (final entry in msg.entries) {
      var v = entry.value;
      final key = entry.key;

      if (v is String && bigIntFields.contains(key)) {
        v = _parseBigInt(v);
      }
      if (key == 'nonce') {
        if (v is String) v = _parseBigInt(v);
        if (v is BigInt) v = v.toInt();
      }
      if (key == 'operation' && v is String) {
        v = int.tryParse(v) ?? v;
      }
      cleaned[key] = v;
    }
    return SafeTransaction.fromJson(cleaned, legacyJson);
  }

  /// Parse a BigInt from a decimal or 0x-prefixed hex string.
  static BigInt _parseBigInt(String s) {
    if (s.startsWith('0x') || s.startsWith('0X')) {
      return BigInt.parse(s.substring(2), radix: 16);
    }
    return BigInt.parse(s);
  }
}
