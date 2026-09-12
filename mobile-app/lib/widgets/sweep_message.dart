import 'package:harrier_central/imports.dart';

/// The full-screen "nothing yet" / "working" state of the camera-roll sweep.
///
/// The Center is not decoration. A Column does NOT expand to fill its width —
/// it takes the width of its widest child — so a Column inside a Padding sits
/// against the left edge, and its crossAxisAlignment then centres the children
/// against each other rather than against the screen. That is exactly what
/// shipped in 3.0.31: the spinner looked centred on the text, and the pair sat
/// on the left (James, 2026-09-12).
class SweepMessage extends StatelessWidget {
  const SweepMessage({super.key, required this.text, this.spinner = false});

  final String text;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (spinner) ...<Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
            ],
            Text(text, style: ts_alertDialogBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
