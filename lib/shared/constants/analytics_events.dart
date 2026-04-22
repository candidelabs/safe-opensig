/// Canonical analytics event names.
///
/// Every event sent through [Analytics] MUST reference a constant here — the
/// service has no public generic `trackEvent`. To add a new event: add a
/// constant here, add a typed helper in [Analytics], and document the event
/// in `docs/analytics.md`.
class AnalyticsEvents {
  AnalyticsEvents._();

  static const String appLaunched = 'app_launched';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String accountAdded = 'account_added';
  static const String accountRemoved = 'account_removed';
  static const String verificationStarted = 'verification_started';
  static const String simulationCompleted = 'simulation_completed';
  static const String hardwarePreviewViewed = 'hardware_preview_viewed';
  static const String optedIn = 'analytics_opted_in';
  static const String optedOut = 'analytics_opted_out';
}

/// Canonical property keys attached to analytics events.
class AnalyticsProps {
  AnalyticsProps._();

  static const String platform = 'platform';
  static const String chainSlug = 'chain_slug';
  static const String accountCountAfter = 'account_count_after';
  static const String inputMethod = 'input_method';
  static const String outcome = 'outcome';
  static const String durationMs = 'duration_ms';
  static const String device = 'device';
}

/// Allowed `input_method` values for [AnalyticsEvents.verificationStarted].
class AnalyticsInputMethods {
  AnalyticsInputMethods._();

  static const String safeApi = 'safe_api';
  static const String json = 'json';
  static const String calldata = 'calldata';
}

/// Allowed `outcome` values for [AnalyticsEvents.simulationCompleted].
class AnalyticsSimulationOutcomes {
  AnalyticsSimulationOutcomes._();

  static const String success = 'success';
  static const String nonceFetchFailed = 'nonce_fetch_failed';
  static const String hashCalculationFailed = 'hash_calculation_failed';
  static const String stateVerificationFailed = 'state_verification_failed';
  static const String traceDecodeError = 'trace_decode_error';
  static const String rpcFailure = 'rpc_failure';
}

/// Allowed `device` values for [AnalyticsEvents.hardwarePreviewViewed].
class AnalyticsDevices {
  AnalyticsDevices._();

  static const String ledgerNanoSPlus = 'ledger_nano_s_plus';
}
