import 'package:safe_opensig/shared/models/safe_transaction_model.dart';

/// Represents a transaction from the Safe Transaction Service API
/// This model mirrors the structure returned by the Safe API and provides
/// conversion to the SafeTransaction model used throughout the app.
class SafeAPITransaction extends SafeTransaction {
  final String safeTxHash;
  final int confirmations;
  final int confirmationsRequired;
  final DateTime? submissionDate;

  SafeAPITransaction({
    required this.safeTxHash,
    required super.to,
    required super.value,
    required super.data,
    required super.operation,
    required super.safeTxGas,
    required super.baseGas,
    required super.gasPrice,
    required super.gasToken,
    required super.refundReceiver,
    required super.nonce,
    required this.confirmations,
    required this.confirmationsRequired,
    this.submissionDate,
  });

  factory SafeAPITransaction.fromJson(Map<String, dynamic> json) {
    try {
      return SafeAPITransaction(
        safeTxHash: json['safeTxHash'] as String,
        to: json['to'] as String,
        value: _parseBigInt(json['value']),
        data: json['data'] as String? ?? '0x',
        operation: _parseInt(json['operation']),
        safeTxGas: _parseBigInt(json['safeTxGas']),
        baseGas: _parseBigInt(json['baseGas']),
        gasPrice: _parseBigInt(json['gasPrice']),
        gasToken: json['gasToken'] as String,
        refundReceiver: json['refundReceiver'] as String? ??
            '0x0000000000000000000000000000000000000000',
        nonce: _parseBigInt(json['nonce']),
        confirmations: (json['confirmations'] as List?)?.length ?? 0,
        confirmationsRequired: _parseInt(json['confirmationsRequired']),
        submissionDate: json['submissionDate'] != null
            ? DateTime.tryParse(json['submissionDate'] as String)
            : null,
      );
    } catch (e) {
      throw FormatException('Failed to parse SafeApiTransaction: $e');
    }
  }

  SafeTransaction toSafeTransaction() {
    return SafeTransaction(
      to: to,
      value: value,
      data: data,
      operation: operation,
      safeTxGas: safeTxGas,
      baseGas: baseGas,
      gasPrice: gasPrice,
      gasToken: gasToken,
      refundReceiver: refundReceiver,
      nonce: nonce,
    );
  }

  static BigInt _parseBigInt(dynamic value) {
    if (value is BigInt) {
      return value;
    }
    if (value is int) {
      return BigInt.from(value);
    }
    if (value is String) {
      if (value.startsWith('0x') || value.startsWith('0X')) {
        return BigInt.parse(value.substring(2), radix: 16);
      }
      return BigInt.parse(value);
    }
    throw FormatException('Cannot parse BigInt from $value (${value.runtimeType})');
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.parse(value);
    }
    throw FormatException('Cannot parse int from $value (${value.runtimeType})');
  }

  String get operationType {
    switch (operation) {
      case 0:
        return 'CALL';
      case 1:
        return 'DELEGATECALL';
      default:
        return 'UNKNOWN';
    }
  }

  bool get isFullyConfirmed => confirmations >= confirmationsRequired;

  double get confirmationProgress {
    if (confirmationsRequired == 0) return 1.0;
    return (confirmations / confirmationsRequired).clamp(0.0, 1.0);
  }
}
