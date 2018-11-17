import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harrier_central/remote_api_data/kennel_scoped_model.dart';
import 'package:harrier_central/widgets/kennel_list_item.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:harrier_central/remote_api_data/main_navigation_scoped_model.dart';



class KennelsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final KennelScopedModel kennelModel = KennelScopedModel();
    kennelModel.getKennelsFromBackend(1, true);


    return ScopedModelDescendant<MainNavigationScopedModel>(builder:
        (BuildContext context, Widget child, MainNavigationScopedModel model) {
      model.appBarTitle = 'My Kennels';
    return ScopedModel<KennelScopedModel>(
      model: kennelModel,
      child:KennelsListPageBody()
      // child: Scaffold(
      //   appBar: AppBar(
      //     centerTitle: true,
      //     backgroundColor: Colors.white,
      //     title: Text(
      //       "Kennel List",
      //       style: TextStyle(
      //         color: Colors.black,
      //       ),
      //     ),
      //   ),
      //   body: KennelsListPageBody(),
      // ),
    );
  
    });
  

}
}


class KennelsListPageBody extends StatelessWidget {
  BuildContext context;
  KennelScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return ScopedModelDescendant<KennelScopedModel>(
      builder: (BuildContext context, Widget child, KennelScopedModel model) {
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
    model.getKennelsFromBackend(1, false);
    model.notifyListeners();
    // await new Future.delayed(new Duration(seconds: 3));

    // setState(() {
    //   _count += 5;
    // });


    return null;
  }

  Widget _buildListView() {
    //Size screenSize = MediaQuery.of(context).size;

    return 
    
    
    
    
    
    Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: model.getKennelsCount() == 0
          ? const Center(child: Text('No Kennels available.'))
          : RefreshIndicator(
              onRefresh: () => _handleRefresh(),
               displacement: 40.0,
               
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: model.getKennelsCount(),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 130.0,
                    padding: const EdgeInsets.all(0.0),
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          KennelsListItem(kennel: model.kennelsList[index]),
                        ]),
                  );
                },
              ),
            ),
    );
  }

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
}
