import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/pages/menu_pages/my_profile_page.dart';
import 'package:harrier_central/pages/menu_pages/imprint_page.dart';
import 'package:harrier_central/pages/menu_pages/legal_page.dart';
import 'package:harrier_central/pages/menu_pages/faq_page.dart';
import 'package:harrier_central/pages/menu_pages/settings_page.dart';
import 'package:harrier_central/pages/menu_pages/in_app_purchase.dart';
import 'package:harrier_central/pages/menu_pages/user_feedback_page.dart';
import 'package:harrier_central/pages/menu_pages/privacy_policy_page.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({Key key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  DrawerMenuState createState() => DrawerMenuState();
}

class DrawerMenuState extends State<DrawerMenu> {
  void onTabTapped(EnumAppPages page) {
    Navigator.pop(context);
  }

  static const int opacity = 160;
  static const Color textColor = Color.fromARGB(opacity, 255, 255, 255);

  TextStyle style = const TextStyle(
      fontFamily: 'AvenirNext',
      fontStyle: FontStyle.normal,
      color: textColor,
      fontSize: 24.0,
      height: 1.0);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //elevation: 120,
      child: Stack(overflow: Overflow.clip, children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  // decoration: const BoxDecoration(
                  //   image: const DecorationImage(
                  //     fit: BoxFit.fill,
                  //     image: const AssetImage("images/other/drawer_image.jpg"),
                  //   ),
                  // ),
                  child: Image.asset('images/other/drawer_image.jpg',
                      fit: BoxFit.fill,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width),
                ),
              ],
            ),
          ),
        ),
        // IntrinsicHeight(child:Image.asset('images/other/drawer_image.jpg',height: 1000, width:800,),),
        Positioned(
          //top:50,
          //top:10,
          top: 40,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.settings, color: textColor),
                title: Text('Settings', style: style),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return SettingsPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: textColor),
                title: Text('My Profile', style: style),
                onTap: () async {
                  //onTabTapped(EnumAppPages.settings);
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return MyProfilePage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: textColor),
                title: Text('In App Purchases', style: style),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return InAppPurchasePage();
                      },
                    ),
                  );
                },
              ),
              // ListTile(
              //   leading:const  Icon(Icons.speaker_notes),
              //   title: const Text('Acknowledgements'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     onTabTapped(3);
              //   },
              // ),
              ListTile(
                leading:
                    const Icon(FontAwesome.question_circle, color: textColor),
                title: Text('FAQs', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return FaqPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback, color: textColor),
                title: Text('Your feedback', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return UserFeedbackPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.speaker_notes, color: textColor),
                title: Text('Imprint', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return ImprintPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(FontAwesome.legal, color: textColor),
                title: Text('Legal', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return LegalPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(MaterialCommunityIcons.shield_lock,
                    color: textColor),
                title: Text('Privacy Policy', style: style),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(
                      settings: RouteSettings(),
                      builder: (BuildContext context) {
                        return PrivacyPolicyPage();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// class ScaleRoute extends PageRouteBuilder<dynamic> {
//   final Widget widget;
//   ScaleRoute({this.widget})
//     : super(
//         pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
//           return widget;
//         },
//         transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {

//           return ScaleTransition(
//             scale: Tween<double>(
//               begin: 0.0,
//               end: 1.0,
//             ).animate(
//                 CurvedAnimation(
//                   parent: animation,
//                   curve: Interval(
//                     0.00,
//                     0.50,
//                     curve: Curves.linear,
//                   ),
//                 ),
//               ),
//             child: ScaleTransition(
//                      scale: Tween<double>(
//                        begin: 1.5,
//                        end: 1.0,
//                      ).animate(
//                        CurvedAnimation(
//                          parent: animation,
//                          curve: Interval(
//                            0.50,
//                            1.00,
//                            curve: Curves.linear,
//                          ),
//                        ),
//                      ),
//                      child: child,
//                    ),
//            );
//          }
//       );
// }
