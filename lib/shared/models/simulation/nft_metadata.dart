import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:safe_verify/shared/models/network_model.dart';
import 'package:safe_verify/shared/utils/abi_utils.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class NFTMetadata {
  String collectionName;
  String symbol;
  String? tokenURI;
  String? name;
  String? description;
  String? imageURI;
  static final Map<String, (String, String, String?)> _metadataCache = {};
  static final Map<String, Map<String, dynamic>> _tokenMetadataCache = {};

  NFTMetadata({
    required this.collectionName,
    required this.symbol,
    this.tokenURI,
    this.name,
    this.description,
    this.imageURI,
  });

  static Future<NFTMetadata> fromAddress(EthereumAddress address, BigInt tokenId, Network network) async {
    String collectionName = "";
    String symbol = "";
    String? tokenUri;
    //
    var cacheIdentifier = "${address.with0x};$tokenId;${network.chainId}";
    if (_metadataCache.containsKey(cacheIdentifier)){
      var metadata = _metadataCache[cacheIdentifier]!;
      collectionName = metadata.$1;
      symbol = metadata.$2;
      tokenUri = metadata.$3;
    }else{
      try {
        // Encode tokenId parameter for tokenURI(uint256)
        var tokenIdEncoded = bytesToHex(encodeAbi(["uint256"], [tokenId]), include0x: false);
        var results = await Future.wait([
          network.provider.callRaw(contract: address, data: hexToBytes("0x06fdde03")),
          network.provider.callRaw(contract: address, data: hexToBytes("0x95d89b41")),
          network.provider.callRaw(contract: address, data: hexToBytes("0xc87b56dd$tokenIdEncoded")).catchError((_) => bytesToHex(encodeAbi(["string"], ["Unknown"]))),
        ]);
        var nameHex = results[0];
        var symbolHex = results[1];
        var tokenUriHex = results[2];
        collectionName = decodeAbi(["string"], hexToBytes(nameHex))[0];
        symbol = decodeAbi(["string"], hexToBytes(symbolHex))[0];
        try {
          tokenUri = decodeAbi(["string"], hexToBytes(tokenUriHex))[0];
        } catch (e) {
          // tokenURI might not be supported or token might not exist
          tokenUri = null;
        }
        _metadataCache[cacheIdentifier] = (collectionName, symbol, tokenUri);
      } catch (e) {
        collectionName = "Unknown";
        symbol = "???";
        tokenUri = null;
      }
    }

    return NFTMetadata(
      collectionName: collectionName,
      symbol: symbol,
      tokenURI: tokenUri,
    );
  }

  /// Fetches the full metadata from tokenURI following EIP-721/EIP-1155 standards
  /// Returns a map containing name, description, image, and other attributes
  /// Handles both IPFS and HTTP/HTTPS URIs with graceful fallback on errors
  Future<Map<String, dynamic>?> fetchTokenMetadata() async {
    if (tokenURI == null || tokenURI!.isEmpty) {
      return null;
    }

    try {
      Map<String, dynamic> metadata;

      // Check cache first
      if (_tokenMetadataCache.containsKey(tokenURI)) {
        metadata = _tokenMetadataCache[tokenURI]!;
      }else{
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
          },
        ));
        final normalizedUri = _normalizeURI(tokenURI!);
        final response = await dio.get(normalizedUri);
        if ((response.statusCode ?? 500) > 399) {
          return null;
        }
        if (response.data is String) {
          metadata = jsonDecode(response.data);
        } else if (response.data is Map) {
          metadata = Map<String, dynamic>.from(response.data);
        } else {
          return null;
        }
        // Cache the result
        _tokenMetadataCache[tokenURI!] = metadata;
      }

      // Normalize image URI if present
      if (metadata.containsKey('image')) {
        metadata['image'] = _normalizeURI(metadata['image']);
      }

      // Update instance fields
      if (metadata.containsKey('name')) {
        name = metadata['name'];
      }
      if (metadata.containsKey('description')) {
        description = metadata['description'];
      }
      if (metadata.containsKey('image')) {
        imageURI = metadata['image'];
      }

      return metadata;
    } catch (e) {
      // Gracefully handle failures - metadata fetch is optional
      print('Failed to fetch NFT metadata from $tokenURI: $e');
    }

    return null;
  }

  /// Normalizes URIs by converting IPFS schemes to HTTP gateway URLs
  static String _normalizeURI(String uri) {
    if (uri.startsWith('ipfs://')) {
      // Convert ipfs:// to https gateway
      final ipfsHash = uri.substring(7); // Remove 'ipfs://'
      return 'https://ipfs.io/ipfs/$ipfsHash';
    } else if (uri.startsWith('ipfs/')) {
      // Handle ipfs/ without protocol
      final ipfsHash = uri.substring(5); // Remove 'ipfs/'
      return 'https://ipfs.io/ipfs/$ipfsHash';
    } else if (uri.startsWith('Qm') || uri.startsWith('bafybei')) {
      // Raw IPFS hash (CIDv0 starts with Qm, CIDv1 starts with bafy)
      return 'https://ipfs.io/ipfs/$uri';
    }

    // Return as-is for http/https URLs
    return uri;
  }
}