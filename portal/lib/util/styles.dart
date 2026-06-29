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

// ═══════════════════════════════════════════════════════════════════════════
// PORTAL BUTTON SYSTEM — single source of truth.
// Roles: primary / secondary / destructive / text / outlined (+ IconButton).
// Every FILLED role shares geometry & typography; only the colour differs.
// Prefer the `HcButton` widget (widgets/hc_button.dart); these ButtonStyles
// back it and the app theme. See docs/portal_button_strategy.md.
// ═══════════════════════════════════════════════════════════════════════════

class HcButtonTokens {
  const HcButtonTokens._();
  static const double radius = 8;
  static const double minHeight = 44;
  static const double minWidth = 88;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(vertical: 12, horizontal: 20);
  static const TextStyle textStyle = TextStyle(
    fontFamily: 'AvenirNextDemiBold',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  // Role colours
  static const Color primary = Color(0xFFC62828); // red 800 — active action
  static const Color secondary = Color(0xFF546E7A); // blueGrey 600 — cancel
  static const Color navigation = Color(0xFF1E88E5); // blue 600 — next/back
  static const Color destructive = Color(0xFFB71C1C); // red 900
  static const Color disabled = Color(0xFFBDBDBD); // grey 400
  static const Color onFilled = Colors.white;
}

/// Filled-button style for a given background (primary/secondary/destructive).
ButtonStyle hcFilledButtonStyle(Color background) => ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: HcButtonTokens.onFilled,
      disabledBackgroundColor: HcButtonTokens.disabled,
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(HcButtonTokens.minWidth, HcButtonTokens.minHeight),
      padding: HcButtonTokens.padding,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HcButtonTokens.radius)),
      textStyle: HcButtonTokens.textStyle,
    );

ButtonStyle get hcPrimaryButtonStyle =>
    hcFilledButtonStyle(HcButtonTokens.primary);
ButtonStyle get hcSecondaryButtonStyle =>
    hcFilledButtonStyle(HcButtonTokens.secondary);
ButtonStyle get hcNavigationButtonStyle =>
    hcFilledButtonStyle(HcButtonTokens.navigation);
ButtonStyle get hcDestructiveButtonStyle =>
    hcFilledButtonStyle(HcButtonTokens.destructive);

/// Low-emphasis flat text button (links / tertiary). No background.
ButtonStyle get hcTextButtonStyle => TextButton.styleFrom(
      foregroundColor: HcButtonTokens.primary,
      minimumSize: const Size(0, HcButtonTokens.minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: HcButtonTokens.textStyle,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HcButtonTokens.radius)),
    );

/// Outlined secondary (in-page alternative to the filled secondary).
ButtonStyle get hcOutlinedButtonStyle => OutlinedButton.styleFrom(
      foregroundColor: HcButtonTokens.secondary,
      side: const BorderSide(color: HcButtonTokens.secondary),
      minimumSize: const Size(HcButtonTokens.minWidth, HcButtonTokens.minHeight),
      padding: HcButtonTokens.padding,
      textStyle: HcButtonTokens.textStyle,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HcButtonTokens.radius)),
    );

// ── Legacy aliases (existing call sites converge automatically) ──────────────
// `defaultButtonStyle` is the primary style; `hcDialogButtonStyle(colour)` is
// the filled style. Prefer HcButton / the named styles above in new code.
ButtonStyle get defaultButtonStyle => hcPrimaryButtonStyle;
ButtonStyle hcDialogButtonStyle(Color background) =>
    hcFilledButtonStyle(background);
const Color hcDialogPrimaryColor = HcButtonTokens.primary;
const Color hcDialogCancelColor = HcButtonTokens.secondary;

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

// Button label text — aligned to the button system (16 DemiBold). Call sites
// that pass this to a button child now match HcButtonTokens.textStyle.
TextStyle textStyleButton = const TextStyle(
  fontFamily: 'AvenirNextDemiBold',
  fontStyle: FontStyle.normal,
  fontSize: 16,
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
