import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

Color themeButtonColors = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground40 = const Color.fromARGB(102, 13, 115, 124);
Color themeNavBarBackground = const Color.fromARGB(255, 190, 190, 190);
Color themeBackgroundColor = const Color.fromARGB(255, 61, 27, 142);
Color themeLearnMoreLink = Colors.yellow;

IconData delayIcon = Ionicons.md_clock;

const double detailsFontSize = 16.0;
const double detailLineSpace = 1.0;
const double detailLineSpaceForBold = 1.0;

TextStyle listLabelStyle = const TextStyle(color: Colors.yellow, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: detailsFontSize, height: detailLineSpace);

TextStyle listValueStyle = const TextStyle(color: Colors.white, fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: detailsFontSize, height: detailLineSpaceForBold);

TextStyle bodyStyle = const TextStyle(color: Colors.white, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 20.0, height: 1.0);

TextStyle bodyStyleYellow = const TextStyle(color: Colors.yellow, fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 20.0, height: 1.0);

// TextStyle titleStyle = const TextStyle(
//     color: Colors.white,
//     fontFamily: 'AvenirNextRegular',
//     fontStyle: FontStyle.normal,
//     fontSize: 30.0,
//     height: 1.0);

TextStyle textStyleButton = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, color: Colors.white);

TextStyle textStyleDisabledButton = TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, fontSize: 22.0, color: Colors.grey[350]);

TextStyle smallTitleStyle = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0);

TextStyle titleStyle = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 24.0, height: 1.0);

TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.0);
TextStyle headingStyle20 = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 20.0, height: 1.0);
TextStyle headingStyle20italic = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.italic, color: Colors.yellow, fontSize: 20.0, height: 1.0);


TextStyle headingStyleOnLightBg = TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.blue[800], fontSize: 24.0, height: 1.0);

TextStyle smallHeadingStyle = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 20.0, height: 1.0);

TextStyle buttonLabelStyleMedium = const TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0);
TextStyle buttonLabelStyleSmall = const TextStyle(fontFamily: 'AvenirNextMedium', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 0.8);

TextStyle largeText = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 32.0, height: 1.0);

TextStyle buttonTextStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.0);

TextStyle smallContentStyleDb = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.black, fontSize: 20.0, height: 1.0);
TextStyle smallContentStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.black, fontSize: 20.0, height: 1.0);

TextStyle footnote = TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.italic, color: Colors.grey[700], fontSize: 14.0, height: 1.0);
TextStyle footnoteRed = TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.italic, color: Colors.red[900], fontSize: 14.0, height: 1.0);

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
