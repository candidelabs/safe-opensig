import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:safe_verify/shared/constants/network_constants.dart';
import 'package:safe_verify/shared/constants/safe_hashes.dart';
import 'package:safe_verify/shared/models/network_model.dart';
import 'package:safe_verify/shared/utils/abi_utils.dart';
import 'package:version/version.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class SafeAccount with EquatableMixin {
  final String id;
  String name;
  String address;
  int chainId;
  String version;

  SafeAccount({
    required this.id,
    required this.name,
    required this.address,
    required this.chainId,
    required this.version,
  });

  Network get network => availableNetworks[chainId]!;

  @override
  List<Object> get props => [id, address];

  SafeAccount copyWith({
    String? id,
    String? name,
    String? address,
    int? chainId,
    String? version,
  }) {
    return SafeAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      chainId: chainId ?? network.chainId,
      version: version ?? this.version,
    );
  }

  String getDomainHash(){
    String domainSeparatorTypeHash = DOMAIN_SEPARATOR_TYPEHASH;
    var accountVersion = Version.parse(version);
    Uint8List encodedDomain;
    if (accountVersion <= Version.parse("1.2.0")){
      domainSeparatorTypeHash = DOMAIN_SEPARATOR_TYPEHASH_OLD;
      encodedDomain = encodeAbi(
        ["bytes32", "address"],
        [hexToBytes(domainSeparatorTypeHash), EthereumAddress.fromHex(address)]
      );
    }else{
      encodedDomain = encodeAbi(
        ["bytes32", "uint256", "address"],
        [hexToBytes(domainSeparatorTypeHash), BigInt.from(network.chainId), EthereumAddress.fromHex(address)]
      );
    }
    return bytesToHex(keccak256(encodedDomain), include0x: true);
  }

  Future<BigInt?> getNonce() async {
    try {
      var response = await network.provider.callRaw(
          contract: EthereumAddress.fromHex(address),
          data: hexToBytes("0xaffed0e0")
      );
      return BigInt.parse(response);
    } catch (e) {
      return null;
    }
  }

  /// Converts SafeAccount to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'chainId': chainId,
      'version': version,
    };
  }

  /// Creates SafeAccount from JSON map
  factory SafeAccount.fromJson(Map<String, dynamic> json) {
    return SafeAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      chainId: json['chainId'] as int,
      version: json['version'] as String,
    );
  }

}