import 'package:safe_opensig/shared/utils/utilities.dart';

extension StringExtensions on String {
  bool get isNumericOnly => Utilities.hasMatch(this, r'^\d+$');

  String? validateHttpsUrl({bool required = true}) {
    if (trim().isEmpty) {
      return required ? 'URL is required' : null;
    }

    final trimmed = trim();

    if (!trimmed.startsWith('https://')) {
      return 'URL must start with https://';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'Invalid URL';
    }

    return null;
  }
}