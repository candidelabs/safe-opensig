class PopularSafe {
  final String displayName;
  final String description;
  final String address; // EIP-55 checksummed
  final int chainId;
  final String version; // verified against Safe Transaction Service API

  const PopularSafe({
    required this.displayName,
    required this.description,
    required this.address,
    required this.chainId,
    required this.version,
  });
}

/// Curated list of well-known protocol Safes for new-user exploration.
/// Each address verified via Safe Transaction Service API before release.
const List<PopularSafe> popularSafes = [
  PopularSafe(
    displayName: 'Yearn DAO',
    description: 'Yearn Finance treasury (ychad.eth)',
    address: '0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52',
    chainId: 1, // Ethereum
    version: '1.3.0',
  ),
  // Guaranteed fallback — always has queued transactions
  PopularSafe(
    displayName: 'Demo Safe',
    description: 'A Safe available for exploration',
    address: '0xDc6f8499d102100CaFA6a6cF2E7aF31fb5b14871',
    chainId: 10, // Optimism
    version: '1.4.1',
  ),
];
