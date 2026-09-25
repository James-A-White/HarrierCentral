import 'package:harrier_central/imports.dart';
import 'package:pdfx/pdfx.dart';

class PrivacyPolicyPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const PrivacyPolicyPage({super.key});

  @override
  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

class PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String pathPDF = '';

  @override
  void initState() {
    super.initState();
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
                        // White on the red button, never the heading yellow.
                        style: ts_headingLarge.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
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
                        'The Harrier Central Privacy Policy can also be found on our website for easier reading: \r\n\r\nhttps://www.harriercentral.com/index.php/privacy-policy/',
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
            setStateIfMounted(() {});
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
