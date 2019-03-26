import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/services/user_run_history_scoped_model.dart';
import 'package:harrier_central/util/styles.dart';

import 'package:scoped_model/scoped_model.dart';
//import 'package:auto_size_text/auto_size_text.dart';

class UserRunHistoryListPage extends StatefulWidget {
  const UserRunHistoryListPage({Key key, @required this.kennelId, @required this.kennelName, @required this.kennelShortName, @required this.kennelLogo})
      : super(key: key);

  final String kennelId;
  final String kennelName;
  final String kennelShortName;
  final String kennelLogo;

  @override
  UserRunHistoryPageState createState() =>
      UserRunHistoryPageState(kennelId: kennelId);
}

class UserRunHistoryPageState extends State<UserRunHistoryListPage> {
  UserRunHistoryPageState({@required this.kennelId});

  String kennelId;

  UserRunHistoryScopedModel model;

  @override
  void initState() {
    super.initState();
    model = UserRunHistoryScopedModel(kennelId: kennelId);
  }

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return ScopedModel<UserRunHistoryScopedModel>(
      model: model,
      child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: Text(
          'My runs for ${widget.kennelShortName}',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
        body: ScopedModelDescendant<UserRunHistoryScopedModel>(
          builder: (BuildContext context, Widget child,
              UserRunHistoryScopedModel model) {
            if ((model.userEventList.isEmpty) && (!model.isLoading)) {
              // TODO(James): Check this statement and make sure the cast to FALSE is correct
              model.getUserEventsFromBackend(true);
            }

            return model.isLoading
                ? _buildCircularProgressIndicator()
                : _buildListView();
          },
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> _handleRefresh() async {
    model.clearKennelList();
    model.getUserEventsFromBackend(false);
    //model.notifyListeners();
  }

  TextStyle headingStyle = TextStyle(
      fontFamily: 'AvenirNextCondensedDemiBold',
      fontStyle: FontStyle.normal,
      fontSize: 22.0,
      height: 0.6);

  Widget _buildListView() {
    const num headingWidth = 55.0;
    return Container(
      decoration: Backgrounds.defaultHcBackgroundLight(),
      padding: const EdgeInsets.only(top: 0.0),
      child: model.getKennelsCount() == 0
          ? const Center(child: Text('No Kennels available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
              displacement: 40.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      // border: new Border.all(width: 1.0, color: Colors.black),
                      //shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Color.fromARGB(70, 0, 0, 0),
                          offset: Offset(0.0, 6.0),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                    //color:Color.fromARGB(30, 0, 0, 0),
                    padding: const EdgeInsets.only(
                        left: 5, top: 5, right: 20, bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          height: 50,
                          child: Image.asset(
                            'images/other/hound_and_hare_drinking.png',
                          ),
                        ),
                        Container(
                          width: headingWidth,
                          child: Text(
                            'Pack\r\nruns',
                            style: headingStyle,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: headingWidth,
                          child: Text(
                            'Hare\r\nruns',
                            style: headingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: headingWidth,
                          child: Text(
                            'Total\r\nruns',
                            style: headingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: headingWidth,
                          child: Text(
                            'Hash\r\npoints',
                            style: headingStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: model.getKennelsCount(),
                      padding: const EdgeInsets.only(top: 20),
                      itemExtent: 60.0,
                      itemBuilder: (BuildContext context, int index) {
                        return Text(model.userEventList[index].eventName);

                        // Container(
                        //   height: 60.0,
                        //   //padding: const EdgeInsets.only(top: 10.0),
                        //   child:

                        // KennelRunHistoryCountListItem(
                        //     kennelRunHistoryCount:
                        //         model.kennelRunCountList[index]);

                        // );
                      },
                    ),
                  ),
                ],
              )),
    );
  }
}
