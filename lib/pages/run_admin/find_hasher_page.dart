import 'package:harrier_central/imports_null_safe.dart';

enum FindHasherPageType { addHasherToRun, addMember }

class FindHasherPage extends StatefulWidget {
  const FindHasherPage(
    this.pageType, {
    Key? key,
    this.kennelId,
    this.eventId,
  }) : super(key: key);

  final FindHasherPageType pageType;
  final String? kennelId;
  final String? eventId;

  @override
  State<FindHasherPage> createState() {
    return FindHasherPageState();
  }
}

class FindHasherPageState extends State<FindHasherPage> {
  List<HashersModel> _hasherList = <HashersModel>[];
  List<HashersModel> _filteredList = <HashersModel>[];

  bool _isLoading = true;

  void findHasher() {
    //    if (showLoadingIndicator) {
    setState(() {
      _isLoading = true;
    });
    //}

    final HashersService svc = HashersService();
    svc.selectAllFromLocalDb(G0<Database>(), G0<TableModel>().hashersTableHelper, G0<TableModel>().hashersTableHelper.getTableName(AppDomainType.user)).then((List<BaseModel> list) {
      _hasherList = list.cast<HashersModel>();
      setState(() {
        if (_hasherList.isNotEmpty) {
          _hasherList.sort((dynamic a, dynamic b) => (a.dispName ?? '').toLowerCase().compareTo((b.dispName ?? '').toLowerCase()));
          _filteredList = _hasherList;
        } else {
          _filteredList = <HashersModel>[];
        }

        _isLoading = false;
      });
    });
  }

