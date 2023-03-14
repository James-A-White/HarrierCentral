import 'package:harrier_central/imports_null_safe.dart';

class TextScaleFactorClamper extends StatelessWidget {
  const TextScaleFactorClamper({
    Key? key,
    required this.child,
    required this.textScaleFactor,
  }) : super(key: key);
  final Widget child;
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final num constrainedTextScaleFactor = mediaQueryData.textScaleFactor.clamp(0.8, textScaleFactor);

    return MediaQuery(
      data: mediaQueryData.copyWith(
        textScaleFactor: constrainedTextScaleFactor as double,
      ),
      child: child,
    );
  }
}
