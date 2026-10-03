import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';

/// Asks which trail-type lane a trail is for. The run's kennel's visible
/// types, Normal first when nothing else is suggested. Null = cancelled.
Future<int?> pickOfficialTrailType(
  BuildContext context, {
  required List<TrailType> types,
  required Set<int> taken,
  String title = 'Which trail is this?',
}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext ctx) => SimpleDialog(
      title: Text(title, style: ts_alertDialogTitle, textAlign: TextAlign.center),
      children: <Widget>[
        for (final TrailType t in types)
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(t.value),
            child: Row(
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: OfficialTrailLane.colorOf(t.value),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t.emoji} ${t.label}'
                    '${taken.contains(t.value) ? '  (replaces the saved one)' : ''}',
                    style: ts_alertDialogBody,
                  ),
                ),
              ],
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Cancel',
            style: ts_alertDialogBody.copyWith(color: Colors.blueGrey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
