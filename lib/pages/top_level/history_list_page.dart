import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/services/kennel_run_history_totals_scoped_model.dart';
import 'package:harrier_central/widgets/kennel_run_history_count_list_item.dart';
import 'package:harrier_central/util/styles.dart';

import 'package:scoped_model/scoped_model.dart';
//import 'package:auto_size_text/auto_size_text.dart';

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({Key key, @required this.kennelRunCountHistoryModel})
      : super(key: key);

  final KennelRunHistoryTotalsScopedModel kennelRunCountHistoryModel;

  @override
  HistoryListPageState createState() =>
      HistoryListPageState(model: kennelRunCountHistoryModel);
}

class HistoryListPageState extends State<HistoryListPage> {
  HistoryListPageState({@required this.model});

  KennelRunHistoryTotalsScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    return ScopedModel<KennelRunHistoryTotalsScopedModel>(
      model: model,
      child: Scaffold(
        body: ScopedModelDescendant<KennelRunHistoryTotalsScopedModel>(
          builder: (BuildContext context, Widget child,
              KennelRunHistoryTotalsScopedModel model) {
            if ((model.kennelRunCountList.isEmpty) && (!model.isLoading)) {
              // TODO(James): Check this statement and make sure the cast to FALSE is correct
              model.getKennelsFromBackend(true);
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
    model.getKennelsFromBackend(false);
    //model.notifyListeners();
  }

  TextStyle headingStyle = TextStyle(
                          fontFamily: 'AvenirNextCondensedDemiBold',
                          fontStyle: FontStyle.normal,
                          fontSize: 22.0,
                          height: 0.6); 

  Widget _buildListView() {
    num headingWidth = 55.0;
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
                  Padding(
                    padding: const EdgeInsets.only(left: 80.0,top:20,right:20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(width:headingWidth,child:Text('Pack\r\nruns',style: headingStyle, maxLines: 2, textAlign: TextAlign.center,),),
                        Container(width:headingWidth,child:Text('Hare\r\nruns',style: headingStyle,textAlign: TextAlign.center,),),
                        Container(width:headingWidth,child:Text('Total\r\nruns',style: headingStyle,textAlign: TextAlign.center,),),
                        Container(width:headingWidth,child:Text('Hash\r\npoints',style: headingStyle,textAlign: TextAlign.center,),),
                      
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: model.getKennelsCount(),
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          height: 90.0,
                          padding: const EdgeInsets.only(top: 10.0),
                          child: KennelRunHistoryCountListItem(
                              kennelRunHistoryCount:
                                  model.kennelRunCountList[index]),
                        );
                      },
                    ),
                  ),
                ],
              )),
    );
    
  }
}
