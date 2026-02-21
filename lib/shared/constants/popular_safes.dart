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
  PopularSafe(
    displayName: 'Vitalik Buterin',
    description: 'vitalik.eth personal Safe',
    address: '0x220866B1A2219f40e72f5c628B65D54268cA3A9D',
    chainId: 1, // Ethereum
    version: '1.1.1',
  ),
  PopularSafe(
    displayName: 'Optimism Foundation',
    description: 'Optimism ecosystem foundation multisig',
    address: '0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0',
    chainId: 10, // Optimism
    version: '1.3.0',
  ),
  PopularSafe(
    displayName: 'GnosisDAO',
    description: 'GnosisDAO governance treasury',
    address: '0x458cD345B4C05e8DF39d0A07220feb4Ec19F5e6f',
    chainId: 100, // Gnosis Chain
    version: '1.3.0',
  ),
];
