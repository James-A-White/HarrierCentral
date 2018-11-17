import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';
import 'package:harrier_central/widgets/run_list_item.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:harrier_central/remote_api_data/main_navigation_scoped_model.dart';
//

class FutureRunsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FutureRunScopedModel futureRunModel = FutureRunScopedModel();
    futureRunModel.getFutureRunsFromBackend(1, true);
    return ScopedModelDescendant<MainNavigationScopedModel>(builder:
        (BuildContext context, Widget child, MainNavigationScopedModel model) {
      model.appBarTitle = 'Upcoming Runs';
      return ScopedModel<FutureRunScopedModel>(
          model: futureRunModel, child: FutureRunListPageBody());
    });
  }
}

class FutureRunListPageBody extends StatelessWidget {
  BuildContext context;
  FutureRunScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return ScopedModelDescendant<FutureRunScopedModel>(
      builder:
          (BuildContext context, Widget child, FutureRunScopedModel model) {
        this.model = model;
        return model.isLoading
            ? _buildCircularProgressIndicator()
            : _buildListView();
      },
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<Null> _handleRefresh() async {
    model.getFutureRunsFromBackend(1, false);
    model.notifyListeners();

    return null;
  }

  Widget _buildListView() {
    //Size screenSize = MediaQuery.of(context).size;

    return Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: model.getFutureRunsCount() == 0
            ? const Center(child: Text('No Kennels available.'))
            : RefreshIndicator(
                onRefresh: () => _handleRefresh(),
                displacement: 40.0,
                child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 40.0, bottom: 40.0),
                    itemCount: model.getFutureRunsCount(),
                    itemBuilder: (BuildContext context, int index) {
                      if (model.futureRunsList[index].daysUntilNextRun < 9999) {
                        return RunListItem(
                            futureRun: model.futureRunsList[index]);
                      }
                    })));
  }
}
// children: <Widget>[
//   Row(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: <Widget>[
//       IconButton(
//         icon: Icon(FontAwesomeIcons.solidCheckCircle),
//         color: Colors.green,
//         tooltip: 'Select to follow a Kennel',
//         iconSize: 35.0,
//         alignment: Alignment.topCenter,
//         splashColor: Colors.greenAccent,
//         onPressed: () {
//           var i = 1;
//           //model.toggleFollowing(kennel);

//           // setState(() {
//           // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
//           // });
//         },
//       ),
//       IconButton(
//         icon: Icon(FontAwesomeIcons.solidQuestionCircle),
//         color: Colors.orange,
//         tooltip: 'Select to follow a Kennel',
//         iconSize: 35.0,
//         alignment: Alignment.topCenter,
//         splashColor: Colors.greenAccent,
//         onPressed: () {
//           var i = 1;
//           //model.toggleFollowing(kennel);

//           // setState(() {
//           // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
//           // });
//         },
//       ),
//       IconButton(
//         icon: Icon(FontAwesomeIcons.solidTimesCircle),
//         color: Colors.red,
//         tooltip: 'Select to follow a Kennel',
//         iconSize: 35.0,
//         alignment: Alignment.topCenter,
//         splashColor: Colors.greenAccent,
//         onPressed: () {
//           var i = 1;
//           //model.toggleFollowing(kennel);

//           // setState(() {
//           // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
//           // });
//         },
//       ),
//       IconButton(
//         icon: ImageIcon(
//             AssetImage('images/icons/hare_icon.png')),
//         color: Colors.deepPurple[700],
//         tooltip: 'Select to follow a Kennel',
//         iconSize: 35.0,
//         alignment: Alignment.topCenter,
//         splashColor: Colors.greenAccent,
//         onPressed: () {
//           var i = 1;
//           //model.toggleFollowing(kennel);

//           // setState(() {
//           // kennel.followingBool = kennel.followingBool == 0 ? 1 : 0;
//           // });
//         },
//       ),
//     ],
//   ),

//   const Text('test'),
//   // const Divider(
//   //   color: Colors.black,
//   //   height: 2.0,
//   // ),
// ]),

// Widget _buildFilterWidgets(Size screenSize) {
//   return Container(
//     margin: const EdgeInsets.all(12.0),
//     width: screenSize.width,
//     child: Card(
//       elevation: 4.0,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12.0),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
//             _buildFilterButton("SORT"),
//             Container(
//               color: Colors.black,
//               width: 2.0,
//               height: 24.0,
//             ),
//             _buildFilterButton("REFINE"),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// Widget _buildFilterButton(String title) {
//   return InkWell(
//     onTap: () {
//       print(title);
//     },
//     child: Row(
//       children: <Widget>[
//         Icon(
//           Icons.arrow_drop_down,
//           color: Colors.black,
//         ),
//         SizedBox(
//           width: 2.0,
//         ),
//         Text(title),
//       ],
//     ),
//   );
// }
