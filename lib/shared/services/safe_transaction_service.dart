import 'package:dio/dio.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/models/safe_api_transaction_model.dart';

/// Service for interacting with the Safe Transaction Service API
/// The Safe Transaction Service provides APIs for fetching queued transactions,
/// transaction history, and other Safe-related data.
class SafeTransactionService {
  final Dio _dio;
  // You can find supported networks here: https://docs.safe.global/advanced/smart-account-supported-networks?service=Transaction+Service
  // CHORE: whenever you add a new network to the app, you need to add it here if it's supported. // todo automatically detect if network is not supported or is currently down
  static const Set<int> supportedChainIds = {
    1,
    137,
    100,
    56,
    43114,
    10,
    8453,
    480,
    130,
    42161,
    42220,
  };

  SafeTransactionService({Dio? dio})
    : _dio = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
        },
      ));

  /// Get the Safe Transaction Service base URL for a given chain ID
  String _getBaseUrl(Network network) {
    return 'https://api.safe.global/tx-service/${network.chainPrefix}/api/v1';
  }

  /// Fetch queued multisig transactions for a Safe account
  Future<(bool, List<SafeAPITransaction>?, String)> getQueuedTransactions({
    required String safeAddress,
    required int chainId,
    int? minNonce,
  }) async {
    var network = availableNetworks[chainId];
    if (network == null || !supportedChainIds.contains(chainId)) {
      return (
        false,
        null,
        'Chain ID $chainId is not supported by Safe Transaction Service. Please use JSON or CallData input.'
      );
    }
    try {
      final baseUrl = _getBaseUrl(network);
      final endpoint = '$baseUrl/safes/$safeAddress/multisig-transactions/';

      // Fetch only non-executed (queued) transactions
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'executed': 'false',
          'nonce__gte': minNonce,
          'ordering': '-nonce', // Sort by nonce descending (newest first)
        },
      );
      if (response.data == null) {
        return (false, null, 'Empty response from Safe API');
      }
      if (response.data is! Map<String, dynamic>) {
        return (false, null, 'Invalid response format from Safe API');
      }
      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('results')) {
        return (false, null, 'Missing results field in API response');
      }
      final results = data['results'];
      if (results is! List) {
        return (false, null, 'Invalid results format in API response');
      }
      final transactions = <SafeAPITransaction>[];
      for (final item in results) {
        try {
          if (item is Map<String, dynamic>) {
            final transaction = SafeAPITransaction.fromJson(item);
            transactions.add(transaction);
          }
        } catch (e) {
          // Log individual parsing errors but continue processing other transactions
          print('Warning: Failed to parse transaction: $e');
        }
      }

      return (true, transactions, '');

    } on DioException catch (e) {
      // Handle specific Dio errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return (false, null, 'Request timed out. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        return (false, null, 'No internet connection. Please check your network.');
      }
      if (e.response?.statusCode == 404) {
        // Safe not found or no transactions - return empty list
        return (true, <SafeAPITransaction>[], '');
      }
      if (e.response?.statusCode == 422) {
        return (false, null, 'Invalid Safe address or chain ID');
      }
      return (
        false,
        null,
        'Safe API error: ${e.message ?? "Unknown error"}'
      );
    } catch (e) {
      // Catch any other unexpected errors
      return (
        false,
        null,
        'Unexpected error: ${e.toString()}'
      );
    }
  }
}
