import 'package:hcportal/imports.dart';

Color themeButtonColors = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground = const Color.fromARGB(255, 13, 115, 124);
Color themeAppBarBackground40 = const Color.fromARGB(102, 13, 115, 124);
Color themeNavBarBackground = const Color.fromARGB(255, 190, 190, 190);
Color themeBackgroundColor = const Color.fromARGB(255, 61, 27, 142);
Color themeLearnMoreLink = Colors.yellow;

IconData delayIcon = MaterialCommunityIcons.progress_clock;

const double detailsFontSize = 16;
const double detailLineSpace = 1;
const double detailLineSpaceForBold = 1.1;

ButtonStyle defaultButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith<Color>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.grey; // Grey background when disabled
      }
      return Colors.red[800]!; // Dark red background when enabled
    },
  ),
  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // 8px corner radius
    ),
  ),
  foregroundColor: WidgetStateProperty.all<Color>(Colors.white), // White text
  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
    const EdgeInsets.symmetric(
        vertical: 12, horizontal: 16), // Optional padding
  ),
);

TextStyle listLabelStyle = const TextStyle(
  color: Colors.yellow,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: detailsFontSize,
  height: detailLineSpace,
);

TextStyle listValueStyle = const TextStyle(
  color: Colors.white,
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  fontSize: detailsFontSize,
  height: detailLineSpaceForBold,
);

TextStyle bodyStyle = const TextStyle(
  color: Colors.white,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: 20,
  height: 1,
);

TextStyle bodyStyleBlack = const TextStyle(
  color: Colors.black,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: 20,
  height: 1.2,
);

TextStyle bodyStyleBlackSmall = const TextStyle(
  color: Colors.black,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: 16,
  height: 1,
);

TextStyle bodyStyleYellow = const TextStyle(
  color: Colors.yellow,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: 20,
  height: 1,
);

TextStyle bodyStylePink = TextStyle(
  color: Colors.pink.shade100,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: 20,
  height: 1,
);

TextStyle bodyStyleSc = const TextStyle(
  color: Colors.white,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  fontSize: 12,
  height: 1,
);

TextStyle formHintStyle = TextStyle(
  color: Colors.blueGrey.shade300,
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.italic,
  fontSize: 20,
  height: 1,
);
// TextStyle titleStyle = const TextStyle(
//     color: Colors.white,
//     fontFamily: 'AvenirNextRegular',
//     fontStyle: FontStyle.normal,
//     fontSize: 30.0,
//     height: 1.0);

TextStyle textStyleButton = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  fontSize: 22,
  color: Colors.white,
);

TextStyle textStyleDisabledButton = TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  fontSize: 22,
  color: Colors.grey[350],
);

TextStyle smallTitleStyle = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 20,
  height: 1,
);

TextStyle titleStyle = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 24,
  height: 1.2,
);

TextStyle titleStyleBlack = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 24,
  height: 1.2,
);

TextStyle largeTitleStyle = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.yellow,
  fontSize: 32,
  height: 1,
);

TextStyle headingStyle = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.yellow,
  fontSize: 24,
  height: 1,
);
TextStyle headingStyle20 = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.yellow,
  fontSize: 20,
  height: 1,
);
TextStyle headingStyle20italic = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.italic,
  color: Colors.yellow,
  fontSize: 20,
  height: 1,
);

TextStyle headingStyleBlack = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 24,
  height: 1,
);
TextStyle headingStyle20Black = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 20,
  height: 1,
);
TextStyle headingStyle20italicBlack = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.italic,
  color: Colors.black,
  fontSize: 20,
  height: 1,
);

TextStyle headingStyleOnLightBg = TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.blue[800],
  fontSize: 24,
  height: 1,
);

TextStyle smallHeadingStyle = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.yellow,
  fontSize: 20,
  height: 1,
);

TextStyle buttonLabelStyleMedium = const TextStyle(
  fontFamily: 'AvenirNextMedium',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 16,
  height: 1,
);
TextStyle buttonLabelStyleSmallCompressedLines = const TextStyle(
  fontFamily: 'AvenirNextMedium',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 16,
  height: 0.8,
);
TextStyle buttonLabelStyleSmall = const TextStyle(
  fontFamily: 'AvenirNextMedium',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 14,
  height: 1,
);

TextStyle largeText = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 32,
  height: 1,
);

TextStyle buttonTextStyle = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.white,
  fontSize: 16,
  height: 1,
);

TextStyle smallContentStyleDb = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 20,
  height: 1,
);
TextStyle smallContentStyle = const TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 20,
  height: 1,
);

TextStyle footnoteSmall = TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.italic,
  color: Colors.grey[700],
  fontSize: 14,
  height: 1,
);
TextStyle footnoteSmallRed = TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.italic,
  color: Colors.red[900],
  fontSize: 14,
  height: 1,
);
TextStyle errorSmallRed = TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.italic,
  color: Colors.red[900],
  fontSize: 14,
  height: 1,
);
TextStyle footnoteSmallBlack = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.italic,
  color: Colors.black,
  fontSize: 14,
  height: 1,
);

TextStyle footnoteMedium = TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.italic,
  color: Colors.grey[700],
  fontSize: 16,
  height: 1,
);
TextStyle footnoteMediumRed = TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.italic,
  color: Colors.red[900],
  fontSize: 16,
  height: 1,
);
TextStyle footnoteMediumBlack = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.italic,
  color: Colors.black,
  fontSize: 16,
  height: 1,
);

TextStyle mediumText = TextStyle(
  fontFamily: 'AvenirNextRegular',
  fontStyle: FontStyle.normal,
  color: Colors.grey[700],
  fontSize: 16,
  height: 1,
);
TextStyle mediumTextRed = TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.red[900],
  fontSize: 16,
  height: 1,
);
TextStyle mediumTextBlack = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 16,
  height: 1,
);

TextStyle ts_alertDialogTitle = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 24,
  height: 1,
);

TextStyle ts_alertDialogBody = const TextStyle(
  fontFamily: 'AvenirNextMedium',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 18,
  height: 0.9,
);

TextStyle ts_alertDialogBodyMedium = const TextStyle(
  fontFamily: 'AvenirNextMedium',
  fontStyle: FontStyle.normal,
  color: Colors.black,
  fontSize: 16,
  height: 0.9,
);

TextStyle ts_button = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  fontSize: 20,
  color: Colors.white,
);

// Color brown = const Color.fromARGB(255, 107, 87, 66);
// Color purple = const Color.fromARGB(255, 61, 27, 142);
// Color yellow = const Color.fromARGB(255, 236, 212, 68);
// Color brickRed = const Color.fromARGB(255, 51, 0, 14);
// Color teal = const Color.fromARGB(255, 13, 115, 124);

// ignore: avoid_classes_with_only_static_members
class Backgrounds {
  static BoxDecoration defaultHcBackground() {
    return const BoxDecoration(
      image: DecorationImage(
        image: ExactAssetImage('images/backgrounds/hash_foot_background.png'),
        fit: BoxFit.cover,
      ),
    );
  }

  static BoxDecoration defaultHcBackgroundLight() {
    return const BoxDecoration(
      image: DecorationImage(
        image: ExactAssetImage(
          'images/backgrounds/hash_foot_background_light.png',
        ),
        fit: BoxFit.cover,
      ),
    );
  }
}
