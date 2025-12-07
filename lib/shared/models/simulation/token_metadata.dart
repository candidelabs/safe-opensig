import 'package:safe_verify/shared/models/network_model.dart';
import 'package:safe_verify/shared/models/simulation/tokens_directory.dart';
import 'package:safe_verify/shared/utils/abi_utils.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class TokenMetadata {
  String name;
  String symbol;
  int decimals;
  String logoUri;
  static final Map<String, (String, String, int, String)> _metadataCache = {};

  TokenMetadata({
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.logoUri
  });

  static Future<TokenMetadata> fromAddress(EthereumAddress address, Network network) async {
    String name = "";
    String symbol = "";
    int decimals = 0;
    //
    var cacheIdentifier = "${address.with0x};${network.chainId}";
    if (_metadataCache.containsKey(cacheIdentifier)){
      var metadata = _metadataCache[cacheIdentifier]!;
      name = metadata.$1;
      symbol = metadata.$2;
      decimals = metadata.$3;
    }else{
      if (address.with0x == "0x0000000000000000000000000000000000000000"){
        name = network.nativeCurrencySymbol;
        symbol = network.nativeCurrencySymbol;
        decimals = 18;
      }else{
        var results = await Future.wait([
          network.provider.callRaw(contract: address,data: hexToBytes("0x06fdde03")),
          network.provider.callRaw(contract: address, data: hexToBytes("0x95d89b41")),
          network.provider.callRaw(contract: address, data: hexToBytes("0x313ce567"))
        ]);
        var nameHex = results[0];
        var symbolHex = results[1];
        var decimalsHex = results[2];
        name = decodeAbi(["string"], hexToBytes(nameHex))[0];
        symbol = decodeAbi(["string"], hexToBytes(symbolHex))[0];
        decimals = BigInt.parse(decimalsHex.replaceFirst("0x", ""), radix: 16).toInt();
      }
    }
    String logoUri = TokensDirectory.getTokenLogo(address.with0x.toLowerCase(), network.chainId);
    return TokenMetadata(
      name: name,
      symbol: symbol,
      decimals: decimals,
      logoUri: logoUri
    );
  }
}