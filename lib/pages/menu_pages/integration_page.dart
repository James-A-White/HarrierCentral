// // @dart=2.11
// import 'package:harrier_central/imports.dart';

// class IntegrationPage extends StatefulWidget {
//   //final FutureRunScopedModel futureRunsModel;

//   const IntegrationPage({Key key}) : super(key: key);

//   @override
//   IntegrationPageState createState() => IntegrationPageState();
// }

// class IntegrationPageState extends State<IntegrationPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: <Widget>[
//         Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
//         Positioned(
//           top: 0,
//           left: 0,
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           child: Scaffold(
//             appBar: AppBar(
//               centerTitle: true,
//               backgroundColor: themeAppBarBackground,
//               title: const Text(
//                 'Integration',
//                 style: TextStyle(
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             body: Container(
//               decoration: Backgrounds.defaultHcBackground(),
//               height: MediaQuery.of(context).size.height,
//               child: const IntegrationPageContent(),
//             ),
//           ),
//         ),
//         OfflineModeRibbon(
//           showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
//           lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
//           ribbonImage: 'images/icons/offline_mode.png',
//         ),
//       ],
//     );
//   }
// }

// class IntegrationPageContent extends StatefulWidget {
//   const IntegrationPageContent({Key key}) : super(key: key);

//   @override
//   _IntegrationPageContentState createState() => _IntegrationPageContentState();
// }

// class _IntegrationPageContentState extends State<IntegrationPageContent> {
//   TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.2);

//   TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.2);

//   bool _isFacebookAdmin = false;

//   String facebookAccessToken;

//   bool isLoggedIn = false;
//   bool showFacebookLoginButton = true;
//   dynamic profileData;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: G0<DeviceInfo>().deviceWidth,
//       child: Column(children: <Widget>[
//         Padding(
//           padding: const EdgeInsets.only(top: 40, bottom: 10, left: 20, right: 20),
//           child: Text(
//             'Facebook Integration',
//             style: headingStyle,
//             textAlign: TextAlign.center,
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(top: 20, bottom: 40, left: 20, right: 20),
//           child: Text(
//             'To enable automatic Facebook integration with Harrier Central at least one Facebook admin from each Kennel must be logged into Facebook using the Harrier Central App.\r\n\r\nIf you are not yet logged into Facebook and you are a Facebook admin for your Kennel, you can login from this page.',
//             style: bodyStyle,
//             textAlign: TextAlign.center,
//           ),
//         ),
//         FancyDivider(
//           key: UniqueKey(),
//           innerColor: Colors.white,
//           topMargin: 10.0,
//           bottomMargin: 20.0,
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Container(
//               margin: const EdgeInsets.only(right: 10),
//               height: 25,
//               width: 25,
//               //color: Colors.yellow[100],
//               child: Checkbox(
//                 fillColor: MaterialStateProperty.resolveWith<Color>(
//                   (Set<MaterialState> states) {
//                     if (!states.contains(MaterialState.selected)) {
//                       return Colors.white;
//                     }
//                     return null; // Use the component's default.
//                   },
//                 ),
//                 value: _isFacebookAdmin,
//                 onChanged: (bool value) {
//                   setState(() {
//                     _isFacebookAdmin = value;
//                     // checkDirty();
//                   });
//                 },
//               ),
//             ),
//             Text(
//               'I am a Facebook group admin',
//               style: bodyStyle,
//               textAlign: TextAlign.center,
//             ),
//             GestureDetector(
//               onTap: () {
//                 IveCoreUtilities.showAlert(
//                     context,
//                     'Why login with Facebook?',
//                     'In order for the Harrier Central server to automatically receive events from groups on Facebook at least one Facebook user with admin permissions on the group must be logged in using the Harrier Central app.\r\n\r\nWhen you login to Facebook using this page, Harrier Central receives credentials that enable our server to access runs from your group.',
//                     'OK');
//               },
//               child: Container(
//                 padding: const EdgeInsets.only(left: 20),
//                 height: 26,
//                 child: Image.asset('images/icons/more_info_button.png'),
//               ),
//             )
//           ],
//         ),
//         isLoggedIn
//             ? Column(children: <Widget>[
//                 Padding(
//                   padding: const EdgeInsets.only(top: 25.0, bottom: 15.0),
//                   child: Text('Logged in as:', textAlign: TextAlign.center, style: smallTitleStyle),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 15.0),
//                   child: Text(profileData['name'], textAlign: TextAlign.center, style: largeTitleStyle),
//                 ),
//               ])
//             : GestureDetector(
//                 onTap: () {
//                   if (_isFacebookAdmin) {
//                     setState(() {
//                       showFacebookLoginButton = false;
//                     });
//                     _login();
//                   }
//                 },
//                 child: showFacebookLoginButton
//                     ? Image(
//                         image: _isFacebookAdmin ? const AssetImage('images/init/facebook_login.png') : const AssetImage('images/init/facebook_login_disabled.png'),
//                       )
//                     : Padding(
//                         padding: const EdgeInsets.only(top: 30),
//                         child: Text(
//                           'Please wait for Facebook login',
//                           style: headingStyle,
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//               ),
//       ]),
//     );
//   }

//   Future<void> _login() async {
//     try {
//       // by default the login method has the next permissions ['email','public_profile']
//       final AccessToken accessToken = await FacebookAuth.instance.login();

//       // get the user data
//       final Map<String, dynamic> userData = await FacebookAuth.instance.getUserData(fields: 'name,picture.width(300),email,birthday,gender,link,first_name,last_name');

//       await setStringPref(StringPrefsEnum.facebookId, accessToken.userId);
//       await setStringPref(StringPrefsEnum.facebookAccessToken, facebookAccessToken);
//       await setDatePref(DatePrefsEnum.lastFbTokenUpdate, DateTime.now());

//       onLoginStatusChanged(true, profData: userData, accessToken: accessToken.token);
//     } on FacebookAuthException catch (e) {
//       switch (e.errorCode) {
//         case FacebookAuthErrorCode.OPERATION_IN_PROGRESS:
//           print('You have a previous login operation in progress');
//           break;
//         case FacebookAuthErrorCode.CANCELLED:
//           print('login cancelled');
//           break;
//         case FacebookAuthErrorCode.FAILED:
//           print('login failed');
//           break;
//       }
//     }
//   }

//   Future<void> onLoginStatusChanged(bool loggedIn, {dynamic profData, String accessToken}) async {
//     setState(() {
//       isLoggedIn = loggedIn;
//       profileData = profData;
//       facebookAccessToken = accessToken;
//     });

//     final HashersService hSrv = HashersService();
//     final String responseBody = await hSrv.processThirdPartyLogin(
//         firstName: profileData['first_name'],
//         lastName: profileData['last_name'],
//         email: profileData['email'],
//         hashName: '',
//         photo: profileData['picture']['data']['url'],
//         facebookId: profileData['id'],
//         facebookAccessToken: facebookAccessToken,
//         includeInGlobalHashDirectory: -1);

//     if (!responseBody.startsWith(ERROR_PREFIX)) {
//       final dynamic result = json.decode(responseBody);

//       setStringPref(StringPrefsEnum.profilePhotoUrl, result[0]['photo']);
//       setStringPref(StringPrefsEnum.displayName, result[0]['displayName']);
//       setStringPref(StringPrefsEnum.email, result[0]['email']);
//       setStringPref(StringPrefsEnum.facebookId, result[0]['facebookId']);
//       setStringPref(StringPrefsEnum.firstName, result[0]['firstName']);
//       setStringPref(StringPrefsEnum.hashName, result[0]['hashName']);
//       setStringPref(StringPrefsEnum.lastName, result[0]['lastName']);
//       setStringPref(StringPrefsEnum.qrCode, result[0]['qrCode']);
//       setStringPref(StringPrefsEnum.supportCode, result[0]['supportCode']);
//       setStringPref(StringPrefsEnum.resetCode, result[0]['resetCode']);
//       setStringPref(StringPrefsEnum.qrSecretCode, result[0]['qrSecretCode']);
//       setStringPref(StringPrefsEnum.userId, result[0]['hasherId']);
//       final int preferences = int.tryParse(result[0]['preferences']) ?? 0;
//       await setIntPref(IntPrefsEnum.hasherPreferences, preferences);
//     } else {
//       IveCoreUtilities.showAlert(
//           context,
//           'Problem saving Facebook data',
//           'There was a problem saving your Facebook infomration to Harrier Central.\r\n\r\nPlease try again later or let us know by contacting us at connect@harriercentral.com. Sorry for the inconvenience!',
//           'OK');
//     }
//   }
// }
