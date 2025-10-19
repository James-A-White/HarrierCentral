import 'package:harrier_central/imports.dart';

class BetaRibbon extends StatelessWidget {
  const BetaRibbon({
    super.key,
    this.ribbonImage = 'images/icons/beta_ribbon.png',
    this.text,
    this.title,
  });

  final String ribbonImage;
  final String? text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: GestureDetector(
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
      ),
    );
  }
}
