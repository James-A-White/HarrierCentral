import 'package:harrier_central/imports.dart';

/// The ValueListenableBuilder rebuilds whenever [snackMsg] changes.
class MapSnackbar extends StatelessWidget {
  const MapSnackbar(
    this.snackState, {
    Key? key,
  }) : super(key: key);

  final ValueNotifier<bool> snackState;

  @override
  Widget build(BuildContext context) {
    /// ValueListenableBuilder rebuilds whenever snackMsg value changes.
    /// i.e. this "listens" to changes of ValueNotifier "snackMsg".
    /// "msg" in builder below is the value of "snackMsg" ValueNotifier.
    /// We don't use the other builder args for this example so they are
    /// set to _ & __ just for readability.
    return ValueListenableBuilder<bool>(
        valueListenable: snackState,
        builder: (_, bool msg, __) {
          return Checkbox(
              value: msg,
              onChanged: (bool? x) {
                snackState.value = x ?? false;
              });
        });
  }
}

class RectClipper extends CustomClipper<Rect> {
  RectClipper({
    required this.width,
    required this.height,
  });

  double width;
  double height;

  @override
  Rect getClip(Size size) {
    final Rect r = const Offset(0.0, 0.0) & Size(width, height - 33);

    // This is where we decide what part of our image is going to be
    // visible. If you try to run the app now, nothing will be shown.
    return r;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
