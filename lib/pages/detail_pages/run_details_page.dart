import 'package:harrier_central/imports.dart';

class RunDetailsPage extends StatefulWidget {
  const RunDetailsPage({
    super.key,
    required this.futureRun,
    this.refreshPage,
  });

  final RunDetailsAggregate futureRun;
  final Function? refreshPage;

  @override
  RunDetailsPageState createState() => RunDetailsPageState();
}

class RunDetailsPageState extends State<RunDetailsPage> {
  late RunDetailsAggregate _futureRun;

  @override
  void initState() {
    _futureRun = widget.futureRun;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            _futureRun.extensions.appAccessFlags == 0
                ? Container()
                : IconButton(
                    icon: const Icon(FontAwesome.gear, color: Colors.white),
                    onPressed: () {
                      Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => RunAdminPage(
                            eventId: _futureRun.event.eventId,
                          ),
                        ),
                      ).then((void _) {
                        if (widget.refreshPage != null) {
                          widget.refreshPage!().then((RunDetailsAggregate? rda) {
                            setState(() {
                              if (rda != null) {
                                _futureRun = rda;
                              }
                            });
                          });
                        }
                      }); //_select(choices[0]);
                    },
                  ),
          ],
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: const Text(
            'Run Details',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: RunTabs(futureRun: _futureRun));
  }
}
