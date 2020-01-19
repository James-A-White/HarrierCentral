// import 'dart:convert';
// import 'dart:core';
// import 'dart:math';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';

// import 'package:harrier_central/util/styles.dart';
// import 'package:harrier_central/util/globals.dart';
// import 'package:harrier_central/util/constants.dart';
// import 'package:harrier_central/widgets/offline_mode_ribbon.dart';
// import 'package:harrier_central/util/utilities.dart';
// import 'package:harrier_central/util/preferences.dart';
// import 'package:harrier_central/widgets/user_details_ui.dart';
// import 'package:harrier_central/data/hc3_services/hashers_service.dart';
// import 'package:harrier_central/pages/init/choose_profile_image.dart';

// class LoginWithFacebookPage extends StatefulWidget {

//   const LoginWithFacebookPage({Key key}) : super(key: key);

//   @override
//   LoginWithFacebookPageState createState() => LoginWithFacebookPageState();
// }

// class LoginWithFacebookPageState extends State<LoginWithFacebookPage> {
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
//                 'Login with Facebook',
//                 style: TextStyle(
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             body: Container(
//               decoration: Backgrounds.defaultHcBackground(),
//               height: MediaQuery.of(context).size.height,
//               width: MediaQuery.of(context).size.width,
//               child: const LoginWithFacebookPageContent(),
//             ),
//           ),
//         ),
//         const OfflineModeRibbon(),
//       ],
//     );
//   }
// }

// class LoginWithFacebookPageContent extends StatefulWidget {
//   const LoginWithFacebookPageContent({Key key}) : super(key: key);

//   @override
//   _LoginWithFacebookPageContentState createState() => _LoginWithFacebookPageContentState();
// }

// class _LoginWithFacebookPageContentState extends State<LoginWithFacebookPageContent> {
//   TextEditingController inviteCodeTextController;
//   InputDecoration inviteCodeDecoration;
//   final FocusNode inviteCodeFocusNode = FocusNode();

//   //final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool isLoading = false;

//   bool includeInGlobalHashDirectory = true;

//   @override
//   void initState() {
//     super.initState();
//   }

//   UserDetailsUi userDetailsUi;

//   @override
//   Widget build(BuildContext context) {
//     userDetailsUi ??= UserDetailsUi(
//       firstName: '',
//       lastName: '',
//       email: '',
//       hashName: '',
//     );
//     return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
//       final num newFontSize = headingStyle.fontSize * deviceWidthScaleFactor;

//       final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

//       return SingleChildScrollView(
//         child: Container(
//           padding: const EdgeInsets.all(15),
//           child: Column(
//             mainAxisSize: MainAxisSize.max,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   //SizedBox(width: 46,height: 10,),
//                   Text(
//                     'Click below to\r\nLogin with Facebook',
//                     style: localHeadingStyle,
//                     textAlign: TextAlign.center,
//                   ),
//                   // GestureDetector(
//                   //   onTap: () {
//                   //     Utilities.showAlert(
//                   //         context,
//                   //         'What is an "Invite Code"?',
//                   //         'An Invite Code is a six character code that allows you to connect to an existing account in Harrier Central.\r\n\r\nTypically you will receive an invite code from your home Kennel when they have already created an account for you in order to track your run counts.\r\n\r\nIf you do not have an Invite Code, please go back to the previous screen and select the option to Create a New Account.',
//                   //         'OK');
//                   //   },
//                   //   child: Container(
//                   //     padding: const EdgeInsets.only(left: 20),
//                   //     height: 26,
//                   //     child: Image.asset('images/icons/more_info_button.png'),
//                   //   ),
//                   // ),
//                 ],
//               ),
//               const SizedBox(
//                 height: 30,
//                 width: 30,
//               ),
//               Container(
//                 margin: const EdgeInsets.only(left: 15, right: 15),
//                 padding: const EdgeInsets.all(10),
//                 color: Colors.yellow[100],
//                 child: Column(
//                   children: <Widget>[
//                     userDetailsUi,
//                     const SizedBox(
//                       height: 30,
//                       width: 30,
//                     ),
//                     Row(
//                       children: <Widget>[
//                         Container(
//                           margin: const EdgeInsets.only(right: 10),
//                           height: 25,
//                           width: 25,
//                           color: Colors.yellow[100],
//                           child: Checkbox(
//                             value: includeInGlobalHashDirectory,
//                             onChanged: (bool value) {
//                               setState(() {
//                                 includeInGlobalHashDirectory = value;
//                               });
//                             },
//                           ),
//                         ),
//                         const Expanded(
//                           child: Text(
//                             'Include me in Global Hash Directory',
//                             //style: headingStyle,
//                             textAlign: TextAlign.center,
//                             maxLines: 2,
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             Utilities.showAlert(
//                                 context,
//                                 'What is the Global Hash Directory?',
//                                 'The Global Hash Directory is a list of all Hashers who use Harrier Central and "opt-in" to be included in the list.\r\n\r\nWhen you select to be included in the Directory your name, home Kennel and any mismanagement roles you have will be publicly available.\r\n\r\nYou may also use Harrier Central to send short email messages to anyone else in the Directory without sharing your e-mail address.',
//                                 'OK');
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.only(left: 20),
//                             height: 26,
//                             child: Image.asset('images/icons/more_info_button.png'),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8, width: 10),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 35, width: 10),
//               FlatButton(
//                 color: Theme.of(context).accentColor,
//                 child: const Text('Get Started!'),
//                 textColor: Colors.white,
//                 onPressed: () {
//                   if (userDetailsUi.validateForm()) {
//                     // If the form is valid, display a snackbar. In the real world,
//                     // you'd often call a server or save the information in a database.
//                     isLoading = true;

//                     setStringPref(StringPrefsEnum.firstName, userDetailsUi.firstName);
//                     setStringPref(StringPrefsEnum.lastName, userDetailsUi.lastName);
//                     setStringPref(StringPrefsEnum.email, userDetailsUi.email);
//                     setStringPref(StringPrefsEnum.hashName, userDetailsUi.hashName);

//                     final HashersService srv = HashersService();

//                     final String profilePhotoUrl = 'bundle://avatar-' + (Random.secure().nextInt(49) + 1).toString();

//                     final Future<String> apiCall =
//                         srv.addEditUser(targetUserId: GUID_EMPTY, firstName: userDetailsUi.firstName, lastName: userDetailsUi.lastName, email: userDetailsUi.email, hashName: userDetailsUi.hashName, photo: profilePhotoUrl, includeInGlobalHashDirectory: includeInGlobalHashDirectory ? 1 : 0);

//                     apiCall.then((String responseBody) async {
//                       bool isSuccessfulLoad = false;

//                       final List<dynamic> jsonResultSets = json.decode(responseBody);
//                       if (jsonResultSets.isNotEmpty) {
//                         final List<dynamic> subSet = jsonResultSets[0];
//                         if (subSet.isNotEmpty) {
//                           final Map<String, dynamic> result = subSet[0];
//                           if (result.isNotEmpty) {
//                             setStringPref(StringPrefsEnum.profilePhotoUrl, result['photo']);
//                             setStringPref(StringPrefsEnum.displayName, result['displayName']);
//                             setStringPref(StringPrefsEnum.email, result['email']);
//                             setStringPref(StringPrefsEnum.facebookId, result['facebookId']);
//                             setStringPref(StringPrefsEnum.firstName, result['firstName']);
//                             setStringPref(StringPrefsEnum.hashName, result['hashName']);
//                             setStringPref(StringPrefsEnum.lastName, result['lastName']);
//                             setStringPref(StringPrefsEnum.qrCode, result['qrCode']);
//                             setStringPref(StringPrefsEnum.supportCode, result['supportCode']);
//                             setStringPref(StringPrefsEnum.resetCode, result['resetCode']);
//                             setStringPref(StringPrefsEnum.qrSecretCode, result['qrSecretCode']);
//                             setStringPref(StringPrefsEnum.userId, result['hasherId']);

//                             isSuccessfulLoad = true;

//                             Navigator.pushReplacement<dynamic, dynamic>(
//                                 context,
//                                 MaterialPageRoute<dynamic>(
//                                   builder: (BuildContext context) => ChooseProfileImage(
//                                     isForThisDevice: true,
//                                     fileNamePrefix: getStringPref(StringPrefsEnum.supportCode),
//                                     currentProfileImage: getStringPref(StringPrefsEnum.profilePhotoUrl),
//                                     popToCaller: false,
//                                   ),
//                                 ));
//                           }
//                         }
//                       }
//                       if (!isSuccessfulLoad) {
//                         Utilities.showAlert(context, 'Account not created', 'There was a problem creating your account. Please delete the app and try again later or contact us at connect@harriercentral.com.\r\n\r\nSorry for the inconvenience!', 'OK');
//                         print(jsonResultSets.length);
//                       }
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 50, width: 10),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }
