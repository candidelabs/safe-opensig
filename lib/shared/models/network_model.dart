import 'package:equatable/equatable.dart';
import 'package:web3dart/web3dart.dart';

class Network extends Equatable {
  final String name;
  final String chainPrefix;
  final int chainId;
  final String nativeCurrencySymbol;
  final List<Web3Client> providers;
  final List<(String, String)> explorers;
  final String? logoUri;

  const Network({
    required this.name,
    required this.chainPrefix,
    required this.chainId,
    required this.nativeCurrencySymbol,
    required this.providers,
    required this.explorers,
    this.logoUri,
  });

  Web3Client get provider => providers.first;

  @override
  List<Object> get props => [chainId];
}