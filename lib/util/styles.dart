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

    //   // Box decoration takes a gradient
    //   gradient: LinearGradient(
    //     // Where the linear gradient begins and ends
    //     begin: Alignment.topRight,
    //     end: Alignment.bottomLeft,
    //     // Add one stop for each color. Stops should increase from 0 to 1
    //     stops: [0.1, 0.9],
    //     colors: [
    //       // Colors are easy thanks to Flutter's Colors class.
    //       Colors.blue[500],
    //       Colors.indigo[900],
    //     ],
    //   ),
    // );
  }
}
