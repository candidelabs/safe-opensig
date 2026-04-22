import 'package:flutter_test/flutter_test.dart';
import 'package:safe_opensig/shared/constants/analytics_events.dart';
import 'package:safe_opensig/shared/services/analytics_service.dart';

class _Capture {
  _Capture(this.name, this.props);
  final String name;
  final Map<String, dynamic>? props;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<_Capture> captured = [];

  void installSink() {
    captured = [];
    Analytics.testSink = (name, props) {
      captured.add(_Capture(name, props));
    };
  }

  setUp(() {
    Analytics.resetForTesting();
  });

  tearDown(() {
    Analytics.resetForTesting();
  });

  group('no-op when not opted-in', () {
    test('all typed helpers drop events', () {
      installSink();
      // Intentionally do NOT call setEnabled(true).
      Analytics.trackAppLaunched();
      Analytics.trackOnboardingCompleted();
      Analytics.trackAccountAdded('eth', 1);
      Analytics.trackAccountRemoved('eth', 0);
      Analytics.trackVerificationStarted('eth', AnalyticsInputMethods.json);
      Analytics.trackSimulationCompleted(
        'eth',
        AnalyticsSimulationOutcomes.success,
        42,
      );
      Analytics.trackHardwarePreviewViewed(
        'eth',
        AnalyticsDevices.ledgerNanoSPlus,
      );

      expect(captured, isEmpty);
    });
  });

  group('typed trackers emit correct shape when enabled', () {
    setUp(() {
      installSink();
      Analytics.setEnabled(true);
      captured.clear(); // drop the opted_in event
    });

    test('trackAppLaunched sends platform', () {
      Analytics.trackAppLaunched();
      expect(captured, hasLength(1));
      expect(captured.single.name, AnalyticsEvents.appLaunched);
      expect(captured.single.props, isNotNull);
      expect(captured.single.props!.keys, contains(AnalyticsProps.platform));
    });

    test('trackOnboardingCompleted carries no props', () {
      Analytics.trackOnboardingCompleted();
      expect(captured.single.name, AnalyticsEvents.onboardingCompleted);
      expect(captured.single.props, isNull);
    });

    test('trackAccountAdded carries chain_slug + account_count_after', () {
      Analytics.trackAccountAdded('base', 2);
      final c = captured.single;
      expect(c.name, AnalyticsEvents.accountAdded);
      expect(c.props, {
        AnalyticsProps.chainSlug: 'base',
        AnalyticsProps.accountCountAfter: 2,
      });
    });

    test('trackAccountRemoved carries chain_slug + account_count_after', () {
      Analytics.trackAccountRemoved('base', 7);
      expect(captured.single.name, AnalyticsEvents.accountRemoved);
      expect(captured.single.props, {
        AnalyticsProps.chainSlug: 'base',
        AnalyticsProps.accountCountAfter: 7,
      });
    });

    test('trackVerificationStarted carries chain_slug + input_method', () {
      Analytics.trackVerificationStarted('arb1', AnalyticsInputMethods.safeApi);
      final c = captured.single;
      expect(c.name, AnalyticsEvents.verificationStarted);
      expect(c.props, {
        AnalyticsProps.chainSlug: 'arb1',
        AnalyticsProps.inputMethod: AnalyticsInputMethods.safeApi,
      });
    });

    test(
      'trackSimulationCompleted carries chain_slug + outcome + duration_ms',
      () {
        Analytics.trackSimulationCompleted(
          'gno',
          AnalyticsSimulationOutcomes.rpcFailure,
          1234,
        );
        final c = captured.single;
        expect(c.name, AnalyticsEvents.simulationCompleted);
        expect(c.props, {
          AnalyticsProps.chainSlug: 'gno',
          AnalyticsProps.outcome: AnalyticsSimulationOutcomes.rpcFailure,
          AnalyticsProps.durationMs: 1234,
        });
      },
    );

    test('trackHardwarePreviewViewed carries chain_slug + device', () {
      Analytics.trackHardwarePreviewViewed(
        'eth',
        AnalyticsDevices.ledgerNanoSPlus,
      );
      final c = captured.single;
      expect(c.name, AnalyticsEvents.hardwarePreviewViewed);
      expect(c.props, {
        AnalyticsProps.chainSlug: 'eth',
        AnalyticsProps.device: AnalyticsDevices.ledgerNanoSPlus,
      });
    });
  });

  group('setEnabled fires toggle events correctly', () {
    test('setEnabled(true) while disabled fires opted_in once', () {
      installSink();
      expect(Analytics.isEnabled, isFalse);

      Analytics.setEnabled(true);

      expect(Analytics.isEnabled, isTrue);
      expect(captured.map((c) => c.name), [AnalyticsEvents.optedIn]);
    });

    test(
      'setEnabled(false) while enabled fires opted_out BEFORE flipping off',
      () {
        installSink();
        Analytics.setEnabled(true);
        captured.clear();

        Analytics.setEnabled(false);

        // The opted_out event must be captured — proving the sink was still
        // "enabled" at the moment _track ran, which is the contract: the
        // user's consent event reaches the backend.
        expect(captured.map((c) => c.name), [AnalyticsEvents.optedOut]);
        expect(Analytics.isEnabled, isFalse);
      },
    );

    test('setEnabled with same value is a no-op', () {
      installSink();
      Analytics.setEnabled(false);
      expect(captured, isEmpty);

      Analytics.setEnabled(true);
      captured.clear();
      Analytics.setEnabled(true);
      expect(captured, isEmpty);
    });
  });

  group('test sink short-circuits debug-mode suppression', () {
    test('sink receives events in test environment (kDebugMode=true)', () {
      installSink();
      Analytics.setEnabled(true);
      captured.clear();

      Analytics.trackOnboardingCompleted();

      // Without the testSink override, debug mode would debugPrint only.
      // Verifying the sink fires proves the override is correctly bypassing
      // the debug-mode guard.
      expect(captured, hasLength(1));
      expect(captured.single.name, AnalyticsEvents.onboardingCompleted);
    });
  });

  group('event / property constants are kebab/snake case', () {
    test('every event name is snake_case lowercase', () {
      const events = [
        AnalyticsEvents.appLaunched,
        AnalyticsEvents.onboardingCompleted,
        AnalyticsEvents.accountAdded,
        AnalyticsEvents.accountRemoved,
        AnalyticsEvents.verificationStarted,
        AnalyticsEvents.simulationCompleted,
        AnalyticsEvents.hardwarePreviewViewed,
        AnalyticsEvents.optedIn,
        AnalyticsEvents.optedOut,
      ];
      for (final e in events) {
        expect(
          e,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
          reason: 'event "$e" must be snake_case',
        );
      }
    });

    test('every property key is snake_case lowercase', () {
      const props = [
        AnalyticsProps.platform,
        AnalyticsProps.chainSlug,
        AnalyticsProps.accountCountAfter,
        AnalyticsProps.inputMethod,
        AnalyticsProps.outcome,
        AnalyticsProps.durationMs,
        AnalyticsProps.device,
      ];
      for (final p in props) {
        expect(
          p,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
          reason: 'prop "$p" must be snake_case',
        );
      }
    });
  });
}
