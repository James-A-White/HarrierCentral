import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Integration Source Selector Widget
// ---------------------------------------------------------------------------

/// A reusable widget for selecting between external (integration) and local
/// data sources.
///
/// This widget displays a card with radio buttons allowing the user to choose
/// whether to use data from an external integration source or from Harrier
/// Central's local data.
///
/// Common use cases:
/// - Choosing between Facebook event data and local data
/// - Selecting image source (external vs uploaded)
/// - Toggling location/coordinates source
///
/// Example usage:
/// ```dart
/// IntegrationSourceSelector(
///   title: 'Data Source',
///   useExternalSource: controller.useExtRunDetails,
///   externalSourceName: 'Facebook',
///   externalLabel: 'Use data from Facebook (read-only)',
///   localLabel: 'Use Harrier Central data (editable)',
///   onChanged: () => controller.checkIfFormIsDirty(),
/// )
/// ```
class IntegrationSourceSelector extends StatelessWidget {
  const IntegrationSourceSelector({
    super.key,
    required this.title,
    required this.useExternalSource,
    required this.externalSourceName,
    this.externalLabel,
    this.localLabel,
    this.onChanged,
    this.cardColor,
    this.icon,
    this.showIcon = true,
  });

  /// Title displayed at the top of the card.
  final String title;

  /// Reactive boolean indicating if external source is selected.
  final RxBool useExternalSource;

  /// Name of the external data source (e.g., "Facebook", "Eventbrite").
  final String externalSourceName;

  /// Custom label for the external source option.
  /// Defaults to "Use data from {externalSourceName} (read-only)".
  final String? externalLabel;

  /// Custom label for the local source option.
  /// Defaults to "Use Harrier Central data (editable)".
  final String? localLabel;

  /// Callback invoked when the selection changes.
  final VoidCallback? onChanged;

  /// Background color for the card.
  /// Defaults to Colors.blue.shade50.
  final Color? cardColor;

  /// Icon to display next to the title.
  final IconData? icon;

  /// Whether to show the icon (if provided).
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Card(
          color: cardColor ?? Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 8),
                _buildExternalOption(),
                _buildLocalOption(),
              ],
            ),
          ),
        ));
  }

  Widget _buildTitle() {
    if (showIcon && icon != null) {
      return Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: titleStyleBlack),
        ],
      );
    }
    return Text(title, style: titleStyleBlack);
  }

  Widget _buildExternalOption() {
    final label =
        externalLabel ?? 'Use data from $externalSourceName (read-only)';

    return Row(
      children: [
        Radio<bool>(
          value: true,
          groupValue: useExternalSource.value,
          onChanged: (value) {
            useExternalSource.value = value ?? false;
            onChanged?.call();
          },
        ),
        Expanded(child: Text(label)),
      ],
    );
  }

  Widget _buildLocalOption() {
    final label = localLabel ?? 'Use Harrier Central data (editable)';

    return Row(
      children: [
        Radio<bool>(
          value: false,
          groupValue: useExternalSource.value,
          onChanged: (value) {
            useExternalSource.value = value ?? false;
            onChanged?.call();
          },
        ),
        Expanded(child: Text(label)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact Integration Toggle Widget
// ---------------------------------------------------------------------------

/// A more compact version of the integration source selector.
///
/// Displays as a single row with a switch instead of radio buttons.
/// Useful when space is limited or for less prominent options.
///
/// Example usage:
/// ```dart
/// IntegrationSourceToggle(
///   label: 'Use Facebook data',
///   useExternalSource: controller.useExtLocation,
///   onChanged: () => controller.checkIfFormIsDirty(),
/// )
/// ```
class IntegrationSourceToggle extends StatelessWidget {
  const IntegrationSourceToggle({
    super.key,
    required this.label,
    required this.useExternalSource,
    this.onChanged,
    this.subtitle,
    this.activeColor,
  });

  /// Label for the toggle.
  final String label;

  /// Reactive boolean indicating if external source is selected.
  final RxBool useExternalSource;

  /// Callback invoked when the toggle changes.
  final VoidCallback? onChanged;

  /// Optional subtitle text.
  final String? subtitle;

  /// Color for the active switch.
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SwitchListTile(
          title: Text(label),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          value: useExternalSource.value,
          activeColor: activeColor ?? Colors.blue.shade600,
          onChanged: (value) {
            useExternalSource.value = value;
            onChanged?.call();
          },
          contentPadding: EdgeInsets.zero,
        ));
  }
}

// ---------------------------------------------------------------------------
// Multi-Option Integration Selector Widget
// ---------------------------------------------------------------------------

/// A selector for choosing between multiple data source options.
///
/// Use this when you have more than two source options (e.g., multiple
/// integrations plus local data).
///
/// Example usage:
/// ```dart
/// MultiSourceSelector<DataSource>(
///   title: 'Data Source',
///   selectedValue: controller.selectedSource,
///   options: [
///     SourceOption(value: DataSource.facebook, label: 'Facebook'),
///     SourceOption(value: DataSource.eventbrite, label: 'Eventbrite'),
///     SourceOption(value: DataSource.local, label: 'Harrier Central'),
///   ],
///   onChanged: (value) => controller.selectedSource.value = value,
/// )
/// ```
class MultiSourceSelector<T> extends StatelessWidget {
  const MultiSourceSelector({
    super.key,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    this.cardColor,
  });

  /// Title displayed at the top of the card.
  final String title;

  /// Currently selected value (reactive).
  final Rx<T> selectedValue;

  /// List of available source options.
  final List<SourceOption<T>> options;

  /// Callback when selection changes.
  final ValueChanged<T> onChanged;

  /// Background color for the card.
  final Color? cardColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Card(
          color: cardColor ?? Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyleBlack),
                const SizedBox(height: 8),
                ...options.map((option) => _buildOption(option)),
              ],
            ),
          ),
        ));
  }

  Widget _buildOption(SourceOption<T> option) {
    return Row(
      children: [
        Radio<T>(
          value: option.value,
          groupValue: selectedValue.value,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(option.label),
              if (option.subtitle != null)
                Text(
                  option.subtitle!,
                  style: bodyStyleBlack.copyWith(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        if (option.icon != null) Icon(option.icon, color: Colors.grey.shade600),
      ],
    );
  }
}

/// Represents a single option in a multi-source selector.
class SourceOption<T> {
  const SourceOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  /// The value associated with this option.
  final T value;

  /// Display label for this option.
  final String label;

  /// Optional subtitle/description.
  final String? subtitle;

  /// Optional icon to display.
  final IconData? icon;
}