  void filterHasherList(String filterText) {
    setState(() {
      if (_hasherList.isNotEmpty) {
        if (filterText.isEmpty) {
          _filteredList = _hasherList;
        } else {
          _filteredList =
              _hasherList.where((dynamic user) => ((user.firstName ?? '') + ' ' + (user.lastName ?? '') + ' ' + (user.dispName ?? '')).toLowerCase().contains(filterText.toLowerCase())).toList();
        }
      } else {
        _filteredList.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    findHasher();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();

  // void _onSearchTextChanged() {
  //   setState(() {
  //     //print('onSearchTextChanged = ${DateTime.now().millisecondsSinceEpoch}');
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Find Hasher',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _searchBar(),
          Expanded(
            child: (_isLoading == true)
                ? const Center(child: HcCircularProgressIndicator(key: Key('559501910')))
                : HasherListView(
                    hasherList: _filteredList,
                    pageType: widget.pageType,
                    searchController: searchController,
                    kennelId: widget.kennelId,
                    eventId: widget.eventId,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
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
      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
      height: 70,
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
          SizedBox(
            width: 40,
            child: TextButton(
              //color: Colors.red,
              style: TextButton.styleFrom(textStyle: TextStyle(color: Colors.grey.shade700), backgroundColor: Colors.white),
              child: Text('X', style: headingStyle20Black.copyWith(color: Colors.grey.shade700)),

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
}

//
//

class HasherListView extends StatelessWidget {
  const HasherListView({
    Key? key,
    required this.hasherList,
    required this.pageType,
    required this.searchController,
    this.kennelId,
    this.eventId,
  }) : super(key: key);

  final List<HashersModel> hasherList;
  final FindHasherPageType pageType;
  final TextEditingController searchController;
  final String? kennelId;
  final String? eventId;

  Future<int?> _promptForHasherType(BuildContext context, HashersModel newHasher) async {
    return showDialog<int>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
            title: Text('Add ${newHasher.dispName}?'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Do you want to add ${newHasher.dispName} to your run?',
                    textAlign: TextAlign.justify,
                    style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              // Padding(
              //   padding: const EdgeInsets.only(right: 15.0),
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(primary: Colors.red),
              //     child: Text(
              //       'Cancel',
              //       textAlign: TextAlign.center,
              //       style: textStyleButton,
              //     ),
              //     onPressed: () {
              //       Navigator.of(context).pop(-1);
              //     },
              //   ),
              // ),

              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(-1);
                },
              ),

              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Add'),
                onPressed: () {
                  Navigator.of(context).pop(enumHasher.value);
                },
              ),

              // ElevatedButton(
              //   child: Text(
              //     'Add',
              //     textAlign: TextAlign.center,
              //     style: textStyleButton,
              //   ),
              //   onPressed: () {
              //     Navigator.of(context).pop(enumHasher.value);
              //   },
              // ),
            ],
          );
        });
  }

  Widget _listItem(BuildContext context, int index) {
    return InkWell(
      //splashColor: Colors.red,
      highlightColor: Colors.red,
      onTap: () async {
        if (pageType == FindHasherPageType.addHasherToRun) {
          int? doAddHasher = await _promptForHasherType(context, hasherList[index]);
          if (doAddHasher != -1) {
            final Map<String, dynamic> result = <String, dynamic>{'hasher': hasherList[index], 'virginVisitorType': doAddHasher};
            Navigator.of(navigatorKey.currentContext!).pop(result);
          }
        } else if (pageType == FindHasherPageType.addMember) {
          final Map<String, dynamic> result = <String, dynamic>{'hasher': hasherList[index]};
          Navigator.of(context).pop(result);
        }
        return;
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: <Widget>[
            if (hasherList[index].photo != null) ...<Widget>[
              hasherList[index].photo!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: hasherList[index].photo!,
                      placeholder: (BuildContext context, String url) => const SizedBox(
                          height: 70.0,
                          width: 70.0,
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                              ),
                            ),
                          )),
                      errorWidget: (BuildContext context, String url, dynamic error) {
                        return Container(
                            height: 70.0,
                            width: 70.0,
                            color: Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('No Image', style: mediumTextRed.copyWith(fontSize: 13, color: Colors.grey)),
                                const Icon(Icons.error, color: Colors.grey),
                                Text('Available', style: mediumTextRed.copyWith(fontSize: 13, color: Colors.grey))
                              ],
                            ));
                      },
                      //fadeOutDuration:  Duration(seconds: 1),
                      fadeInDuration: const Duration(milliseconds: 0),
                      width: 70.0,
                      height: 70.0,
                      fit: BoxFit.fill)
                  : hasherList[index].photo!.startsWith('bundle')
                      ? Image(
                          width: 70.0,
                          height: 70.0,
                          fit: BoxFit.fill,
                          image: AssetImage(('images/avatars/${hasherList[index].photo!.toLowerCase().replaceFirst('bundle://', '')}.jpg').toLowerCase()),
                        )
                      : const Image(
                          width: 70.0,
                          height: 70.0,
                          fit: BoxFit.fill,
                          image: AssetImage('images/avatars/avatar-2.jpg'),
                        ),
            ],

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

  Widget _getAddHasherBlock(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // NULLSAFETODO
        // Navigator.push<HashersModel>(
        //   context,
        //   MaterialPageRoute<HashersModel>(
        //     builder: (BuildContext context) => HasherProfilePage(
        //       dataContext: pageType == FindHasherPageType.addHasherToRun ? EnumDataContext.event : EnumDataContext.kennel,
        //       pageType: EnumMyProfilePageType.newHasherProfile,
        //       eventId: pageType == FindHasherPageType.addHasherToRun ? eventId : GUID_EMPTY,
        //       kennelId: kennelId,
        //       uiElementsToDisplay: HasherProfilePage.flagUiElement_followKennel,
        //       hashNameFromSearch: capitalizeFirstLetter(searchController.text),
        //     ),
        //   ),
        // ).then((HashersModel newHasher) {
        //   if (newHasher != null) {
        //     if (pageType == FindHasherPageType.addHasherToRun) {
        //       _promptForHasherType(context, newHasher).then((int doAddHasher) {
        //         if (doAddHasher != -1) {
        //           final Map<String, dynamic> result = <String, dynamic>{'hasher': newHasher, 'virginVisitorType': doAddHasher};
        //           Navigator.of(context).pop(result);
        //         }
        //       });
        //     } else if (pageType == FindHasherPageType.addMember) {
        //       final Map<String, dynamic> result = <String, dynamic>{'hasher': newHasher};
        //       Navigator.of(context).pop(result);
        //     }
        //   }
        //   return null;
        // });
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(left: 10),
        child: Row(
          children: <Widget>[
            Icon(SimpleLineIcons.question, size: 35.0, color: Colors.red.shade900),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Can\'t find a Hasher?', style: smallContentStyleDb),
                    AutoSizeText(
                      'Click here to add \'${capitalizeFirstLetter(searchController.text)}\'',
                      style: smallContentStyle,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String capitalizeFirstLetter(String s) => (s.isNotEmpty) ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

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

    //print(DateTime.now().millisecondsSinceEpoch.toString());
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) => const Divider(
              height: 1.0,
              color: Colors.black45,
            ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: hasherList.length + (searchController.text.isNotEmpty ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if ((index == hasherList.length) && (searchController.text.isNotEmpty)) {
            return _getAddHasherBlock(context);
          } else {
            return (hasherList.isEmpty)
                ? Container(
                    color: Colors.grey[300],
                    width: 70.0,
                    height: 70.0,
                    child: const Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Center(child: HcCircularProgressIndicator(key: Key('3330495910'))),
                    ),
                  )
                : Dismissible(
                    key: Key(index.toString()),
                    confirmDismiss: (DismissDirection direction) {
                      final Map<String, dynamic> result = <String, dynamic>{
                        'hasher': hasherList[index],
                        'virginVisitorType': direction == DismissDirection.startToEnd ? enumHasher.value : enumKnownVisitor.value
                      };
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
                      //print(direction.toString() + ' NOTE: We should never reach this point');
                    },
                    child: _listItem(context, index),
                  );
          }
        });
  }
}
