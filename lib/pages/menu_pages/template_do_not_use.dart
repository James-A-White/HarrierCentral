import 'package:harrier_central/imports.dart';

class DoNotUse extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const DoNotUse({
    super.key,
  });

  @override
  DoNotUseState createState() => DoNotUseState();
}

class DoNotUseState extends State<DoNotUse> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28.0,
        ),
        title: Text('My Profile', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: const Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Positioned(
                top: 10,
                left: 20,
                //width: MediaQuery.of(context).size.width,
                child: XPageContent()),
          ],
        ),
      ),
    );
  }
}

class XPageContent extends StatefulWidget {
  const XPageContent({super.key});

  @override
  XPageContentState createState() => XPageContentState();
}

class XPageContentState extends State<XPageContent> {
  @override
  Widget build(BuildContext context) {
    return Container(color: hc_red, width: 100, height: 100);
  }
}
