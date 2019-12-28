import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info/package_info.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/widgets/offline_mode_ribbon.dart';

class NewAccountPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const NewAccountPage({Key key}) : super(key: key);

  @override
  NewAccountPageState createState() => NewAccountPageState();
}

class NewAccountPageState extends State<NewAccountPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              title: const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height,
              child: const NewAccountPageContent(),
            ),
          ),
        ),
        const OfflineModeRibbon(),
      ],
    );
  }
}

class NewAccountPageContent extends StatefulWidget {
  const NewAccountPageContent({Key key}) : super(key: key);

  @override
  _NewAccountPageContentState createState() => _NewAccountPageContentState();
}

class _NewAccountPageContentState extends State<NewAccountPageContent> {


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      num newFontSize = smallTitleStyle.fontSize * deviceWidthScaleFactor;
      final TextStyle localTitleStyle = smallTitleStyle.copyWith(fontSize: newFontSize, color: Colors.black);
      newFontSize = bodyStyleSc.fontSize * deviceWidthScaleFactor;
      final TextStyle localBodyStyle = bodyStyleSc.copyWith(fontSize: newFontSize, color: Colors.black);
      newFontSize = headingStyle.fontSize * deviceWidthScaleFactor;

      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize,);

      return 
      Container(
        padding: EdgeInsets.all(15),
      child:Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,

        children: <Widget>[
          const SizedBox(height: 20,width: 20),
          Text('Select an option',style: localHeadingStyle),
          const SizedBox(height: 20,width: 20),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).accentColor,
                width: 2, //                   <--- border width here
              ),
            ),
            child: Row(
              children: <Widget>[
                Image(
                  width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  fit: BoxFit.fill,
                  image: const AssetImage('images/avatars/avatar-2.png'),
                ),
                const SizedBox(height: 1, width: 10),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Text('Use Invite Code', style: localTitleStyle),
                    Text(
                      'Use the invite code provided by your kennel to create or reconnect to your Harrier Central account',
                      style: localBodyStyle,
                      //softWrap: true,
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20,width: 20),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).accentColor,
                width: 2, //                   <--- border width here
              ),
            ),
            child: Row(
              children: <Widget>[
                Image(
                  width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  fit: BoxFit.fill,
                  image: const AssetImage('images/avatars/avatar-2.png'),
                ),
                const SizedBox(height: 1, width: 10),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Text('Use Facebook', style: localTitleStyle),
                    Text(
                      'Create a new Harrier Central account or connect to your existing account using your Facebook login',
                      style: localBodyStyle,
                      //softWrap: true,
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20,width: 20),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).accentColor,
                width: 2, //                   <--- border width here
              ),
            ),
            child: Row(
              children: <Widget>[
                Image(
                  width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  fit: BoxFit.fill,
                  image: const AssetImage('images/avatars/avatar-2.png'),
                ),
                const SizedBox(height: 1, width: 10),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Text('Transfer app', style: localTitleStyle),
                    Text(
                      'Use a QR code to transfer your Harrier Central account to this phone from another phone',
                      style: localBodyStyle,
                      //softWrap: true,
                    ),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20,width: 20),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).accentColor,
                width: 2, //                   <--- border width here
              ),
            ),
            child: Row(
              children: <Widget>[
                Image(
                  width: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  height: PROFILE_PIC_SIZE2 * deviceWidthScaleFactor,
                  fit: BoxFit.fill,
                  image: const AssetImage('images/avatars/avatar-2.png'),
                ),
                const SizedBox(height: 1, width: 10),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Text('Create New Account', style: localTitleStyle),
                    Text(
                      'Provide information to create a new Harrier Central account if you are not already in the system',
                      style: localBodyStyle,
                      //softWrap: true,
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
      );
    });
  }
}
