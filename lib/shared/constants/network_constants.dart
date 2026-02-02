import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

import '../models/network_model.dart';

var availableNetworks = {
  // L1s
  1: Network(
    name: 'Ethereum',
    chainPrefix: 'eth',
    chainId: 1,
    nativeCurrencySymbol: "ETH",
    providers: [
      Web3Client(dotenv.env['NODE_URL_ETHEREUM']!, Client()),
      Web3Client("https://ethereum-rpc.publicnode.com", Client()),
      Web3Client("https://eth.drpc.org", Client()),
    ],
    explorers: [
      ("Etherscan", "https://etherscan.io")
    ],
    logoUri: null,
  ),
  137: Network(
    name: 'Polygon',
    chainPrefix: 'pol',
    chainId: 137,
    nativeCurrencySymbol: "POL",
    providers: [
      Web3Client(dotenv.env['NODE_URL_POLYGON']!, Client()),
      Web3Client("https://polygon-bor-rpc.publicnode.com", Client()),
      Web3Client("https://polygon.drpc.org", Client()),
    ],
    explorers: [
      ("Polygon Scan", "https://polygonscan.com")
    ],
    logoUri: null,
  ),
  100: Network(
    name: 'Gnosis',
    chainPrefix: 'gno',
    chainId: 100,
    nativeCurrencySymbol: "xDAI",
    providers: [
      Web3Client(dotenv.env['NODE_URL_GNOSIS']!, Client()),
      Web3Client("https://gnosis-rpc.publicnode.com", Client()),
      Web3Client("https://gnosis.drpc.org", Client()),
    ],
    explorers: [
      ("Gnosis Scan", "https://gnosisscan.io")
    ],
    logoUri: null,
  ),
  56: Network(
    name: 'BSC',
    chainPrefix: 'bnb',
    chainId: 56,
    nativeCurrencySymbol: "BNB",
    providers: [
      Web3Client(dotenv.env['NODE_URL_BSC']!, Client()),
      Web3Client("https://bsc-rpc.publicnode.com", Client()),
      Web3Client("https://bsc.drpc.org", Client()),
    ],
    explorers: [
      ("BSC Scan", "https://bscscan.com")
    ],
    logoUri: null,
  ),
  43114: Network(
    name: 'Avalanche',
    chainPrefix: 'avax',
    chainId: 43114,
    nativeCurrencySymbol: "AVAX",
    providers: [
      Web3Client(dotenv.env['NODE_URL_AVAX']!, Client()),
      Web3Client("https://avalanche-c-chain-rpc.publicnode.com", Client()),
      Web3Client("https://avalanche.drpc.org", Client()),
    ],
    explorers: [
      ("Snowtrace", "https://snowtrace.io")
    ],
    logoUri: null,
  ),
  // L2s
  10: Network(
    name: 'Optimism',
    chainPrefix: 'oeth',
    chainId: 10,
    nativeCurrencySymbol: "ETH",
    providers: [
      Web3Client(dotenv.env['NODE_URL_OPTIMISM']!, Client()),
      Web3Client("https://optimism-rpc.publicnode.com", Client()),
      Web3Client("https://optimism.drpc.org", Client()),
    ],
    explorers: [
      ("OP Etherscan", "https://optimistic.etherscan.io")
    ],
    logoUri: null,
  ),
  8453: Network(
    name: 'Base',
    chainPrefix: 'base',
    chainId: 8453,
    nativeCurrencySymbol: "ETH",
    providers: [
      Web3Client(dotenv.env['NODE_URL_BASE']!, Client()),
      Web3Client("https://base-rpc.publicnode.com", Client()),
      Web3Client("https://base.drpc.org", Client()),
    ],
    explorers: [
      ("Base Scan", "https://basescan.org")
    ],
    logoUri: null,
  ),
  480: Network(
    name: 'Worldchain',
    chainPrefix: 'wc',
    chainId: 480,
    nativeCurrencySymbol: "ETH",
    providers: [
      Web3Client(dotenv.env['NODE_URL_WORLDCHAIN']!, Client()),
      Web3Client("https://worldchain-mainnet.g.alchemy.com/public", Client()),
      Web3Client("https://worldchain.drpc.org", Client()),
    ],
    explorers: [
      ("World Scan", "https://worldscan.org")
    ],
    logoUri: null,
  ),
  130: Network(
    name: 'Unichain',
    chainPrefix: 'unichain',
    chainId: 130,
    nativeCurrencySymbol: "ETH",
    providers: [
      Web3Client(dotenv.env['NODE_URL_UNICHAIN']!, Client()),
      Web3Client("https://unichain-rpc.publicnode.com", Client()),
      Web3Client("https://unichain.drpc.org", Client()),
    ],
    explorers: [
      ("Uni Scan", "https://uniscan.xyz")
    ],
    logoUri: null,
  ),
  42161: Network(
    name: 'Arbitrum',
    chainPrefix: 'arb1',
    chainId: 42161,
    nativeCurrencySymbol: "ETH",
    providers: [
      Web3Client(dotenv.env['NODE_URL_ARBITRUM']!, Client()),
      Web3Client("https://arbitrum-one-rpc.publicnode.com", Client()),
      Web3Client("https://arbitrum.drpc.org", Client()),
    ],
    explorers: [
      ("Arbitrum Scan", "https://arbiscan.io")
    ],
    logoUri: null,
  ),
  42220: Network(
    name: 'Celo',
    chainPrefix: 'celo',
    chainId: 42220,
    nativeCurrencySymbol: "CELO",
    providers: [
      Web3Client(dotenv.env['NODE_URL_CELO']!, Client()),
      Web3Client("https://celo-rpc.publicnode.com", Client()),
      Web3Client("https://celo.drpc.org", Client()),
    ],
    explorers: [
      ("Celo Scan", "https://celoscan.io")
    ],
    logoUri: null,
  ),
};
