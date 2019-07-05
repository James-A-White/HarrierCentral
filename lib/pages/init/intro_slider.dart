import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intro_slider/intro_slider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/styles.dart';

class IntroSliderPage extends StatefulWidget {
  const IntroSliderPage({Key key}) : super(key: key);

  @override
  _IntroSliderPageState createState() => _IntroSliderPageState();
}

class _IntroSliderPageState extends State<IntroSliderPage> {
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
        title: 'Welcome to Harrier Central',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'The World\'s Best Way to Manage Your Hash Life',
        styleDescription: descriptionStyle,
        pathImage: 'images/other/hc_app_icon.png',
        //widthImage: 150,
        heightImage: 150,
        colorBegin: const Color.fromARGB(255, 206, 237, 255),
        colorEnd: const Color.fromARGB(255, 206, 237, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'Discover Hash Runs',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Instantly Find Hash Runs Around the Corner or Across the Globe!',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_map.png',
        heightImage: 200,
        colorBegin: const Color.fromARGB(255, 172, 255, 161),
        colorEnd: const Color.fromARGB(255, 172, 255, 161),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'Your Run History',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Track Your Run Counts Across all Hash Kennels',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_run_counts.png',
        heightImage: 270,
        colorBegin: const Color.fromARGB(255, 234, 195, 255),
        colorEnd: const Color.fromARGB(255, 234, 195, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'Built for\r\nMis-Management',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Powerful Tools Designed to Make It Easier to Manage Your Kennel',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_admin_tools.png',
        heightImage: 180,
        colorBegin: const Color.fromARGB(255, 143, 234, 255),
        colorEnd: const Color.fromARGB(255, 143, 234, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
        slides.add(
      Slide(
        title: 'Secure Data',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'We don\'t Share Your Data with *Anyone* Outside of Harrier Central',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_data_security.png',
        heightImage: 220,
        colorBegin: const Color.fromARGB(255, 255, 165, 115),
        colorEnd: const Color.fromARGB(255, 255, 165, 115),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'Beta Software',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'We are building 5-star software, but we\'re not done yet! Please contact us with bug reports and feature requests',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_beta_testing.png',
        heightImage: 180,
        colorBegin: const Color.fromARGB(255, 221, 255, 69),
        colorEnd: const Color.fromARGB(255, 221, 255, 69),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
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

        // Navigator.of(context)
        // .pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());


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
        return Text('Skip', style:navStyle
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

      // Next button
      renderNextBtn: renderNextBtn(),

      // Done button
      renderDoneBtn: renderDoneBtn(),
      onDonePress: onDonePress,
      colorDoneBtn: const Color(0x00000000),
      highlightColorDoneBtn: const Color(0xff000000),

      // Dot indicator
      colorDot: themeAppBarBackground40,
      colorActiveDot: themeAppBarBackground,
      sizeDot: 9.0,

      // Show or hide status bar
      shouldHideStatusBar: true,
    );
  }
}
