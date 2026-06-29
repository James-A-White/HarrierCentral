import 'package:hcportal/imports.dart';

/// Button role in the portal button system. See docs/portal_button_strategy.md.
enum HcButtonVariant {
  /// Main action (Save, Submit, Confirm). Filled brand red.
  primary,

  /// Alternative / Cancel / Back. Filled neutral (blueGrey).
  secondary,

  /// Irreversible action (Delete, Clear, Regenerate). Filled deep red.
  destructive,

  /// In-page low-emphasis alternative. Outlined.
  outlined,

  /// Lowest emphasis, link-style. Flat, no background.
  text,
}

/// The standard portal button. Prefer this over raw ElevatedButton/TextButton
/// so size, shape, typography, disabled and loading states stay consistent.
///
/// Disabled when [onPressed] is null OR [loading] is true. Set [icon] for a
/// leading icon, [expand] to fill the available width.
class HcButton extends StatelessWidget {
  const HcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HcButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  const HcButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = HcButtonVariant.primary;

  const HcButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = HcButtonVariant.secondary;

  const HcButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = HcButtonVariant.destructive;

  const HcButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = HcButtonVariant.outlined;

  const HcButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = HcButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final HcButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  bool get _isFilled =>
      variant == HcButtonVariant.primary ||
      variant == HcButtonVariant.secondary ||
      variant == HcButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final onTap = (loading || onPressed == null) ? null : onPressed;
    final spinnerColor =
        _isFilled ? HcButtonTokens.onFilled : HcButtonTokens.secondary;

    final Widget child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: spinnerColor),
          )
        : (icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ));

    final Widget button = switch (variant) {
      HcButtonVariant.primary =>
        ElevatedButton(onPressed: onTap, style: hcPrimaryButtonStyle, child: child),
      HcButtonVariant.secondary => ElevatedButton(
          onPressed: onTap, style: hcSecondaryButtonStyle, child: child),
      HcButtonVariant.destructive => ElevatedButton(
          onPressed: onTap, style: hcDestructiveButtonStyle, child: child),
      HcButtonVariant.outlined => OutlinedButton(
          onPressed: onTap, style: hcOutlinedButtonStyle, child: child),
      HcButtonVariant.text =>
        TextButton(onPressed: onTap, style: hcTextButtonStyle, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
