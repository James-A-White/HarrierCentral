import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/widgets/circular_progress_indicator.dart';

enum FindHasherPageType { addHasherToRun, addMember }

class FindHasherPage extends StatefulWidget {
  const FindHasherPage(this.pageType);

  final FindHasherPageType pageType;

  @override
  State<FindHasherPage> createState() {
    return FindHasherPageState();
  }
}

class FindHasherPageState extends State<FindHasherPage> {
  GlobalKey hasherListBox = GlobalKey();

  List<HashersModel> hasherList;
  List<HashersModel> filteredList;

  void findHasher() {
    final HashersService svc = HashersService();
    svc.selectAllFromLocalDb().then((List<HashersModel> list) {
      hasherList = list;
      setState(() {
        if (hasherList != null) {
          hasherList.sort((HashersModel a, HashersModel b) => (a.dispName ?? '').toLowerCase().compareTo((b.dispName ?? '').toLowerCase()));
          filteredList = hasherList;
        } else {
          filteredList = null;
        }
      });
    });
  }

  void filterHasherList(String filterText) {
    setState(() {
      if (hasherList != null) {
        if (filterText.isEmpty) {
          filteredList = hasherList;
        } else {
          filteredList = hasherList.where((HashersModel user) => ((user.firstName ?? '') + ' ' + (user.lastName ?? '') + ' ' + (user.dispName ?? '')).toLowerCase().contains(filterText.toLowerCase())).toList();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    findHasher();
  }

  GlobalKey<ScaffoldState> scaffoldKey;

  final FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();

  AppBar getAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: themeAppBarBackground,
      title: const Text(
        'Find Hasher',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  // void _onSearchTextChanged() {
  //   setState(() {
  //     print('onSearchTextChanged = ${DateTime.now().millisecondsSinceEpoch}');
  //   });
  // }

  Container searchBar(num width) {
    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(left: 10, top: 10),
      width: width,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextField(
              onChanged: (String text) {
                //setState(() {
                filterHasherList(text);
                // });
              },
              focusNode: searchFocusNode,
              controller: searchController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(
                  FontAwesome.search,
                  color: Colors.black,
                ),
                hintText: 'Hash or mortal name',
                hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
              ),
            ),
          ),
          Container(
            width: 40,
            child: FlatButton(
              //color: Colors.red,
              child: const Text('X'),
              textColor: Colors.grey[700],
              onPressed: () {
                // searchController.text = '';
                // model.filterPackList('');
                // model.forceRefresh();
                // packList = model.filteredPackList;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //getPack(false);
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: SpeedDial(
        // both default to 16
        marginRight: 18,
        marginBottom: 30,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child:const  Icon(Icons.add),
        visible: true,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Theme.of(context).accentColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: CircleBorder(),
        children: <SpeedDialChild>[
          SpeedDialChild(
            child: const Icon(FontAwesome.heart),
            backgroundColor: Colors.blue,
            label: '<unused>',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {},
          )
        ],
      ),
      appBar: getAppBar(),
      body: LayoutBuilder(
        builder: (BuildContext scaffoldContext, BoxConstraints constraints) => Stack(children: <Widget>[
              Positioned(top: 0, child: searchBar(constraints.maxWidth)),
              Positioned(
                top: searchBar(constraints.maxWidth).constraints.maxHeight,
                right: 0.0,
                left: 0.0,
                child: (filteredList == null || filteredList.isEmpty)
                    ? Center(child: Container(height: 50, width: 50, child: const HcCircularProgressIndicator()))
                    : Container(
                        key: hasherListBox,
                        height: constraints.maxHeight - searchBar(constraints.maxWidth).constraints.maxHeight,
                        child: HasherListView(
                          hasherList: filteredList,
                          pageType: widget.pageType,
                        ),
                      ),
              ),
            ]),
      ),
    );
  }
}

//
//

class HasherListView extends StatelessWidget {
  const HasherListView({Key key, this.hasherList, this.pageType}) : super(key: key);

  final List<HashersModel> hasherList;
  final FindHasherPageType pageType;

  Widget listItem(BuildContext context, int index) {
    return InkWell(
      //splashColor: Colors.red,
      highlightColor: Colors.red,
      onTap: () {

        if (pageType ==FindHasherPageType.addHasherToRun)
        {


         return showDialog<int>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add ${hasherList[index].dispName}?'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(
                        'Do you want to add ${hasherList[index].dispName} to your run?',
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                      )
                    ],
                  ),
                ),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Container(
                      width: 80.0,
                      height: 50.0,
                      child: RaisedButton(
                        color: Colors.red,
                        child: const Text('Cancel'),
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.of(context).pop(-1);
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 80.0,
                    height: 50.0,
                    child: RaisedButton(
                      child: const Text(
                        'Add\r\nVisitor',
                        textAlign: TextAlign.center,
                      ),
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop(enumKnownVisitor.value);
                      },
                    ),
                  ),
                  Container(
                    width: 80.0,
                    height: 50.0,
                    child: RaisedButton(
                      child: const Text(
                        'Add\r\nHasher',
                        textAlign: TextAlign.center,
                      ),
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop(enumHasher.value);
                      },
                    ),
                  ),
                ],
              );
            }).then((int doAddHasher) {
          if (doAddHasher != -1) {
            final Map<String, dynamic> result = <String, dynamic>{'hasher': hasherList[index], 'virginVisitorType': doAddHasher};
            Navigator.of(context).pop(result);
          }
        });

        } else if (pageType ==FindHasherPageType.addMember)
        {
            final Map<String, dynamic> result = <String, dynamic>{'hasher': hasherList[index]};
            Navigator.of(context).pop(result);
        }
        return null;
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            hasherList[index].photo.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: hasherList[index].photo,
                    // placeholder: (context, url) => Container(
                    //     child: Center(
                    //       child: Container(
                    //         height: 20,
                    //         width: 20,
                    //         child: CircularProgressIndicator(
                    //           strokeWidth: 3.0,
                    //         ),
                    //       ),
                    //     ),
                    //     height: 70.0,
                    //    width: 70.0),
                    errorWidget: (BuildContext context, String url, Object error) => const Icon(Icons.error),
                    //fadeOutDuration:  Duration(seconds: 1),
                    fadeInDuration: const Duration(milliseconds: 0),
                    width: 70.0,
                    height: 70.0,
                    fit: BoxFit.fill)
                : hasherList[index].photo.startsWith('bundle')
                    ? Image(
                        width: 70.0,
                        height: 70.0,
                        fit: BoxFit.fill,
                        image: AssetImage(('images/avatars/' + hasherList[index].photo.toLowerCase().replaceFirst('bundle://', '') + '.png').toLowerCase()),
                      )
                    : Image(
                        width: 70.0,
                        height: 70.0,
                        fit: BoxFit.fill,
                        image: const AssetImage('images/avatars/avatar-2.png'),
                      ),

            Positioned(
              left: 77.0,
              top: 19.0,
              child: Text(hasherList[index].dispName, style: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 25.0, height: 1.0)),
            ),
            // this widget is here to grow the contents of the cell to a size that fills nearly the whole cell
            // in order to give plenty of room for the tap gesture.
            Positioned(
              left: 75,
              top: 0,
              child: Container(width: MediaQuery.of(context).size.width - 80, height: 65, color: Colors.transparent),
            )
            // Payment icons
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String rightToLeftTitle;
    String leftToRightTitle;
    IconData rightToLeftIcon;
    IconData leftToRightIcon;

    switch (pageType) {
      case FindHasherPageType.addHasherToRun:
        rightToLeftTitle = ' Add as\r\nvisitor';
        leftToRightTitle = 'Add\r\nto run';
        rightToLeftIcon = MaterialCommunityIcons.alpha_v_circle;
        leftToRightIcon = FontAwesome.plus_circle;
        break;
      case FindHasherPageType.addMember:
        rightToLeftTitle = ' Add as\r\nmember';
        leftToRightTitle = 'Add as\r\nmember';
        rightToLeftIcon = Ionicons.md_person_add;
        leftToRightIcon = Ionicons.md_person_add;
        break;
    }

    print(DateTime.now().millisecondsSinceEpoch.toString());
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) => const Divider(
              height: 1.0,
              color: Colors.black45,
            ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: hasherList?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          return ((hasherList == null) || (hasherList.isEmpty))
              ? Container(
                  color: Colors.grey[300],
                  width: 70.0,
                  height: 70.0,
                  child: const Padding(padding: EdgeInsets.all(5.0), child: Center(child: HcCircularProgressIndicator())),
                )
              : Dismissible(
                  key: Key(index.toString()),
                  confirmDismiss: (DismissDirection direction) {
                    final Map<String, dynamic> result = <String, dynamic>{'hasher': hasherList[index], 'virginVisitorType': direction == DismissDirection.startToEnd ? enumHasher.value : enumKnownVisitor.value};
                    Navigator.of(context).pop(result);
                    return Future<bool>.value(false);
                  },
                  background: Container(
                    color: Colors.green,
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: Icon(
                            leftToRightIcon,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: Text(leftToRightTitle, style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                      color: Colors.purple,
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: Icon(
                            rightToLeftIcon,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: Text(rightToLeftTitle, style: const TextStyle(fontFamily: 'AvenirNextDemiBold', fontStyle: FontStyle.normal, color: Colors.white, fontSize: 17.0, height: 1.0)),
                        )
                      ])),
                  onDismissed: (DismissDirection direction) {
                    print(direction.toString() + ' NOTE: We should never reach this point');
                  },
                  child: listItem(context, index),
                );
        });
  }
}
