import 'dart:math';

import 'package:flutter/services.dart';
import 'package:safe_verify/shared/utils/abi_utils.dart';
import 'package:safe_verify/shared/utils/extensions/string_extensions.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class Utilities {
  static void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  static String truncateIfAddress(String input, {int? leadingDigits, int? trailingDigits}){
    var regex = RegExp('^(0x[a-zA-Z0-9]{${trailingDigits ?? 6}})[a-zA-Z0-9]+([a-zA-Z0-9]{${trailingDigits ?? 6}})\$');
    var matches = regex.allMatches(input);
    if (matches.isEmpty) {
      return input;
    }
    return "${matches.first.group(1)}...${matches.first.group(2)}";
  }

  static String truncate(String input, {int leadingDigits=10, int trailingDigits=6}) {
    if (input.length <= (leadingDigits+trailingDigits-3)) return input;
    return '${input.substring(0, leadingDigits)}...${input.substring(input.length - trailingDigits)}';
  }

  static String generateRandomEthereumAddress() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    final address = bytesToHex(bytes, include0x: true);
    return address;
  }

  static bool _isChecksumAddress(String address) {
    address = address.replaceAll('0x', '');
    var addressHash = bytesToHex(keccakAscii(address.toLowerCase()));
    for (var i = 0; i < 40; i++ ) {
      if ((int.parse(addressHash[i], radix: 16) > 7 && address[i].toUpperCase() != address[i]) ||
          (int.parse(addressHash[i], radix: 16) <= 7 && address[i].toLowerCase() != address[i])) {
        return false;
      }
    }
    return true;
  }

  static bool isValidAddress(String address){
    if (!RegExp(r"^(0x)?[0-9a-fA-F]{40}$").hasMatch(address)) return false; // check basic conditions
    if (RegExp(r"^(0x)?[a-f0-9]{40}$").hasMatch(address)) return true; // check all lowercase
    if (RegExp(r"^(0x)?[A-F0-9]{40}$").hasMatch(address)) return true; // check all uppercase
    return _isChecksumAddress(address); // check checksum address
  }

  static Uint8List randomBytes(int length, {bool secure = false}) {
    assert(length > 0);

    final random = secure ? Random.secure() : Random();
    final ret = Uint8List(length);

    for (var i = 0; i < length; i++) {
      ret[i] = random.nextInt(256);
    }
    return ret;
  }

  static Map<String, dynamic>? decodeSafeTxCalldata(String callData, bool legacyJson) {
    try {
      if (callData.startsWith("0x")) {
        callData = callData.replaceFirst("0x", "");
      }
      if (callData.length > 8){
        callData = callData.substring(8);
      }
      var bytes = hexToBytes(callData);
      var data = decodeAbi([
        "address",
        "uint256",
        "bytes",
        "uint8",
        "uint256",
        "uint256",
        "uint256",
        "address",
        "address",
      ], bytes);
      var result = {
        "to": (data[0] as EthereumAddress).eip55With0x,
        "value": data[1] as BigInt,
        "data": bytesToHex(data[2] as Uint8List, include0x: true),
        "operation": (data[3] as BigInt).toInt(),
        "safeTxGas": data[4] as BigInt,
        "baseGas": data[5] as BigInt,
        "dataGas": data[5] as BigInt,
        "gasPrice": data[6] as BigInt,
        "gasToken": (data[7] as EthereumAddress).eip55With0x,
        "refundReceiver": (data[8] as EthereumAddress).eip55With0x
      };
      if (legacyJson){
        result.remove("baseGas");
      }else{
        result.remove("dataGas");
      }
      return result;
    } catch (e) {
      return null;
    }
  }

  static BigInt? decodeBigInt(dynamic value, {bool defaultsToZero = false}){
    if (value == null) {
      if (defaultsToZero) return BigInt.zero;
      return null;
    }
    if (value is String){
      if (value.startsWith("0x") || !value.isNumericOnly){
        if (value == "0x") return BigInt.zero;
        return BigInt.parse(value.replaceAll("0x", ""), radix: 16);
      }else{
        return BigInt.parse(value);
      }
    }else if (value is num){
      return BigInt.from(value);
    }
    return BigInt.from(value);
  }

  static bool hasMatch(String? value, String pattern) {
    return (value == null) ? false : RegExp(pattern).hasMatch(value);
  }

  static String formatCryptoAmount(
    dynamic amount,
    int decimals,
    {
      int? displayDecimals,
      String? symbol,
    }
  ) {
    BigInt rawAmount;
    if (amount is String) {
      rawAmount = BigInt.parse(amount);
    } else if (amount is BigInt) {
      rawAmount = amount;
    } else if (amount is int) {
      rawAmount = BigInt.from(amount);
    } else {
      throw ArgumentError('Amount must be String, BigInt, or int');
    }
    final divisor = BigInt.from(10).pow(decimals);
    final integerPart = rawAmount ~/ divisor;
    final fractionalPart = rawAmount % divisor;
    //
    String decimalStr = fractionalPart.toString().padLeft(decimals, '0');
    //
    int showDecimals;
    if (displayDecimals != null) {
      showDecimals = displayDecimals;
    } else {
      if (integerPart > BigInt.from(1000)) {
        showDecimals = 2;
      } else if (integerPart > BigInt.zero) {
        showDecimals = 5;
      } else {
        showDecimals = _findSignificantDecimals(decimalStr);
      }
    }
    if (showDecimals > 0) {
      decimalStr = decimalStr.substring(0, min(showDecimals, decimalStr.length));
      decimalStr = decimalStr.replaceAll(RegExp(r'0+$'), '');
    } else {
      decimalStr = '';
    }
    String formattedInteger = _addThousandsSeparators(integerPart.toString());
    String result = formattedInteger;
    if (decimalStr.isNotEmpty) {
      result += '.$decimalStr';
    }
    if (symbol != null && symbol.isNotEmpty) {
      result += ' $symbol';
    }
    return result;
  }

  /// Finds the number of decimals needed to show the first significant digits
  static int _findSignificantDecimals(String decimalStr) {
    // Find first non-zero digit
    int firstNonZero = 0;
    for (int i = 0; i < decimalStr.length; i++) {
      if (decimalStr[i] != '0') {
        firstNonZero = i;
        break;
      }
    }

    // Show up to first 4 significant digits after leading zeros
    return min(firstNonZero + 4, decimalStr.length);
  }

  static String _addThousandsSeparators(String number) {
    final regex = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return number.replaceAllMapped(regex, (match) => '${match[1]},');
  }

}
