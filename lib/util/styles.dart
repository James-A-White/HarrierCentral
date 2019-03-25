import 'package:flutter/material.dart';

Color themeButtonColors = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground = const Color.fromARGB(255, 13, 115, 124);
Color themeNavBarBackground = const Color.fromARGB(255, 190, 190, 190);
Color themeBackgroundColor = const Color.fromARGB(255, 61, 27, 142);
Color themeLearnMoreLink = Colors.yellow;

// Color brown = const Color.fromARGB(255, 107, 87, 66);
// Color purple = const Color.fromARGB(255, 61, 27, 142);
// Color yellow = const Color.fromARGB(255, 236, 212, 68);
// Color brickRed = const Color.fromARGB(255, 51, 0, 14);
// Color teal = const Color.fromARGB(255, 13, 115, 124);

class Backgrounds {
  static BoxDecoration defaultHcBackground() {
    return BoxDecoration(
        image: DecorationImage(
      image: ExactAssetImage('images/backgrounds/hash_foot_background.png'),
      fit: BoxFit.cover,
    ));
  }

  static BoxDecoration defaultHcBackgroundLight() {
    return BoxDecoration(
        image: DecorationImage(
      image: ExactAssetImage('images/backgrounds/hash_foot_background_light.png'),
      fit: BoxFit.cover,
    ));
  }
}
