# Analytics

Safe OpenSig optionally sends a small set of anonymous app-usage events so the project can see what's working, what breaks, and what chains people actually use. This page is the full source of truth for that telemetry.

- **Default:** off. Analytics are **opt-in**. Toggle in **Settings → Share anonymous usage**.
- **Vendor:** [Aptabase](https://aptabase.com) (open source, privacy-first, MIT-licensed). Self-hostable.
- **Code:** `lib/shared/services/analytics_service.dart` — one file, no hidden layers. Delete it (and the call sites that reference it) to rip out analytics entirely.

---

## What we do NOT collect

We will never send any of the following to the analytics backend:

- Wallet addresses
- Safe addresses
- Safe owner addresses
- Transaction hashes, domain hashes, message hashes
- Transaction calldata, token amounts, token addresses
- Decoded transfer recipients or any content from a simulated transaction
- RPC endpoint URLs, custom network configuration
- Account names you entered
- Nonces, block numbers, threshold values
- IP address geolocation beyond what the Aptabase server records by default

The `Analytics` service in this repo deliberately does not expose a generic `trackEvent(...)` method. Every event must go through a typed helper defined in `lib/shared/services/analytics_service.dart`. If you want to add an event, you add a helper, update the table below, and review the PR together.

---

## Default posture

| Scenario | Behaviour |
|---|---|
| Fresh install | Analytics disabled. A one-time banner on the Accounts screen offers to enable. Dismiss = stays disabled. |
| Upgrading user | Analytics disabled. One-time banner appears once, then never again. |
| Debug / profile build | Analytics disabled regardless of toggle. Events are printed via `debugPrint` for developer verification, nothing is sent. |
| `APTABASE_APP_KEY` empty in `.env` | Analytics hard-off at boot. The SDK is not initialised, the Settings toggle is hidden, and the first-run banner does not appear. No helper can send anything. |
| Toggle turned off mid-session | An `analytics_opted_out` event is sent first, then all subsequent events are suppressed immediately. |

To see what a build would send, run in debug mode and watch the console for `[Analytics]` lines.

---

## Event reference

All `chain_slug` values come from `Network.chainPrefix` and are public identifiers (e.g. `eth`, `base`, `arb1`, `gno`).

### `app_launched`

Fired once per cold start, after opt-in is confirmed. Tells us platform mix and rough active-install count.

| Property | Type | Values |
|---|---|---|
| `platform` | string | `android`, `ios`, `windows`, `macos`, `linux`, `web` |

### `onboarding_completed`

Fired when a user finishes the onboarding flow (either by pressing the check mark on screen 4 or by pressing Skip from any earlier screen).

No properties.

### `account_added`

Fired after a new Safe account is saved. Not fired for edits.

| Property | Type | Example |
|---|---|---|
| `chain_slug` | string | `eth` |
| `account_count_after` | int | `3` |

### `account_removed`

Fired after a Safe account is deleted (via swipe or long-press menu, including the confirmation dialog).

| Property | Type | Example |
|---|---|---|
| `chain_slug` | string | `eth` |
| `account_count_after` | int | `2` |

### `verification_started`

Fired when the user initiates a verification — either by hitting "Verify" in the manual-input tab, or by finishing a valid Safe-API lookup.

| Property | Type | Values |
|---|---|---|
| `chain_slug` | string | `eth` |
| `input_method` | string | `safe_api`, `json`, `calldata` |

### `simulation_completed`

Fired exactly once per call to `SafeTransactionModel.simulate()`, regardless of outcome. The `outcome` field categorises what happened without leaking the underlying error text.

| Property | Type | Values |
|---|---|---|
| `chain_slug` | string | `eth` |
| `outcome` | string | `success`, `nonce_fetch_failed`, `hash_calculation_failed`, `state_verification_failed`, `trace_decode_error`, `rpc_failure` |
| `duration_ms` | int | wall-clock ms, measured from the top of `simulate()` |

### `hardware_preview_viewed`

Fired the first time, per verification session, that the user advances past the hardware-wallet selection screen and sees the emulated Ledger preview. Does not re-fire on back/forward navigation.

| Property | Type | Values |
|---|---|---|
| `chain_slug` | string | `eth` |
| `device` | string | `ledger_nano_s_plus` |

### `analytics_opted_in` / `analytics_opted_out`

Fired when the user flips the toggle in Settings or acts on the one-time banner. Sanity-check that consent plumbing is working.

No properties.

---

## Self-hosting

You can self-host the Aptabase backend — source at [aptabase/aptabase](https://github.com/aptabase/aptabase). A self-hosted instance is what crypto-native users are likely to trust most.

1. Deploy Aptabase per the upstream instructions. Recommended: **disable IP address retention** in the server configuration.
2. Create a self-hosted app and copy the key (it will have the format `A-SH-xxxxxxx`).
3. In the app's `.env`:
   ```
   APTABASE_APP_KEY=A-SH-xxxxxxxxxx
   APTABASE_HOST=https://analytics.yourdomain.com
   ```
4. Rebuild the app.

If `APTABASE_HOST` is blank with an `A-SH-...` key, the SDK logs an error and analytics stays disabled — no fallback to any public host.

## Building without analytics

Leave `APTABASE_APP_KEY` blank in `.env`. `Analytics.init()` returns early, no SDK network activity occurs, every typed helper is a no-op. No code changes required.

---

## Anonymity details

Per-install identity in Aptabase is a random UUID generated client-side by the SDK on first launch and stored in local app storage. It is never tied to a wallet address or email. Deleting the app wipes it. The `sessionId` attached to every event is a short-lived string that rotates after an hour of inactivity.

The Aptabase SDK also attaches a small `systemProps` object to every event containing `osName`, `osVersion`, `locale`, `appVersion`, `appBuildNumber`, and a `sdkVersion` tag. None of these identify the user. Full details: the SDK source is in `https://github.com/aptabase/aptabase_flutter`.
