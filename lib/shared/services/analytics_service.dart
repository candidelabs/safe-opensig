import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_opensig/core/storage/misc_box.dart';
import 'package:safe_opensig/shared/constants/analytics_events.dart';
import 'package:safe_opensig/shared/utils/platform_helper.dart';

/// Single entry point for analytics in Safe OpenSig.
///
/// Design constraints — treat these as invariants, not guidelines:
///   1. No generic public `trackEvent`. Every event goes through a typed
///      helper defined in this file. Adding a new event forces a PR and
///      documentation update in `docs/analytics.md`.
///   2. Hard-off when `APTABASE_APP_KEY` is empty. A fork shipping without a
///      key produces zero network activity.
///   3. Hard-off in `kDebugMode` / `kProfileMode`. Dev activity never reaches
///      a production backend. Events are printed via `debugPrint` instead.
///   4. Opt-in, default false. The in-memory `_enabled` flag is seeded from
///      [MiscBox.isAnalyticsOptedIn] and mutated by [setEnabled].
///   5. Never include wallet addresses, transaction hashes, calldata,
///      amounts, RPC URLs, or account names in any event. The typed helpers
///      below accept only already-safe values (public chain slugs, enum
///      strings, integer counts/durations).
class Analytics {
  Analytics._();

  static bool _initialized = false;
  static bool _enabled = false;

  /// Test-only hook. When set, [_track] invokes this sink instead of the real
  /// Aptabase SDK. Short-circuits the debug-mode suppression.
  @visibleForTesting
  static void Function(String name, Map<String, dynamic>? props)? testSink;

  static bool get isEnabled => _enabled;

  /// True when `APTABASE_APP_KEY` is present in the environment. UI should
  /// hide analytics controls when this is false — there's no backend to
  /// opt into, so the toggle would only persist a flag that can never take
  /// effect. Re-reads dotenv on every call; cheap.
  static bool get isConfigured {
    final key = dotenv.env['APTABASE_APP_KEY'];
    return key != null && key.isNotEmpty;
  }

  @visibleForTesting
  static bool get isInitialized => _initialized;

  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _enabled = false;
    testSink = null;
  }

  /// Initialize the service. Idempotent — safe to call more than once, but
  /// only the first call has effect. Never throws; all errors are swallowed
  /// and result in analytics being disabled for this app session.
  static Future<void> init() async {
    if (_initialized) return;
    final key = dotenv.env['APTABASE_APP_KEY'];
    if (key == null || key.isEmpty) return;

    _enabled = MiscBox.isAnalyticsOptedIn();

    if (kDebugMode || kProfileMode) {
      _initialized = true;
      if (_enabled) trackAppLaunched();
      return;
    }

    final host = dotenv.env['APTABASE_HOST'];
    try {
      await Aptabase.init(
        key,
        InitOptions(host: (host != null && host.isNotEmpty) ? host : null),
      );
    } catch (_) {
      // Invalid app key format or init failure — leave analytics disabled.
      return;
    }

    _initialized = true;
    if (_enabled) trackAppLaunched();
  }

  /// Flip the opt-in flag at runtime. Persistence is the caller's
  /// responsibility — call [MiscBox.setAnalyticsOptedIn] separately.
  static void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    if (enabled) {
      _enabled = true;
      _track(AnalyticsEvents.optedIn);
    } else {
      // Fire BEFORE flipping off so the event actually sends.
      _track(AnalyticsEvents.optedOut);
      _enabled = false;
    }
  }

  // ---- Typed trackers — the ONLY public event surface ----

  static void trackAppLaunched() => _track(AnalyticsEvents.appLaunched, {
    AnalyticsProps.platform: getPlatformString(),
  });

  static void trackOnboardingCompleted() =>
      _track(AnalyticsEvents.onboardingCompleted);

  static void trackAccountAdded(String chainSlug, int accountCountAfter) =>
      _track(AnalyticsEvents.accountAdded, {
        AnalyticsProps.chainSlug: chainSlug,
        AnalyticsProps.accountCountAfter: accountCountAfter,
      });

  static void trackAccountRemoved(String chainSlug, int accountCountAfter) =>
      _track(AnalyticsEvents.accountRemoved, {
        AnalyticsProps.chainSlug: chainSlug,
        AnalyticsProps.accountCountAfter: accountCountAfter,
      });

  static void trackVerificationStarted(String chainSlug, String inputMethod) =>
      _track(AnalyticsEvents.verificationStarted, {
        AnalyticsProps.chainSlug: chainSlug,
        AnalyticsProps.inputMethod: inputMethod,
      });

  static void trackSimulationCompleted(
    String chainSlug,
    String outcome,
    int durationMs,
  ) => _track(AnalyticsEvents.simulationCompleted, {
    AnalyticsProps.chainSlug: chainSlug,
    AnalyticsProps.outcome: outcome,
    AnalyticsProps.durationMs: durationMs,
  });

  static void trackHardwarePreviewViewed(String chainSlug, String device) =>
      _track(AnalyticsEvents.hardwarePreviewViewed, {
        AnalyticsProps.chainSlug: chainSlug,
        AnalyticsProps.device: device,
      });

  // ---- Internals ----

  static void _track(String name, [Map<String, dynamic>? props]) {
    if (testSink != null) {
      if (!_enabled) return;
      testSink!(name, props);
      return;
    }
    if (!_initialized || !_enabled) return;
    if (kDebugMode || kProfileMode) {
      debugPrint('[Analytics] $name ${props ?? const <String, dynamic>{}}');
      return;
    }
    Aptabase.instance.trackEvent(name, props);
  }
}
