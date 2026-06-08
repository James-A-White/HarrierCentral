import 'package:harrier_central/imports.dart';

/// Shows the tracking quality picker and saves the selection to prefs.
/// Returns true if the user confirmed a choice.
Future<bool> showTrackingQualityDialog(BuildContext context) async {
  final result = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TrackingQualityDialog(),
  );
  if (result == null) return false;
  await setIntPref(IntPrefsEnum.trackingQuality, result);
  return true;
}

class _TrackingQualityDialog extends StatefulWidget {
  const _TrackingQualityDialog();

  @override
  State<_TrackingQualityDialog> createState() => _TrackingQualityDialogState();
}

class _TrackingQualityDialogState extends State<_TrackingQualityDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = getIntPref(IntPrefsEnum.trackingQuality) ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.power, color: themeBackgroundColor, size: 28),
          const SizedBox(width: 10),
          Text('GPS Tracking Quality', style: ts_alertDialogTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Higher accuracy gives a more detailed track but drains battery faster.',
            style: ts_alertDialogBody,
          ),
          const SizedBox(height: 16),
          _option(2, 'Best', 'Finest GPS detail — highest battery use', 3),
          _option(1, 'Balanced', 'Good accuracy — moderate battery use', 2),
          _option(0, 'Power Saver', 'Coarser track — lowest battery use', 1),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeBackgroundColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _option(int value, String label, String sub, int boltCount) {
    final isSelected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeBackgroundColor.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? themeBackgroundColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? themeBackgroundColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Row(
              children: List.generate(3, (i) => Icon(
                Icons.bolt,
                size: 18,
                color: i < boltCount ? Colors.amber.shade700 : Colors.grey.shade300,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
