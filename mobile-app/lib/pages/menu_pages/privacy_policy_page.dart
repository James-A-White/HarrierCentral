import 'package:harrier_central/imports.dart';
import 'package:pdfx/pdfx.dart';

class PrivacyPolicyPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const PrivacyPolicyPage({super.key});

  @override
  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

// Future<File> createFileOfPdfUrl() async {
//   final ByteData bytes =
//       await rootBundle.load('assets/documents/privacy_policy.pdf');
//   final String dir = (await getApplicationDocumentsDirectory()).path;
//   final File file = File('$dir/privacy_policy_internal.pdf');
//   await file.writeAsBytes(bytes.buffer.asInt8List());
//   return file;
// }

class PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String pathPDF = '';

  @override
  void initState() {
    super.initState();
    // createFileOfPdfUrl().then((File f) {
    //   setState(() {
    //     pathPDF = f.path;
    //   });
    // });
  }

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
              title: Text('Privacy Policy', style: ts_appBarTitle),
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      child: Text(
                        'Open Privacy Policy',
                        style: ts_headingLarge,
                      ),
                      onPressed: () => Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => PDFScreen(pathPDF),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(30),
                      child: Text(
                        'The Harrier Central Privacy Policy can also be found on our website for easier reading: \r\n\r\nhttp://www.harriercentral.com',
                        textAlign: TextAlign.center,
                        style: ts_medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        OfflineModeRibbon(
          lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSync),
          ribbonImage: 'images/icons/offline_mode.png',
          refreshFunction: () {
            setState(() {});
          },
        ),
      ],
    );
  }
}

class PDFScreen extends StatelessWidget {
  PDFScreen(this.pathPDF, {super.key});

  final String pathPDF;

  final pdfPinchController = PdfControllerPinch(
    document: PdfDocument.openAsset('assets/documents/privacy_policy.pdf'),
  );

  @override
  Widget build(BuildContext context) {
    //return Container();
    return AppScaffold(
      appBar: AppBar(
        title: Text('Privacy Policy', style: ts_appBarTitle),
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
      ),
      body: PdfViewPinch(controller: pdfPinchController),
    );
  }
}
