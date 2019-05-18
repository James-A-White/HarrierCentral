import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:path_provider/path_provider.dart';

import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';

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
        print(pathPDF);
      });
    });
  }

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.0);

  TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 18.0, height: 1.0);

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
              title: const Text('Privacy Policy'),
              backgroundColor: themeAppBarBackground,
            ),
            body: Container(
              decoration: Backgrounds.defaultHcBackground(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      child: Text('Open Privacy Policy', style: headingStyle),
                      onPressed: () => Navigator.push<dynamic>(
                            context,
                            MaterialPageRoute<dynamic>(builder: (BuildContext context) => PDFScreen(pathPDF)),
                          ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(30),
                      child: Text('The Harrier Central Privacy Policy can also be found on our website for easier reading: \r\n\r\nhttp://www.harriercentral.com', textAlign: TextAlign.center, style: bodyStyle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        globalConnectionStatus == connectionStatus_notConnected
            ? Positioned(
                right: 0,
                top: 0,
                child: Image.asset(
                  'images/icons/offline_mode.png',
                  height: 120,
                  width: 120,
                ),
              )
            : Container(),
      ],
    );
  }
}

class PDFScreen extends StatelessWidget {
  const PDFScreen(this.pathPDF);

  final String pathPDF;

  @override
  Widget build(BuildContext context) {
    return PDFViewerScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          title: const Text('Privacy Policy'),
          // actions: <Widget>[
          //   IconButton(
          //     icon:const  Icon(Icons.share),
          //     onPressed: () {},
          //   ),
          // ],
        ),
        path: pathPDF);
  }
}
