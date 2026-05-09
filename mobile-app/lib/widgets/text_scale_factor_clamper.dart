import 'package:harrier_central/imports.dart';

class TextScaleFactorClamper extends StatelessWidget {
  const TextScaleFactorClamper({
    super.key,
    required this.child,
    required this.textScaleFactor,
  });
  final Widget child;
  final double textScaleFactor;

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final TextScaler constrainedTextScaleFactor = mediaQueryData.textScaler.clamp(
      minScaleFactor: .8,
      maxScaleFactor: textScaleFactor,
    );

    return MediaQuery(
      data: mediaQueryData.copyWith(
        textScaler: constrainedTextScaleFactor,
      ),
      child: child,
    );
  }
}
