import 'package:harrier_central/imports.dart';

class AddKennelPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const AddKennelPage({super.key});

  @override
  AddKennelPageState createState() => AddKennelPageState();
}

class AddKennelPageState extends State<AddKennelPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      SizedBox(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
      Positioned(
        top: 0,
        left: 0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: themeAppBarBackground,
            iconTheme: const IconThemeData(
              color: Colors.white,
              size: 28.0,
            ),
            title: Text('Add a Kennel', style: ts_appBarTitle),
          ),
          body: Container(
            decoration: Backgrounds.defaultHcBackground(),
            height: MediaQuery.of(context).size.height,
            child: const FaqPageContent(),
          ),
        ),
      ),
      OfflineModeRibbon(
        showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected,
        lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
        ribbonImage: 'images/icons/offline_mode.png',
        refreshFunction: () {
          setState(() {});
        },
      ),
    ]);
  }
}

class FaqPageContent extends StatefulWidget {
  const FaqPageContent({super.key});

  @override
  FaqPageContentState createState() => FaqPageContentState();
}

class FaqPageContentState extends State<FaqPageContent> {
  TextStyle sectionStyle = ts_titleLarge.copyWith(color: Colors.orange, height: 1.2);

  TextStyle headingStyle = ts_heading.copyWith(height: 1.2);

  TextStyle bodyStyle = ts_medium.copyWith(height: 1.2);

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
                  Connection2.styleForConnected(
                    G0<AppModel>().connectionStatus,
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                        ),
                        onPressed: () async {
                          await launchUrl(Uri.parse('https://harriercentral.com/index.php/add-kennel-with-facebook-integration/'), mode: LaunchMode.externalApplication);
                        },
                        child: Text('Add with Facebook', style: ts_button),
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
                  Connection2.styleForConnected(
                    G0<AppModel>().connectionStatus,
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
                        ),
                        onPressed: () async {
                          await launchUrl(Uri.parse('https://harriercentral.com/index.php/add-kennel-standalone/'), mode: LaunchMode.externalApplication);
                        },
                        child: Text('Add without integration', style: ts_button),
                      ),
                    ),
                  ),
                  const SizedBox(
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
