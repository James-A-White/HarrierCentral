import 'dart:async';
import 'package:flutter/material.dart';


class Backgrounds {
   static BoxDecoration defaultHcBackground()
   {
     return BoxDecoration(

image: DecorationImage(
      image: ExactAssetImage('images/backgrounds/hash_foot_background.png'),
      fit: BoxFit.cover,));


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
