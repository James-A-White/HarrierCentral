import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/styles.dart';

class LocationPermissionSliderPage extends StatefulWidget {
  const LocationPermissionSliderPage({Key key}) : super(key: key);

  @override
  _LocationPermissionSliderPageState createState() => _LocationPermissionSliderPageState();
}

class _LocationPermissionSliderPageState extends State<LocationPermissionSliderPage> {
  List<Slide> slides = <Slide>[];

  TextStyle titleStyle = const TextStyle(
      color: Colors.black, fontSize: 36.0, fontFamily: 'AvenirNextRegular');

  TextStyle descriptionStyle = const TextStyle(
      color: Colors.black, fontSize: 28.0, fontFamily: 'AvenirNextRegular');

    TextStyle navStyle = TextStyle(
      color: themeAppBarBackground, fontSize: 20.0, fontFamily: 'AvenirNextDemiBold');

  @override
  void initState() {
    super.initState();

    slides.add(
      Slide(
        title: 'Let us know where you are!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'This lets us find the Hash events closest to you',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_phone_location.png',
        heightImage: 240,
        colorBegin: const Color.fromARGB(255, 230, 203, 203),
        colorEnd: const Color.fromARGB(255, 230, 203, 203),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
  }
    

  Future<void> onDonePress() async {

    await PermissionHandler().requestPermissions(<PermissionGroup>[PermissionGroup.location]);
    Navigator.of(context)
        .pushReplacementNamed(RouteNames.PERMISSION_PHOTO_SLIDER.toString());

  }

  void onSkipPress() {
    Navigator.of(context)
        .pushReplacementNamed(RouteNames.PERMISSION_PHOTO_SLIDER.toString());

  }

  Widget renderNextBtn() {
    // return Icon(
    //   Icons.navigate_next,
    //   color: themeAppBarBackground,
    //   size: 35.0,
    // );

    return Text('Next', style:navStyle
    );
  }

  Widget renderDoneBtn() {
    // return Icon(
    //   Icons.done,
    //   color: themeAppBarBackground,
    // );
        return Text('OK', style:navStyle
    );
  }

  Widget renderSkipBtn() {
    // return Icon(
    //   Icons.skip_next,
    //   color: themeAppBarBackground,
    // );
        return Text('No thanks', style:navStyle
    );
  }

  IntroSlider slider;

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      // List slides
      slides: slides,

      // Skip button
      renderSkipBtn: renderSkipBtn(),
      colorSkipBtn: const Color(0x00000000),
      highlightColorSkipBtn: const Color(0xff000000),
      onSkipPress: onSkipPress,
      isShowSkipBtn: true,

      // Next button
      renderNextBtn: renderNextBtn(),
      

      // Done button
      renderDoneBtn: renderDoneBtn(),
      onDonePress: onDonePress,
      colorDoneBtn: const Color(0x00000000),
      highlightColorDoneBtn: const Color(0xff000000),

      // Dot indicator
      // colorDot: themeAppBarBackground40,
      // colorActiveDot: themeAppBarBackground,
      // sizeDot: 9.0,
      isShowDotIndicator: false,

      // Show or hide status bar
      shouldHideStatusBar: true,
    );
  }
}
