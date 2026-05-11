import 'package:harrier_central/imports.dart';

class BetaRibbon extends StatelessWidget {
  const BetaRibbon({
    super.key,
    this.ribbonImage = 'images/icons/beta_ribbon.png',
    this.showRibbon = true,
    this.text,
    this.title,
    this.child,
    this.feature,
    this.ribbonTopMargin = 0,
  });

  final String ribbonImage;
  final bool showRibbon;
  final String? text;
  final String? title;
  final Widget? child;
  final BetaFeatures? feature;
  final int? ribbonTopMargin;

  @override
  Widget build(BuildContext context) {
    // String betaFeaturesEnabled =
    //     getStringPref(StringPrefsEnum.betaFeaturesEnabled) ?? '';

    // if ((feature != null) &&
    //     (!betaFeaturesEnabled.toLowerCase().contains(
    //       feature!.key.toLowerCase(),
    //     ))) {
    //   return const SizedBox.shrink();
    // }

    if (!showRibbon) {
      return child ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (child != null) child!,
        Positioned(
          left: 0,
          top: ribbonTopMargin?.toDouble() ?? 0,
          child: ((text != null) && (title != null))
              ? GestureDetector(
                  onTap: () async {
                    if ((text != null) && (title != null)) {
                      await Utilities.showAlert(title!, text!, 'OK');
                    }
                  },
                  child: Image.asset(
                    ribbonImage, // <-- now uses the provided image path
                    height: 100,
                    width: 100,
                  ),
                )
              : IgnorePointer(
                  child: Image.asset(
                    ribbonImage, // <-- now uses the provided image path
                    height: 100,
                    width: 100,
                  ),
                ),
        ),
      ],
    );
  }
}
