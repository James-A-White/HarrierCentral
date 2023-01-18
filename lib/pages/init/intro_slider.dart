// @dart=2.11
import 'package:harrier_central/imports.dart';

class IntroSliderPage extends StatefulWidget {
  const IntroSliderPage({Key key}) : super(key: key);

  @override
  IntroSliderPageState createState() => IntroSliderPageState();
}

class IntroSliderPageState extends State<IntroSliderPage> {
  List<ContentConfig> slides = <ContentConfig>[];

  TextStyle titleStyle;
  TextStyle descriptionStyle;

  TextStyle navStyle;

  @override
  void initState() {
    super.initState();
  }

  void addSlides() {
    descriptionStyle = TextStyle(color: Colors.black, fontSize: 24.0 * G0<DeviceInfo>().deviceWidthScaleFactor, fontFamily: 'AvenirNextRegular');
    titleStyle = TextStyle(color: Colors.black, fontSize: 32.0 * G0<DeviceInfo>().deviceWidthScaleFactor, fontFamily: 'AvenirNextRegular');
    navStyle = TextStyle(color: themeAppBarBackground, fontSize: 18.0 * G0<DeviceInfo>().deviceWidthScaleFactor, fontFamily: 'AvenirNextDemiBold');

    slides.add(
      ContentConfig(
        title: 'Welcome to Harrier Central',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'The World\'s Best Way to Manage Your Hash Life',
        styleDescription: descriptionStyle,
        pathImage: 'images/other/hc_app_icon.png',
        heightImage: 120 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'Discover Hash Runs',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Instantly Find Hash Runs Around the Corner or Across the Globe!',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_map.png',
        heightImage: 120 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 172, 255, 161),
        colorEnd: const Color.fromARGB(255, 172, 255, 161),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'Your Run History',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Track Your Run Counts Across all Hash Kennels',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_run_counts.png',
        heightImage: 170 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 234, 195, 255),
        colorEnd: const Color.fromARGB(255, 234, 195, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'Easy\r\nHash Cash',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'With new ways to pay for the Hash, you\'ll never fumble for cash again',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_cash.png',
        heightImage: 140 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 255, 244, 210),
        colorEnd: const Color.fromARGB(255, 255, 244, 210),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'Built for\r\nMis-Management',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Powerful Tools Designed to Make It Easier to Manage Your Kennel',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_admin_tools.png',
        heightImage: 100 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 200, 200, 255),
        colorEnd: const Color.fromARGB(255, 200, 200, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'Secure Data',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'We don\'t Share Your Data with *Anyone* Outside of Harrier Central',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_data_security.png',
        heightImage: 140 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 255, 190, 180),
        colorEnd: const Color.fromARGB(255, 255, 190, 180),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'More to Come!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'There are dozens more features designed just for the Hash coming soon!',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_rocket.png',
        heightImage: 150 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 143, 234, 255),
        colorEnd: const Color.fromARGB(255, 143, 234, 255),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
    slides.add(
      ContentConfig(
        title: 'OK! Let\'s\r\nGet Started!',
        maxLineTitle: 2,
        styleTitle: titleStyle,
        description: 'Now We Need Just a Bit of Information to Create Your Custom Harrier Central Experience!',
        styleDescription: descriptionStyle,
        pathImage: 'images/init/intro/intro_info_sign.png',
        heightImage: 100 * G0<DeviceInfo>().deviceMaxScaleFactor,
        colorBegin: const Color.fromARGB(255, 227, 227, 227),
        colorEnd: const Color.fromARGB(255, 227, 227, 227),
        directionColorBegin: Alignment.topRight,
        directionColorEnd: Alignment.bottomLeft,
      ),
    );
  }

  Future<void> onDonePress() async {
    await Navigator.of(context).pushReplacementNamed(RouteNames.PERMISSIONS_SLIDER.toString());
  }

  Future<void> onSkipPress() async {
    // introSlider = null;
    // slides.clear();
    // addSlides();
    // setState(() {
    //   buildIntroSlider();
    // });
    await Navigator.of(context).pushReplacementNamed(RouteNames.INTRO_SLIDER.toString());
  }

  Widget renderNextBtn() {
    // return Icon(
    //   Icons.navigate_next,
    //   color: themeAppBarBackground,
    //   size: 35.0,
    // );

    return Text('Next', style: navStyle);
  }

  Widget renderDoneBtn() {
    // return Icon(
    //   Icons.done,
    //   color: themeAppBarBackground,
    // );
    return Text('OK', style: navStyle);
  }

  Widget renderSkipBtn() {
    // return Icon(
    //   Icons.skip_next,
    //   color: themeAppBarBackground,
    // );
    return Text('Skip', style: navStyle);
  }

  IntroSlider slider;

  @override
  Widget build(BuildContext context) {
    if (slides.isEmpty) {
      addSlides();
    }
    return IntroSlider(
      // Indicator
      indicatorConfig: IndicatorConfig(
        sizeIndicator: 10,
        indicatorWidget: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: themeAppBarBackground40),
        ),
        activeIndicatorWidget: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: themeAppBarBackground),
        ),
        spaceBetweenIndicator: 10,
        typeIndicatorAnimation: TypeIndicatorAnimation.sliding,
      ),
      // // Dot indicator
      // colorDot: themeAppBarBackground40,
      // colorActiveDot: themeAppBarBackground,
      // sizeDot: 6.5,

      // // Show or hide status bar
      // hideStatusBar: true,
      // List slides
      listContentConfig: slides,
      //onSkipPress: onSkipPress,

      // Skip button
      renderSkipBtn: renderSkipBtn(),
      skipButtonStyle: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color(0xff000000);
            }
            return const Color(0xffffffff);
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return const Color(0x00000000);
          },
        ),
      ),

      // Next button
      renderNextBtn: renderNextBtn(),
      nextButtonStyle: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color(0xff000000);
            }
            return const Color(0xffffffff);
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return const Color(0x00000000);
          },
        ),
      ),

      // Done button
      renderDoneBtn: renderDoneBtn(),
      onDonePress: onDonePress,
      doneButtonStyle: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color(0xff000000);
            }
            return const Color(0xffffffff);
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return const Color(0x00000000);
          },
        ),
      ),
    );
  }
}
