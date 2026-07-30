import 'package:harrier_central/imports.dart';

// ---------------------------------------------------------------------------
// Photo review actions — single source of truth
// ---------------------------------------------------------------------------

/// One photo review action as the UI presents it: the `photoAction*` code plus
/// its button caption, badge caption, icon and colour.
///
/// [photoActionSpecs] is the ONLY place these are declared. Both review
/// surfaces (the single-photo carousel and the multi-select grid) render that
/// list through [PhotoActionButtonBar], and the status badges / count chips
/// take their labels and colours from it too — so a new rung on the ladder is
/// added in exactly one place and cannot drift between screens.
class PhotoActionSpec {
  const PhotoActionSpec({
    required this.action,
    required this.label,
    required this.tagLabel,
    required this.icon,
    required this.color,
    this.status,
    this.singleTargetOnly = false,
  });

  /// `photoAction*` code sent to `HC6.hcapp_updatePhotoStatus`.
  final int action;

  /// The `HC.KennelPhotos.Status` this action writes, or null when it doesn't
  /// write one — Delete is a soft delete that stamps `DeletedAt` and leaves
  /// `Status` alone.
  final int? status;

  /// Button caption.
  final String label;

  /// Shorter caption for status badges and count chips.
  final String tagLabel;

  final IconData icon;
  final Color color;

  /// Actions that only make sense on one photo at a time. Cover Photo is the
  /// only one — an event has exactly one cover (the SP demotes any previous
  /// `Status=5` row), so applying it to a multi-selection would just leave
  /// whichever row happened to be written last.
  final bool singleTargetOnly;
}

/// The single-tag ladder in ascending audience order, with Delete last so the
/// destructive action is never the first button under the reviewer's thumb.
final List<PhotoActionSpec> photoActionSpecs = List.unmodifiable([
  PhotoActionSpec(
    action: photoActionKeepPrivate,
    label: 'Private',
    tagLabel: 'Private',
    icon: Icons.lock_outline,
    color: Colors.blueGrey.shade600,
    status: 0,
  ),
  PhotoActionSpec(
    action: photoActionMembers,
    label: 'Members',
    tagLabel: 'Members',
    icon: Icons.people_outline,
    color: Colors.blue.shade700,
    status: 2,
  ),
  PhotoActionSpec(
    action: photoActionPublic,
    label: 'Public',
    tagLabel: 'Public',
    icon: Icons.public,
    color: Colors.green.shade700,
    status: 3,
  ),
  PhotoActionSpec(
    action: photoActionFeature,
    label: 'Featured',
    tagLabel: 'Featured',
    icon: Icons.home_outlined,
    color: Colors.teal.shade600,
    status: 4,
  ),
  PhotoActionSpec(
    action: photoActionMakeEventCover,
    label: 'Cover Photo',
    tagLabel: 'Cover',
    icon: Icons.star_outline,
    color: Colors.teal.shade800,
    status: 5,
    singleTargetOnly: true,
  ),
  PhotoActionSpec(
    action: photoActionDelete,
    label: 'Delete',
    tagLabel: 'Deleted',
    icon: Icons.delete_outline,
    color: hc_red,
  ),
]);

final Map<int, PhotoActionSpec> _specsByAction = {
  for (final spec in photoActionSpecs) spec.action: spec,
};

final Map<int, PhotoActionSpec> _specsByStatus = {
  for (final spec in photoActionSpecs)
    if (spec.status != null) spec.status!: spec,
};

/// Spec for an action code, or null if there isn't one (e.g. a pending photo).
PhotoActionSpec? photoActionSpec(int? action) =>
    action == null ? null : _specsByAction[action];

/// Spec for a `HC.KennelPhotos.Status` value. Status 1 (pending) is produced by
/// the upload, not by a review action, so it returns null.
PhotoActionSpec? photoSpecForStatus(int status) => _specsByStatus[status];

/// `HC.KennelPhotos.Status` → the action that produces it, or null for pending.
int? photoActionForStatus(int status) => photoSpecForStatus(status)?.action;

/// Badge / chip colour for a photo that hasn't been actioned yet.
final Color photoPendingColor = Colors.orange.shade800;

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

/// The action button bar shared by both photo review surfaces.
///
/// * Single-photo carousel: every action enabled, [selectedAction] marks the
///   photo's current (or queued) status, [dimUnselected] fades the rest.
/// * Multi-select grid: no selected action; [isEnabled] greys the bar out when
///   nothing is selected, and Cover Photo when more than one photo is.
class PhotoActionButtonBar extends StatelessWidget {
  const PhotoActionButtonBar({
    super.key,
    required this.onAction,
    this.selectedAction,
    this.isEnabled,
    this.dimUnselected = false,
  });

  /// Called with the `photoAction*` code of the button tapped.
  final ValueChanged<int> onAction;

  /// The action already applied (or queued) for the photo under review.
  final int? selectedAction;

  /// Per-action enablement. Null means every action is enabled.
  final bool Function(PhotoActionSpec spec)? isEnabled;

  /// Fade the non-selected buttons once [selectedAction] is known, so the
  /// photo's current status stands out.
  final bool dimUnselected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final spec in photoActionSpecs)
          PhotoActionButton(
            spec: spec,
            enabled: isEnabled?.call(spec) ?? true,
            isSelected: selectedAction == spec.action,
            dimmed: dimUnselected &&
                selectedAction != null &&
                selectedAction != spec.action,
            onTap: () => onAction(spec.action),
          ),
      ],
    );
  }
}

class PhotoActionButton extends StatelessWidget {
  const PhotoActionButton({
    super.key,
    required this.spec,
    required this.onTap,
    this.enabled = true,
    this.isSelected = false,
    this.dimmed = false,
  });

  final PhotoActionSpec spec;
  final VoidCallback onTap;
  final bool enabled;
  final bool isSelected;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Color fg = enabled ? Colors.white : Colors.grey.shade700;
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(isSelected ? Icons.check_circle : spec.icon,
          size: 18, color: fg),
      label: Text(
        spec.label,
        style: ts_button.copyWith(
          color: fg,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            dimmed ? spec.color.withValues(alpha: 0.5) : spec.color,
        foregroundColor: Colors.white,
        // Keep disabled buttons visible (light grey, dark grey text) instead
        // of fading to invisible-with-white-text.
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade700,
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 2)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
