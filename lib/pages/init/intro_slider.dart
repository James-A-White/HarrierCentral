import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:intro_slider/intro_slider.dart';
import 'package:tinycolor/tinycolor.dart';

import 'package:harrier_central/util/routes.dart';
import 'package:harrier_central/util/styles.dart';

class IntroSliderPage extends StatefulWidget {
  const IntroSliderPage({Key key}) : super(key: key);

  @override
  _IntroSliderPageState createState() => _IntroSliderPageState();
}

class _IntroSliderPageState extends State<IntroSliderPage> {
  List<Slide> slides = new List();

  TextStyle titleStyle = TextStyle(
      color: Colors.black, fontSize: 36.0, fontFamily: 'AvenirNextRegular');

  TextStyle descriptionStyle = TextStyle(
      color: Colors.black, fontSize: 28.0, fontFamily: 'AvenirNextRegular');

    TextStyle navStyle = TextStyle(
      color: themeAppBarBackground, fontSize: 20.0, fontFamily: 'AvenirNextDemiBold');

  @override
  void initState() {
    super.initState();

    slides.add(
      new Slide(
        title: "Welcome to Harrier Central!",
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: "The World's Most Fun Way to Manage Your Hash Life",
        styleDescription: descriptionStyle,
        pathImage: 'images/other/hc_app_icon.png',
        //widthImage: 150,
        heightImage: 150,
        colorBegin: Color.fromARGB(255, 206, 237, 255),
        colorEnd: Color.fromARGB(255, 206, 237, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      new Slide(
        title: "Discover Hash Runs",
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            "Instantly Find Hash Runs Around the Corner or Across the Globe!",
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_map.png',
        //widthImage: 200,
        heightImage: 200,
        colorBegin: Color.fromARGB(255, 172, 255, 161),
        colorEnd: Color.fromARGB(255, 172, 255, 161),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      new Slide(
        title: 'Your Run History',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Track Your Run Counts Across all Hash Kennels',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_run_counts.png',
        //widthImage: 250,
        heightImage: 270,
        colorBegin: Color.fromARGB(255, 234, 195, 255),
        colorEnd: Color.fromARGB(255, 234, 195, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      new Slide(
        title: 'Built for\r\nMis-Management',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Powerful Tools Designed to Make It Easier to Manage Your Kennel',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_admin_tools.png',
        //widthImage: 250,
        heightImage: 180,
        colorBegin: Color.fromARGB(255, 143, 234, 255),
        colorEnd: Color.fromARGB(255, 143, 234, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
        slides.add(
      new Slide(
        title: 'Secure Data',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'We don\'t Share Your Data with Anyone. Your Data is Locked Securely Away in the HC Cloud.',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_data_security.png',
        //widthImage: 250,
        heightImage: 220,
        colorBegin: Color.fromARGB(255, 255, 165, 115),
        colorEnd: Color.fromARGB(255, 255, 165, 115),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      new Slide(
        title: 'Beta Software',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'Harrier Central is Beta software still under development. If you experience problems, please do not leave a negative reivew, contact us first so we can fix it. Negative reviews hang around forever, but we can kill most bugs in just a few days with your help!',
        styleDescription: TextStyle(
            color: Colors.black,
            fontSize: 19.0,
            fontFamily: 'AvenirNextRegular'),
        pathImage: 'images/init/intro/intro_beta_testing.png',
        //widthImage: 250,
        heightImage: 180,
        colorBegin: Color.fromARGB(255, 221, 255, 69),
        colorEnd: Color.fromARGB(255, 221, 255, 69),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      new Slide(
        title: 'OK! Let\'s\r\nGet Started!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description:
            'We Need Just a Bit of Information to Create Your Custom Harrier Central Experience!',
        styleDescription: TextStyle(
            color: Colors.black,
            fontSize: 24.0,
            fontFamily: 'AvenirNextRegular'),
        pathImage: 'images/init/intro/intro_info_sign.png',
        //widthImage: 250,
        heightImage: 180,
        colorBegin: Color.fromARGB(255, 255, 160, 151),
        colorEnd: Color.fromARGB(255, 255, 160, 151),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
  }

  void onDonePress() {
    Navigator.of(context)
        .pushReplacementNamed(RouteNames.NEW_ACCOUNT.toString());

    // setState(() {
    //   refreshSlide();
    // }

    //);
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
      colorSkipBtn: Color(0x00000000),
      highlightColorSkipBtn: Color(0xff000000),

      // Next button
      renderNextBtn: this.renderNextBtn(),

      // Done button
      renderDoneBtn: this.renderDoneBtn(),
      onDonePress: this.onDonePress,
      colorDoneBtn: Color(0x00000000),
      highlightColorDoneBtn: Color(0xff000000),

      // Dot indicator
      colorDot: themeAppBarBackground40,
      colorActiveDot: themeAppBarBackground,
      sizeDot: 9.0,

      // Locale
      locale: 'en',

      // Show or hide status bar
      shouldHideStatusBar: true,
    );
    ;
  }
}
