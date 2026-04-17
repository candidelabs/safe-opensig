import 'package:flutter_test/flutter_test.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';

// ignore: must_be_immutable
class _FakeSafeAccount extends SafeAccount {
  final BigInt? Function() _getNonce;

  _FakeSafeAccount({required BigInt? Function() getNonce})
      : _getNonce = getNonce,
        super(
          id: 'test',
          name: 'Test',
          address: '0x0000000000000000000000000000000000000001',
          chainId: 1,
          version: '1.4.1',
        );

  @override
  Future<BigInt?> getNonce() async => _getNonce();
}

SafeTransaction _tx({BigInt? nonce}) => SafeTransaction(
      to: '0x0000000000000000000000000000000000000002',
      value: BigInt.zero,
      data: '0x',
      operation: 0,
      safeTxGas: BigInt.zero,
      baseGas: BigInt.zero,
      gasPrice: BigInt.zero,
      gasToken: '0x0000000000000000000000000000000000000000',
      refundReceiver: '0x0000000000000000000000000000000000000000',
      nonce: nonce,
    );

void main() {
  group('SafeTransaction.ensureNonce', () {
    test('nonce set, fetch succeeds: latestNonce populated, success', () async {
      final tx = _tx(nonce: BigInt.from(7));
      final account = _FakeSafeAccount(getNonce: () => BigInt.from(10));

      final (ok, err) = await tx.ensureNonce(account);

      expect(ok, isTrue);
      expect(err, isEmpty);
      expect(tx.nonce, BigInt.from(7));
      expect(tx.latestNonce, BigInt.from(10));
      expect(tx.nonceIsEditable, isFalse);
    });

    test('nonce set, fetch fails: success with null latestNonce', () async {
      final tx = _tx(nonce: BigInt.from(7));
      final account = _FakeSafeAccount(getNonce: () => null);

      final (ok, err) = await tx.ensureNonce(account);

      expect(ok, isTrue);
      expect(err, isEmpty);
      expect(tx.nonce, BigInt.from(7));
      expect(tx.latestNonce, isNull);
      expect(tx.nonceIsEditable, isFalse);
    });

    test('nonce null, fetch succeeds: both adopted, editable', () async {
      final tx = _tx(nonce: null);
      final account = _FakeSafeAccount(getNonce: () => BigInt.from(10));

      final (ok, err) = await tx.ensureNonce(account);

      expect(ok, isTrue);
      expect(err, isEmpty);
      expect(tx.nonce, BigInt.from(10));
      expect(tx.latestNonce, BigInt.from(10));
      expect(tx.nonceIsEditable, isTrue);
    });

    test('nonce null, fetch fails: success, nonce stays null, editable', () async {
      final tx = _tx(nonce: null);
      final account = _FakeSafeAccount(getNonce: () => null);

      final (ok, err) = await tx.ensureNonce(account);

      expect(ok, isTrue);
      expect(err, isEmpty);
      expect(tx.nonce, isNull);
      expect(tx.latestNonce, isNull);
      expect(tx.nonceIsEditable, isTrue);
    });
  });

  group('SafeTransaction.getMessageHash', () {
    test('returns error when useLatestNonce true and latestNonce null',
        () async {
      final tx = _tx(nonce: BigInt.from(7));
      final account = _FakeSafeAccount(getNonce: () => null);

      final (ok, msg) = await tx.getMessageHash(account, useLatestNonce: true);

      expect(ok, isFalse);
      expect(msg.toLowerCase(), contains('nonce'));
    });

    test('returns error when nonce null', () async {
      final tx = _tx(nonce: null);
      final account = _FakeSafeAccount(getNonce: () => null);

      final (ok, msg) = await tx.getMessageHash(account);

      expect(ok, isFalse);
      expect(msg.toLowerCase(), contains('nonce'));
    });
  });
}
