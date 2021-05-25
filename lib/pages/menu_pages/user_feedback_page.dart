import 'package:harrier_central/imports.dart';

class UserFeedbackPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const UserFeedbackPage({Key key}) : super(key: key);

  @override
  UserFeedbackPageState createState() => UserFeedbackPageState();
}

class UserFeedbackPageState extends State<UserFeedbackPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
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
                child: UserFeedbackPageContent()),
          ],
        ),
      ),
    );
  }
}

class UserFeedbackPageContent extends StatefulWidget {
  const UserFeedbackPageContent({Key key}) : super(key: key);

  @override
  _UserFeedbackPageContentState createState() =>
      _UserFeedbackPageContentState();
}

class _UserFeedbackPageContentState extends State<UserFeedbackPageContent> {
  TextStyle headingStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.yellow,
      fontSize: 24.0,
      height: 1.0);

  TextStyle bodyStyle = const TextStyle(
      fontFamily: 'AvenirNextRegular',
      fontStyle: FontStyle.normal,
      color: Colors.white,
      fontSize: 20.0,
      height: 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(
          child: Text('Your Feedback\r\nPage Placeholder',
              textAlign: TextAlign.center, style: headingStyle)),
    );
  }
}
