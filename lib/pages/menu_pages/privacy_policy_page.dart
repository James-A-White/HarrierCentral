import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:path_provider/path_provider.dart';

import 'package:harrier_central/util/styles.dart';

class PrivacyPolicyPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  PrivacyPolicyPage({Key key}) : super(key: key);

  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

Future<File> createFileOfPdfUrl() async {
  var bytes = await rootBundle.load('assets/documents/privacy_policy.pdf');
  String dir = (await getApplicationDocumentsDirectory()).path;
  File file = new File('$dir/privacy_policy_internal.pdf');
  await file.writeAsBytes(bytes.buffer.asInt8List());
  return file;
}

class PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String pathPDF = "";

  @override
  void initState() {
    super.initState();
    createFileOfPdfUrl().then((f) {
      setState(() {
        pathPDF = f.path;
        print(pathPDF);
      });
    });
  }

  TextStyle headingStyle = TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 24.0,
      height: 1.0);

  TextStyle bodyStyle = TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 18.0,
      height: 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text("Open Privacy Policy", style: headingStyle),
                onPressed: () => Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute<dynamic>(
                          builder: (context) => PDFScreen(pathPDF)),
                    ),
              ),
              Container(
                margin: EdgeInsets.all(30),
                child: Text(
                    'The Harrier Central Privacy Policy can also be found on our website for easier reading: \r\n\r\nhttp://www.harriercentral.com',
                    textAlign: TextAlign.center,
                    style: bodyStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PDFScreen extends StatelessWidget {
  String pathPDF = "";
  PDFScreen(this.pathPDF);

  @override
  Widget build(BuildContext context) {
    return PDFViewerScaffold(
        appBar: AppBar(
          backgroundColor: ThemeColors.appBarBackground,
          title: Text("Privacy Policy"),
          // actions: <Widget>[
          //   IconButton(
          //     icon: Icon(Icons.share),
          //     onPressed: () {},
          //   ),
          // ],
        ),
        path: pathPDF);
  }
}
