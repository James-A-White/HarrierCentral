import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harrier_central/util/globals.dart';

import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/styles.dart';

class IntroSliderPage extends StatefulWidget {
  const IntroSliderPage({Key key}) : super(key: key);

  @override
  _IntroSliderPageState createState() => _IntroSliderPageState();
}

class _IntroSliderPageState extends State<IntroSliderPage> {
  List<Slide> slides = <Slide>[];

  TextStyle titleStyle;
  TextStyle descriptionStyle;

    TextStyle navStyle;


  @override
  void initState() {
    super.initState();
  }


  void addSlides() {

    descriptionStyle = TextStyle(color: Colors.black, fontSize: 24.0 * deviceWidthScaleFactor, fontFamily: 'AvenirNextRegular');
    titleStyle = TextStyle(color: Colors.black, fontSize: 32.0 * deviceWidthScaleFactor, fontFamily: 'AvenirNextRegular');
    navStyle = TextStyle(color: themeAppBarBackground, fontSize: 18.0 * deviceWidthScaleFactor, fontFamily: 'AvenirNextDemiBold');
    
    slides.add(
      Slide(
        title: 'Welcome to Harrier Central',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'The World\'s Best Way to Manage Your Hash Life',
        styleDescription: descriptionStyle,
        pathImage: 'images/other/hc_app_icon.png',
        heightImage: 120 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
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
        heightImage: 120 * deviceMaxScaleFactor,
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
        heightImage: 170 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 234, 195, 255),
        colorEnd: const Color.fromARGB(255, 234, 195, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'Easy\r\nHash Cash',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'With new ways to pay for the Hash, you\'ll never fumble for cash again',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_cash.png',
        heightImage: 140 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 255, 244, 210),
        colorEnd: const Color.fromARGB(255, 255, 244, 210),
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
        heightImage: 100 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 200, 200, 255),
        colorEnd: const Color.fromARGB(255, 200, 200, 255),
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
        heightImage: 140 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 255, 190, 180),
        colorEnd: const Color.fromARGB(255, 255, 190, 180),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'More to Come!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'There are dozens more features designed just for the Hash coming soon!',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_rocket.png',
        heightImage: 150 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 143, 234, 255),
        colorEnd: const Color.fromARGB(255, 143, 234, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      Slide(
        title: 'OK! Let\'s\r\nGet Started!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Now We Need Just a Bit of Information to Create Your Custom Harrier Central Experience!',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_info_sign.png',
        heightImage: 100 * deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    

  }

  Future<void> onDonePress() async {
    
    Navigator.of(context)
        .pushReplacementNamed(RouteNames.PERMISSIONS_SLIDER.toString());

  }

  Future<void> onSkipPress() async {
    // introSlider = null;
    // slides.clear();
    // addSlides();
    // setState(() {
    //   buildIntroSlider();
    // });
        Navigator.of(context)
        .pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
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
    if (slides.isEmpty)
    {
      addSlides();
    }
    return IntroSlider(
      // List slides
      slides: slides,
      //onSkipPress: onSkipPress,

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
      sizeDot: 6.5,

      // Show or hide status bar
      shouldHideStatusBar: true,
    );
  }
}
