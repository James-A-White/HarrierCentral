import 'package:harrier_central/imports.dart';

Color themeButtonColors = const Color.fromARGB(255, 13, 115, 124);
Color themeStatusBarBackground = const Color.fromARGB(255, 7, 63, 68);
Color themeAppBarBackground = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground40 = const Color.fromARGB(102, 13, 115, 124);
Color themeNavBarBackground = const Color.fromARGB(255, 190, 190, 190);
Color themeBackgroundColor = const Color.fromARGB(255, 61, 27, 142);
Color themeLearnMoreLink = Colors.yellow;
Color themeLightBackground = Colors.yellow.shade100;

IconData delayIcon = MaterialCommunityIcons.progress_clock;
const String delayIconAsset = 'images/icons/progress_clock.png';

const double detailsFontSize = 16.0;
const double detailLineSpace = 1.0;
const double detailLineSpaceForBold = 1.1;

// Color brown = const Color.fromARGB(255, 107, 87, 66);
// Color purple = const Color.fromARGB(255, 61, 27, 142);
// Color yellow = const Color.fromARGB(255, 236, 212, 68);
// Color brickRed = const Color.fromARGB(255, 51, 0, 14);
// Color teal = const Color.fromARGB(255, 13, 115, 124);

class Backgrounds {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  static BoxDecoration defaultHcBackground() {
    return const BoxDecoration(
        image: DecorationImage(
      image: ExactAssetImage('images/backgrounds/hash_foot_background.png'),
      fit: BoxFit.cover,
    ));
  }

  static BoxDecoration defaultHcBackgroundLight() {
    return const BoxDecoration(
        image: DecorationImage(
      image:
          ExactAssetImage('images/backgrounds/hash_foot_background_light.png'),
      fit: BoxFit.cover,
    ));
  }
}
