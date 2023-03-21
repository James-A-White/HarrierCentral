import 'package:harrier_central/imports_null_safe.dart';

class SelectRunPage extends StatefulWidget {
  const SelectRunPage({
    Key? key,
    required this.runList,
    required this.selected,
  }) : super(key: key);

  final List<AreWeAtRunModel> runList;
  final Map<String, bool> selected;

  @override
  SelectRunPageState createState() => SelectRunPageState();
}

class SelectRunPageState extends State<SelectRunPage> {
  SelectRunPageState();

  List<Map<String, dynamic>> atRunList = <Map<String, dynamic>>[];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          title: const Text(
            'Select run',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: _buildListView());
  }

  bool _showCheckinButton = false;

  Widget _buildListView() {
    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: Column(
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Text(
              'Would you like to check in to any of the below runs?',
              style: headingStyleBlack.copyWith(height: 1.2),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            //color: Colors.white,
            decoration: const BoxDecoration(
              // border: new Border.all(width: 1.0, color: Colors.black),
              //shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color.fromARGB(70, 0, 0, 0),
                  offset: Offset(0.0, 10.0),
                  blurRadius: 10.0,
                ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.red.shade900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('Don\'t check in', style: buttonLabelStyleMedium),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                const SizedBox(width: 30.0),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.grey.shade700;
                        }
                        return Colors.green.shade800; // Use the component's default.
                      },
                    ),
                  ),
                  onPressed: _showCheckinButton
                      ? () {
                          Navigator.of(context).pop(true);
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('Check in', style: buttonLabelStyleMedium),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 50),
              physics: const AlwaysScrollableScrollPhysics(),
              //padding: const EdgeInsets.only( bottom: 40.0),
              itemCount: widget.runList.length,
              //itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                //index = 0;
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: RunListItem(
                      item: widget.runList[index],
                      selected: widget.selected[widget.runList[index]] ?? false,
                      callback: (AreWeAtRunModel item) {
                        setState(() {
                          _showCheckinButton = false;
                          for (AreWeAtRunModel r in widget.runList) {
                            if (widget.selected.containsKey(r.eventId)) {
                              _showCheckinButton = true;
                              break;
                            }
                          }
                        });
                      }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RunListItem extends StatelessWidget {
  const RunListItem({
    Key? key,
    required this.item,
    required this.callback,
    required this.selected,
  }) : super(key: key);

  final AreWeAtRunModel item;
  final Function callback;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      KennelLogo(
        kennelId: item.kennelId,
        kennelLogoUrl: item.kennelLogo,
        kennelShortName: item.kennelShortName,
        logoHeight: 45.0,
      ),
      Expanded(
        child: CheckboxListTile(
            value: selected,
            title: Text(item.eventName),
            onChanged: (bool? value) {
              callback(item, value ?? false);
            }),
      ),
    ]);
  }
}
