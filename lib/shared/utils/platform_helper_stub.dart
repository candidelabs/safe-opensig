/// Web fallback for the platform helper. Selected by the conditional
/// export in `platform_helper.dart` when `dart:io` is unavailable.
String getPlatformString() => 'web';

bool get isWindows => false;

bool get isMobile => false;
