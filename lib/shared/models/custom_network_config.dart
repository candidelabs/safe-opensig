class CustomNetworkConfig {
  final int chainId;
  final String primaryNodeUrl;
  final List<String> secondaryNodeUrls;
  final String? explorerUrl;

  const CustomNetworkConfig({
    required this.chainId,
    required this.primaryNodeUrl,
    this.secondaryNodeUrls = const [],
    this.explorerUrl,
  });

  Map<String, dynamic> toJson() => {
    'chainId': chainId,
    'primaryNodeUrl': primaryNodeUrl,
    'secondaryNodeUrls': secondaryNodeUrls,
    if (explorerUrl != null) 'explorerUrl': explorerUrl,
  };

  factory CustomNetworkConfig.fromJson(Map<String, dynamic> json) {
    return CustomNetworkConfig(
      chainId: json['chainId'] as int,
      primaryNodeUrl: json['primaryNodeUrl'] as String,
      secondaryNodeUrls: (json['secondaryNodeUrls'] as List<dynamic>?)
          ?.cast<String>() ?? [],
      explorerUrl: json['explorerUrl'] as String?,
    );
  }
}
