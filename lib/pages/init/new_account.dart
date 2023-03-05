// @dart=2.11
import 'package:harrier_central/imports.dart';

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
        SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
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
                'Setup Harrier Central',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: const NewAccountPageContent(),
            ),
          ),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }
}

class NewAccountPageContent extends StatefulWidget {
  const NewAccountPageContent({Key key}) : super(key: key);

  @override
  NewAccountPageContentState createState() => NewAccountPageContentState();
}

class NewAccountPageContentState extends State<NewAccountPageContent> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      num newFontSize = smallTitleStyle.fontSize * G0<DeviceInfo>().deviceWidthScaleFactor;
      final TextStyle localTitleStyle = smallTitleStyle.copyWith(fontSize: newFontSize, color: Colors.black);

      newFontSize = bodyStyleSc.fontSize * G0<DeviceInfo>().deviceWidthScaleFactor;
      final TextStyle localBodyStyle = bodyStyleSc.copyWith(fontSize: newFontSize, color: Colors.black);

      newFontSize = headingStyle.fontSize * G0<DeviceInfo>().deviceWidthScaleFactor;
      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

      return Container(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                'Select an option to configure Harrier Central',
                style: localHeadingStyle,
                textAlign: TextAlign.center,
              ),

              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement<dynamic, dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(builder: (BuildContext context) => const CreateNewAccountPage()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(5.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.red.shade900,
                      width: 2, //                   <--- border width here
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Image(
                        width: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
                        height: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
                        fit: BoxFit.fill,
                        image: const AssetImage('images/icons/pencil.png'),
                      ),
                      const SizedBox(height: 1, width: 10),
                      Expanded(
                        child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text('Create New Account', style: localTitleStyle),
                          Text(
                            'Provide information to create a new Harrier Central account if you are not already in the system',
                            style: localBodyStyle.copyWith(fontSize: 16.0),
                            //softWrap: true,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(builder: (BuildContext context) => const UseInviteCodePage()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(5.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.red.shade900,
                      width: 2, //                   <--- border width here
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Image(
                        width: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
                        height: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
                        fit: BoxFit.fill,
                        image: const AssetImage('images/icons/inviteCode.png'),
                      ),
                      const SizedBox(height: 1, width: 10),
                      Expanded(
                        child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text('Connect to Existing Account', style: localTitleStyle),
                          Text(
                            'Did your Kennel set up an account for you or have you reinstalled Harrier Central? If so click here to use an Invite Code to connect to your existing account.',
                            style: localBodyStyle.copyWith(fontSize: 16.0),
                            //softWrap: true,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement<dynamic, dynamic>(
                    context,
                    MaterialPageRoute<dynamic>(builder: (BuildContext context) => const ThirdPartyLogin(true)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(5.0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.red.shade900,
                      width: 2, //                   <--- border width here
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Image(
                        width: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
                        height: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
                        fit: BoxFit.fill,
                        image: const AssetImage('images/init/3rd_party.png'),
                      ),
                      const SizedBox(height: 1, width: 10),
                      Expanded(
                        child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text('Use Third Party', style: localTitleStyle),
                          Text(
                            'Create a new Harrier Central account or connect to your existing account using a third-party login provider such as Apple or Facebook',
                            style: localBodyStyle.copyWith(fontSize: 16.0),
                            //softWrap: true,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              // IveCoreUtilities.styleForDisabled(
              //     Container(
              //       padding: const EdgeInsets.all(10),
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(20.0),
              //         color: Colors.white,
              //         border: Border.all(
              //           color: Colors.red.shade900,
              //           width: 2, //                   <--- border width here
              //         ),
              //       ),
              //       child: Row(
              //         children: <Widget>[
              //           Image(
              //             width: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
              //             height: PROFILE_PIC_SIZE2 * G0<DeviceInfo>().deviceWidthScaleFactor,
              //             fit: BoxFit.fill,
              //             image: const AssetImage('images/icons/qrPhone.png'),
              //           ),
              //           const SizedBox(height: 1, width: 10),
              //           Expanded(
              //             child:
              //                 Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              //               Text('Transfer app', style: localTitleStyle),
              //               Text(
              //                 'Use a QR code to transfer your Harrier Central account to this phone from another phone',
              //                 style: localBodyStyle,
              //                 //softWrap: true,
              //               ),
              //             ]),
              //           ),
              //         ],
              //       ),
              //     ),
              //     borderRadius: 20.0),
            ],
          ),
        ),
      );
    });
  }
}
