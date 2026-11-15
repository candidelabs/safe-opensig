import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/models/simulation/safe_setting_change.dart';
import 'package:safe_opensig/shared/models/simulation/trace_decoder.dart';

// Regression test for the "RangeError (length): Only valid value is 0: 1"
// simulation failure on swapOwner transactions.
//
// Safe owner/module/guard events changed their parameter indexing between
// versions: in Safe <=1.3.0 the address is a NON-indexed parameter (carried in
// `data`, so `topics` only holds the event signature), while in Safe >=1.4.0 it
// is indexed (carried in `topics[1]`). The decoder previously always read
// `topics[1]`, which overran the topics list for <=1.3.0 events and threw.
void main() {
  // Owner events build a SafeSettingChange that never references the network,
  // so a bare stub avoids loading RPC config from .env.
  const network = Network(
    name: 'Test',
    chainPrefix: 'eth',
    chainId: 1,
    nativeCurrencySymbol: 'ETH',
    providers: [],
    explorers: [],
  );
  const account = '0x1111111111111111111111111111111111111111';
  const owner = '0x00000000000000000000000000000000000000aa';
  const ownerWord =
      '0x00000000000000000000000000000000000000000000000000000000000000aa';
  const removedOwnerSig =
      '0xf8d49fc529812e9a7c5c50e69c20f0dccc0db8fa95c98bc58cc9a4f1c1299eaf';
  const addedOwnerSig =
      '0x9465fa0c962cc76958e6373a993326400c1c94f8be2fe3a952adfa7f60b2ea26';

  final decoder = TraceDecoder(accountSingleton: '0x0');
  final expectedOwner = EthereumAddress.fromHex(owner);

  group('TraceDecoder.processLog owner events', () {
    test('Safe <=1.3.0 non-indexed RemovedOwner decodes from data', () {
      final result = decoder.processLog(account, network, {
        'address': account,
        'topics': [removedOwnerSig], // only the signature, owner is non-indexed
        'data': ownerWord,
      }) as SafeSettingChange;

      expect(result.type, SafeSettingChangeType.OWNER_REVOCATION);
      expect(result.data.first, expectedOwner);
    });

    test('Safe >=1.4.0 indexed RemovedOwner decodes from topics[1]', () {
      final result = decoder.processLog(account, network, {
        'address': account,
        'topics': [removedOwnerSig, ownerWord], // owner indexed
        'data': '0x',
      }) as SafeSettingChange;

      expect(result.type, SafeSettingChangeType.OWNER_REVOCATION);
      expect(result.data.first, expectedOwner);
    });

    test('Safe <=1.3.0 non-indexed AddedOwner decodes from data', () {
      final result = decoder.processLog(account, network, {
        'address': account,
        'topics': [addedOwnerSig],
        'data': ownerWord,
      }) as SafeSettingChange;

      expect(result.type, SafeSettingChangeType.OWNER_ADDITION);
      expect(result.data.first, expectedOwner);
    });
  });
}
