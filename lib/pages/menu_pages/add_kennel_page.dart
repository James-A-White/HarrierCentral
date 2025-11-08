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
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: AppScaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: themeAppBarBackground,
              iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
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

class FaqPageContent extends StatefulWidget {
  const FaqPageContent({super.key});

  @override
  FaqPageContentState createState() => FaqPageContentState();
}

class FaqPageContentState extends State<FaqPageContent> {
  TextStyle sectionStyle = ts_titleLarge.copyWith(
    color: Colors.orange,
    height: 1.2,
  );

  TextStyle headingStyle = ts_heading.copyWith(height: 1.2);

  TextStyle bodyStyle = ts_medium.copyWith(height: 1.2);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('\r\nAdding a Kennel', style: sectionStyle),
                    Text(
                      '\r\nIf you are on a Kennel\'s Mismanagement you should add your Kennel to Harrier Central! Below you will find information on how to do this. Please read more below and sign up today!\r\n\r\nOne more small note, the below buttons open up a form that you have to fill out. If you are comfortable using your phone to type, please go ahead and use the below buttons. If you prefer working with a keyboard, please visit our website at https://www.harriercentral.com/ where you can fill out the forms using your computer.',
                      style: bodyStyle,
                    ),
                    const SizedBox(height: 20.0),
                    Text('\r\nAdd a Kennel', style: headingStyle),
                    Text(
                      'Use this option to add your Kennel. You can use your Harrier Central app or our administrative web portal to add runs, indicate run locations and add descriptive information about the runs.',
                      style: bodyStyle,
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20.0),
                    StyleForConnected(
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 8,
                              left: 20,
                              right: 20,
                            ),
                          ),
                          onPressed: () async {
                            await launchUrl(
                              Uri.parse(
                                'https://harriercentral.com/index.php/add-kennel-standalone/',
                              ),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: Text('Add Your Kennel', style: ts_button),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50, width: 30),
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
