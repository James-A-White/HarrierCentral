import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';

import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/styles.dart';

class GetStartedSliderPage extends StatefulWidget {
  const GetStartedSliderPage({Key key}) : super(key: key);

  @override
  _GetStartedSliderPageState createState() => _GetStartedSliderPageState();
}

class _GetStartedSliderPageState extends State<GetStartedSliderPage> {
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
        title: 'Some Last\r\nDetails',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Now Just a Tiny Bit of Personal Information (we don\'t share this outside of Harrier Central)',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_pen.png',
        //widthImage: 250,
        heightImage: 180,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
  }
    

  Future<void> onDonePress() async {
    Navigator.of(context)
        .pushReplacementNamed(RouteNames.NEW_ACCOUNT.toString());
  }

  void onSkipPress() {
    Navigator.of(context)
        .pushReplacementNamed(RouteNames.NEW_ACCOUNT.toString());

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
        return Text('Start!', style:navStyle
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
