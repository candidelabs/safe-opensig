import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:safe_opensig/shared/models/network_model.dart';

class NetworkLogo extends StatelessWidget {
  final Network network;
  final double size;

  const NetworkLogo({
    super.key,
    required this.network,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath = 'assets/networks/${network.chainId}';
    
    // Networks that have local assets
    final List<String> networksWithAssets = [
      "1.svg",
      "10.svg",
      "56.svg",
      "100.svg",
      "137.svg",
      "480.svg",
      "8453.png",
      "42161.svg",
      "42220.svg",
    ];

    if (networksWithAssets.contains("${network.chainId}.png")) {
      return Image.asset(
        "$assetPath.png",
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to network logo URI if local asset fails
          return _buildNetworkLogoFromUri();
        },
      );
    } else if (networksWithAssets.contains("${network.chainId}.svg")) {
      return SvgPicture.asset(
        "$assetPath.svg",
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to network logo URI if local asset fails
          return _buildNetworkLogoFromUri();
        },
      );
    } else {
      // For networks without local assets, use the logo URI
      return _buildNetworkLogoFromUri();
    }
  }

  Widget _buildNetworkLogoFromUri() {
    if (network.logoUri == null || network.logoUri?.trim() == ""){
      return ClipRRect(
        borderRadius: BorderRadius.circular(50.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              network.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0),
      child: Image.network(
        network.logoUri ?? "",
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to a colored circle with the first letter of the network name
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                network.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}