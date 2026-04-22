import 'package:flutter/material.dart';

/// The app's standard toggle switch.
///
/// Renders the pre-Material-3 `Switch` look: a circular thumb that is
/// noticeably larger than a thin pill track, so the thumb extends above
/// and below the track. Obtained by wrapping a stock [Switch] in a local
/// [Theme] with `useMaterial3: false`.
///
/// Defaults `activeColor` to the ambient `ColorScheme.primary` and sets
/// [MaterialTapTargetSize.shrinkWrap] to avoid the extra tap-target
/// padding the default Switch applies inside dense rows.
class M2Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Thumb color when [value] is true. Defaults to the ambient primary.
  final Color? activeColor;

  const M2Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: ThemeData.from(
        colorScheme: theme.colorScheme,
        useMaterial3: false,
      ),
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? theme.colorScheme.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
