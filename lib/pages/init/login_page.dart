
// import 'dart:core';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import 'package:harrier_central/widgets/new_user.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({Key key}) : super(key: key);

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage>
//     with SingleTickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       body: NotificationListener<OverscrollIndicatorNotification>(
//         onNotification: (OverscrollIndicatorNotification overscroll) {
//           overscroll.disallowGlow();
// TODO(James): What shoudl the return type really be?
//           return true; 
//         },
//         child: NewUserWidget(scaffoldKey: _scaffoldKey),
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();

//     // signupFirstNameController.text = 'delete';
//     // signupLastNameController.text = 'delete';
//     // signupHashNameController.text = 'delete';
//     // signupEmailController.text =
//     //     'delete_' + Random.secure().nextInt(99999999).toString() + '@test.com';

//     SystemChrome.setPreferredOrientations(<DeviceOrientation>[
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);

//   }

// }
