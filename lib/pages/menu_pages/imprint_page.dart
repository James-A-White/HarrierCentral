// @dart=2.11
import 'package:harrier_central/imports.dart';

class ImprintPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const ImprintPage({Key key}) : super(key: key);

  @override
  ImprintPageState createState() => ImprintPageState();
}

class ImprintPageState extends State<ImprintPage> {
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
                'Imprint',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.of(context).size.height,
              child: const ImprintPageContent(),
            ),
          ),
        ),
        OfflineModeRibbon(
          showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
          ribbonImage: 'images/icons/offline_mode.png',
        ),
      ],
    );
  }
}

class ImprintPageContent extends StatefulWidget {
  const ImprintPageContent({Key key}) : super(key: key);

  @override
  _ImprintPageContentState createState() => _ImprintPageContentState();
}

class _ImprintPageContentState extends State<ImprintPageContent> {
  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.2);

  TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.2);

  String appName;
  String packageName;
  String version;
  String buildNumber;

  @override
  Widget build(BuildContext context) {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    });

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              //minHeight: viewportConstraints.maxHeight,
              ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Software version:', style: headingStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Name: $appName\r\nVersion: $version\r\nBuild number: $buildNumber\r\nDatabase version: ${DB_VERSION.toString()}', style: bodyStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('\r\nImprint:', style: headingStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Harrier Central\r\n\r\nInnoVet Europe\r\nFluwelen Burgwal 58\r\n2511 CJ, Den Haag\r\nNetherlands\r\n\r\nKvK number: 68759207\r\nVAT #: NL002452779B31',
                          style: bodyStyle),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text('\r\nContact:', style: headingStyle),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('connect@harriercentral.com', style: bodyStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('\r\nCopyright:', style: headingStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('© 2020, InnoVet Europe\r\nAll rights reserved', style: bodyStyle),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('\r\nTechnical data:', style: headingStyle),
                    ],
                  ),
                  Text(
                      'The Harrier Central service is hosted in Microsoft Azure data centers in The Netherlands and Ireland. The mobile app for iOS and Android is written in Google Flutter and the back-end services are composed in Microsoft SQL Azure and Microsoft ASP.NET.',
                      style: bodyStyle),
                  Container(width: 40, height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
