import 'package:harrier_central/imports.dart';

/// "People not in the app": type a name, tap +, and it becomes a chip that can
/// be removed. Shared by Add and Edit Down Down so the two cannot drift.
///
/// [names] must be read by the PAGE, inside its Obx: an Obx tracks only the
/// observables its own builder reads, not what a child's build reads later,
/// so reading c.externalNames here would leave the chips stale.
class DownDownExternalNamesField extends StatelessWidget {
  const DownDownExternalNamesField({
    super.key,
    required this.c,
    required this.names,
  });

  final DownDownFormController c;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'People not in the app',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c.externalNameController,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          onSubmitted: c.addExternalName,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Add a name, then tap +',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            prefixIcon: const Icon(Icons.person_add_alt_1),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add name',
              onPressed: () => c.addExternalName(),
            ),
          ),
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: names
                .map(
                  (name) => Chip(
                    label: Text(name),
                    backgroundColor: Colors.yellow.shade700,
                    labelStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    deleteIconColor: Colors.black54,
                    onDeleted: () => c.removeExternalName(name),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// One hasher in the "People in the app" list: tick to charge them.
class DownDownAttendeeTile extends StatelessWidget {
  const DownDownAttendeeTile({
    super.key,
    required this.c,
    required this.attendee,
  });

  final DownDownFormController c;
  final AttendeeItem attendee;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: attendee.selected,
      title: Text(
        attendee.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
        ),
      ),
      onChanged: (v) => c.toggleAttendee(attendee, v ?? false),
      activeColor: Colors.yellow,
      checkColor: Colors.black87,
      side: const BorderSide(color: Colors.yellow, width: 1.5),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
