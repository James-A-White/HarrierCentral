import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

Color themeButtonColors = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground40 = const Color.fromARGB(102, 13, 115, 124);
Color themeNavBarBackground = const Color.fromARGB(255, 190, 190, 190);
Color themeBackgroundColor = const Color.fromARGB(255, 61, 27, 142);
Color themeLearnMoreLink = Colors.yellow;

IconData delayIcon = Ionicons.md_clock;

TextStyle textStyleButton = const TextStyle(
    fontFamily: 'AvenirNextDemiBold',
    fontStyle: FontStyle.normal,
    fontSize: 22.0,
    color: Colors.white);

TextStyle textStyleDisabledButton = TextStyle(
    fontFamily: 'AvenirNextDemiBold',
    fontStyle: FontStyle.normal,
    fontSize: 22.0,
    color: Colors.grey[350]);

TextStyle titleStyle = const TextStyle(
      fontFamily: 'AvenirNextDemiBold',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 24.0,
      height: 1.0);

TextStyle headingStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 24.0,
      height: 1.0);

TextStyle headingStyleOnLightBg = TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.blue[800],
      fontSize: 24.0,
      height: 1.0);

TextStyle smallHeadingStyle = const TextStyle(
      fontFamily: 'AvenirNextDemiBold',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 20.0,
      height: 1.0);

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


