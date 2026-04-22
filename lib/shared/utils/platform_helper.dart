/// Cross-platform helper for reading the current platform.
///
/// Conditionally re-exports the web stub (returns `'web'`) or the native
/// `dart:io`-backed implementation based on whether `dart:io` is available
/// at compile time. This keeps `dart:io` out of the web build graph.
///
/// Exposes `String getPlatformString()` — one of: `android`, `ios`,
/// `windows`, `macos`, `linux`, `web`, or `unknown`.
library;

export 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart';
