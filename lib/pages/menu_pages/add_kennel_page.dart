// @dart=2.11
import 'package:harrier_central/imports.dart';

class AddKennelPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const AddKennelPage({Key key}) : super(key: key);

  @override
  AddKennelPageState createState() => AddKennelPageState();
}

class AddKennelPageState extends State<AddKennelPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
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
              'Add a Kennel',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          body: Container(
            decoration: Backgrounds.defaultHcBackground(),
            height: MediaQuery.of(context).size.height,
            child: const FaqPageContent(),
          ),
        ),
      ),
      OfflineModeRibbon(
        showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
        lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
        ribbonImage: 'images/icons/offline_mode.png',
      ),
    ]);
  }
}

class FaqPageContent extends StatefulWidget {
  const FaqPageContent({Key key}) : super(key: key);

  @override
  _FaqPageContentState createState() => _FaqPageContentState();
}

class _FaqPageContentState extends State<FaqPageContent> {
  TextStyle sectionStyle = const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.orange, fontSize: 24.0, height: 1.2);

  TextStyle headingStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.yellow, fontSize: 22.0, height: 1.2);

  TextStyle bodyStyle = const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 16.0, height: 1.2);

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('\r\nAdding a Kennel', style: sectionStyle),
                  Text(
                      '\r\nIf you are on a Kennel\'s Mismanagement then you should consider adding your Kennel to Harrier Central. Below you will find information on how to do this both using automatic Facebook integration or as a stand-alone Kennel with no integration.\r\n\r\nIf your Kennel publishes your runs to a public or private Facebook group, we highly recommend you select this option as it will enable you to avoid double entry of data. Please read more below and sign up today!\r\n\r\nOne more small note, the below buttons open up a form that you have to fill out. If you are comfortable using your phone to type, please go ahead and use the below buttons. If you prefer working with a keyboard, please visit our website at https://www.harriercentral.com/ where you can fill out the forms using your computer.',
                      style: bodyStyle),
                  Text('\r\n1. Add a Kennel with Facebook integration', style: headingStyle),
                  Text(
                    'If your Kennel uses Facebook Events to publish run information (even if your Facebook group is private), this is the best option for you. Once you have configured the system, our backend will automatically copy your run information from your Facebook Group into Harrier Central so you do not have to input data twice. Every time you change information about a run on Facebook, the change will get populated in Harrier Central within five minutes.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Connection.styleForConnected(
                    G0<AppModel>().connectionStatus,
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                        ),
                        onPressed: () async {
                          await launch('https://harriercentral.com/index.php/add-kennel-with-facebook-integration/');
                        },
                        child: Text('Add with Facebook', style: textStyleButton),
                      ),
                    ),
                  ),
                  Text('\r\n2. Add a Kennel with no integration', style: headingStyle),
                  Text(
                    'Use this option to add your Kennel without configuring any data integrations. In this case, you use your Harrier Central app to add runs, indicate run locations and add descriptive information about the runs. All of the other features work the same irrespective of how the run information is added to our backend platform. Use this option if your Kennel does not post run information on Facebook.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Connection.styleForConnected(
                    G0<AppModel>().connectionStatus,
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                        ),
                        onPressed: () async {
                          await launch('https://harriercentral.com/index.php/add-kennel-standalone/');
                        },
                        child: Text('Add without integration', style: textStyleButton),
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 30,
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
