import 'package:harrier_central/imports.dart';

class ImprintPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const ImprintPage({super.key});

  @override
  ImprintPageState createState() => ImprintPageState();
}

class ImprintPageState extends State<ImprintPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: AppScaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
              title: Text('Imprint', style: ts_appBarTitle),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              height: MediaQuery.sizeOf(context).height,
              child: const ImprintPageContent(),
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setStateIfMounted(() {});
          },
        ),
      ],
    );
  }
}

class ImprintPageContent extends StatefulWidget {
  const ImprintPageContent({super.key});

  @override
  ImprintPageContentState createState() => ImprintPageContentState();
}

class ImprintPageContentState extends State<ImprintPageContent> {
  String appName = '';
  String packageName = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    unawaited(loadPackageInfo());
  }

  Future<void> loadPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    setStateIfMounted(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
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
                        Text('Software version:', style: ts_headingLarge),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Name: $appName\r\nVersion: $version\r\nBuild number: $buildNumber\r\nDatabase version: ${DB_VERSION.toString()}',
                          style: ts_regular,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text('\r\nImprint:', style: ts_headingLarge),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Harrier Central\r\n\r\nMelissa and James White\r\nTuna Melt and Opee\r\n\r\nLondon, England',
                          style: ts_regular,
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text('\r\nContact:', style: ts_headingLarge),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text('harriercentral@gmail.com', style: ts_regular),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text('\r\nCopyright:', style: ts_headingLarge),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '© ${DateTime.now().year}, Melissa and James White\r\nAll rights reserved',
                          style: ts_regular,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text('\r\nTechnical data:', style: ts_headingLarge),
                      ],
                    ),
                    Text(
                      'The Harrier Central service is hosted in Microsoft Azure data centers in The Netherlands and Ireland. The mobile app for iOS and Android is written in Google Flutter and the back-end services are composed in Microsoft SQL Azure and Microsoft ASP.NET.',
                      style: ts_regular,
                    ),
                    const SizedBox(width: 40, height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
