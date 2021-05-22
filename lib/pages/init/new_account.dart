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
          lastSync: SecurePrefs.getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
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
      final TextStyle localHeadingStyle = headingStyle.copyWith(fontSize: newFontSize, height: 1.2);

      return Container(
        padding: const EdgeInsets.all(15),
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
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(builder: (BuildContext context) => const UseInviteCodePage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
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
                      image: const AssetImage('images/icons/inviteCode.png'),
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
            ),
            GestureDetector(
              onTap: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(builder: (BuildContext context) => FbLoginPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
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
                      image: const AssetImage('images/icons/facebookLogoCircle.png'),
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
            ),
            IveCoreUtilities.styleForDisabled(
                Container(
                  padding: const EdgeInsets.all(10),
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
                        image: const AssetImage('images/icons/qrPhone.png'),
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
                borderRadius: 20.0),
            GestureDetector(
              onTap: () {
                Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute<dynamic>(builder: (BuildContext context) => const CreateNewAccountPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
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
                      image: const AssetImage('images/icons/pencil.png'),
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
            ),
          ],
        ),
      );
    });
  }
}
