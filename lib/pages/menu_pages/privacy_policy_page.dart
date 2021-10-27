// @dart=2.11
import 'package:harrier_central/imports.dart';

class PrivacyPolicyPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const PrivacyPolicyPage({Key key}) : super(key: key);

  @override
  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

Future<File> createFileOfPdfUrl() async {
  final ByteData bytes = await rootBundle.load('assets/documents/privacy_policy.pdf');
  final String dir = (await getApplicationDocumentsDirectory()).path;
  final File file = File('$dir/privacy_policy_internal.pdf');
  await file.writeAsBytes(bytes.buffer.asInt8List());
  return file;
}

class PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String pathPDF = '';

  @override
  void initState() {
    super.initState();
    createFileOfPdfUrl().then((File f) {
      setState(() {
        pathPDF = f.path;
        //print(pathPDF);
      });
    });
  }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.0);

  TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 18.0, height: 1.0);

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
              title: const Text('Privacy Policy'),
              backgroundColor: themeAppBarBackground,
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      child: Text('Open Privacy Policy', style: headingStyle),
                      onPressed: () => Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(builder: (BuildContext context) => PDFScreen(pathPDF)),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(30),
                      child: Text('The Harrier Central Privacy Policy can also be found on our website for easier reading: \r\n\r\nhttp://www.harriercentral.com',
                          textAlign: TextAlign.center, style: bodyStyle),
                    ),
                  ],
                ),
              ),
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

class PDFScreen extends StatelessWidget {
  const PDFScreen(this.pathPDF, {Key key}) : super(key: key);

  final String pathPDF;

  @override
  Widget build(BuildContext context) {
    //return Container();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: themeAppBarBackground,
      ),
      body: PdfView(path: pathPDF),
    );
  }
}
