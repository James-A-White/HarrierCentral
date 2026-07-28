import 'package:hcportal/imports.dart';

/// One area's derived-entry state for the currently-selected grantor.
class AreaEntry {
  const AreaEntry(this.label, this.app, this.portal);
  final String label;
  final bool app;
  final bool portal;
  bool get any => app || portal;
}

/// The "Can enter" preview banner. Entry is DERIVED — a role opens a section iff it
/// holds at least one capability in that area — so this shows, live as capabilities
/// are ticked, which doorways the selected role gets. Purely informational.
Widget buildEntryPreview(List<AreaEntry> areas) {
  final entered = [for (final a in areas) if (a.any) a];
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CAN ENTER',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        if (entered.isEmpty)
          const Text(
              'Nothing — this role holds no capability that opens a section.',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final a in entered) _entryChip(a)],
          ),
      ],
    ),
  );
}

Widget _entryChip(AreaEntry a) {
  final surf = a.app && a.portal ? 'app · portal' : (a.app ? 'app' : 'portal');
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFA7F3D0)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
        const SizedBox(width: 6),
        Text(a.label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46))),
        const SizedBox(width: 6),
        Text('· $surf',
            style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
      ],
    ),
  );
}

/// Small tag shown on a capability that isn't available on both surfaces.
/// Nothing renders for a normal (both-surface) capability.
Widget? surfaceTag(int surfaces) {
  final app = (surfaces & kSurfaceApp) != 0;
  final portal = (surfaces & kSurfacePortal) != 0;
  if (app && portal) return null;
  final label = app ? 'app only' : 'portal only';
  return Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFFC7D2FE)),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4338CA))),
  );
}
