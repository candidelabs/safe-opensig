import 'dart:io';

/// Native (Android / iOS / Windows / macOS / Linux) implementation of
/// the platform helper. Selected by the conditional export in
/// `platform_helper.dart` whenever `dart:io` is available.
String getPlatformString() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

bool get isWindows => Platform.isWindows;

bool get isMobile => Platform.isAndroid || Platform.isIOS;
