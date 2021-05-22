import 'package:harrier_central/imports.dart';

class InAppPurchasePage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const InAppPurchasePage({Key key}) : super(key: key);

  @override
  InAppPurchasePageState createState() => InAppPurchasePageState();
}

class InAppPurchasePageState extends State<InAppPurchasePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: const <Widget>[
            Positioned(
                //top: 10,
                //left: 20,
                //width: MediaQuery.of(context).size.width,
                child: InAppPurchasePageContent()),
          ],
        ),
      ),
    );
  }
}

class InAppPurchasePageContent extends StatefulWidget {
  const InAppPurchasePageContent({Key key}) : super(key: key);

  @override
  _InAppPurchasePageContentState createState() => _InAppPurchasePageContentState();
}

class _InAppPurchasePageContentState extends State<InAppPurchasePageContent> {
  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 24.0, height: 1.0);

  TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 20.0, height: 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(child: Text(' In App Purchase\r\nPage Placeholder', textAlign: TextAlign.center, style: headingStyle)),
    );
  }
}
