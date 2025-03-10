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

  bool _isUpdating = false;

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
                          setState(() {
                            _isUpdating = true;
                          });

                          final result = widget.refreshPage!();

                          if (result is Future<dynamic>) {
                            result.then((dynamic rda) {
                              setState(() {
                                if (rda != null) {
                                  _futureRun = rda;
                                }
                                _isUpdating = false;
                              });
                            });
                          }
                        }
                      }); //_select(choices[0]);
                    },
                  ),
          ],
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 28.0,
          ),
          title: Text('Run Details', style: ts_appBarTitle),
        ),
        body: Container(
            decoration: Backgrounds.defaultHcBackground(),
            height: MediaQuery.of(context).size.height,
            child: _isUpdating
                ? Center(
                    child: HcCircularProgressIndicator(key: UniqueKey()),
                  )
                : RunTabs(futureRun: _futureRun)));
  }
}
