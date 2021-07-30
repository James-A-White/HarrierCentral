import 'package:harrier_central/imports.dart';
import 'package:latlong/latlong.dart';
import 'package:date_time_picker/date_time_picker.dart';

class EditRunDetailsPage extends StatefulWidget {
  const EditRunDetailsPage(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _EditRunDetailsPageState createState() => _EditRunDetailsPageState();
}

class _EditRunDetailsPageState extends State<EditRunDetailsPage> with SingleTickerProviderStateMixin {
  List<Tab> tabs = <Tab>[];

  TabController _tabController;

  final String userId = getStringPref(StringPrefsEnum.userId);

  GlobalKey tabKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Edit run details',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackgroundLight(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            // Positioned(
            //     top: 30,
            //     left: 0,
            //     right: 0,
            //     child: Text(
            //       'QR Code Scanner',
            //       textAlign: TextAlign.center,
            //       style: const TextStyle(
            //           fontFamily: 'AvenirNextRegular',
            //           fontStyle: FontStyle.normal,
            //           color: Colors.white,
            //           fontSize: 24.0,
            //           height: 1.0),
            //     )),
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  //color: Colors.white,
                  height: 85,
                  decoration: BoxDecoration(
                    // border: new Border.all(width: 1.0, color: Colors.black),
                    //shape: BoxShape.circle,
                    color: Colors.yellow.shade50,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color.fromARGB(70, 0, 0, 0),
                        offset: Offset(0.0, 6.0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                )),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                width: 340.0,
                height: 45.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: const BorderRadius.all(Radius.circular(35.0)),
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: TabBar(
                    physics: const NeverScrollableScrollPhysics(),
                    labelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'AvenirNextCondensedMedium', fontStyle: FontStyle.normal, fontSize: 18.0, height: 1.0),
                    isScrollable: false,
                    unselectedLabelColor: Colors.black,
                    labelColor: Colors.white,
                    labelPadding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BubbleTabIndicator(
                      indicatorHeight: 35.0,
                      indicatorColor: Theme.of(context).buttonColor,
                      tabBarIndicatorSize: TabBarIndicatorSize.tab,
                      indicatorRadius: 20.0,
                    ),
                    tabs: tabs,
                    controller: _tabController,
                  ),
                ),
              ),
            ),
            Positioned(
                top: 86,
                bottom: 0,
                child: Container(
                  key: tabKey,
                  //color: Colors.teal,
                  width: MediaQuery.of(context).size.width,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: <Widget>[
                      DetailsTab(widget.eventAggregate, widget.getUpdatedEventAggregate),
                      LocationTab(widget.eventAggregate, widget.getUpdatedEventAggregate),
                      OtherInfoTab(widget.eventAggregate, widget.getUpdatedEventAggregate),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initTabs();

    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      FocusScope.of(context).unfocus();
    });
  }

  // Color left = Colors.white;
  // Color right = Colors.white;

  void _initTabs() {
    if (tabs.isEmpty) {
      tabs.add(const Tab(text: 'Details'));
      tabs.add(const Tab(text: 'Map'));
      tabs.add(const Tab(text: 'Other'));
      //tabs.add(const Tab(text: 'Date/Time'));
    }
  }

  // void _onSwitchToQrCode() {
  //   _pageController.animateToPage(0,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }

  // void _onSwitchToQrScanner() {
  //   _pageController?.animateToPage(1,
  //       duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  // }
}

class OtherInfoTab extends StatefulWidget {
  const OtherInfoTab(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _OtherInfoTabState createState() => _OtherInfoTabState();
}

class _OtherInfoTabState extends State<OtherInfoTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;
  RunDetailAggregate _updatedEventAggregate;
  bool _isUpdating = false;

  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();

  final FocusNode _focusNodeAbsoluteEventNumber = FocusNode();
  final FocusNode _focusNodeEventPriceForMembers = FocusNode();
  final FocusNode _focusNodeEventPriceForNonMembers = FocusNode();
  final FocusNode _focusNodeEventPriceForExtras = FocusNode();
  final FocusNode _focusNodeExtrasDescription = FocusNode();

  final TextEditingController _absoluteEventNumberController = TextEditingController();
  final TextEditingController _eventPriceForMembersController = TextEditingController();
  final TextEditingController _eventPriceForNonMembersController = TextEditingController();
  final TextEditingController _eventPriceForExtrasController = TextEditingController();
  final TextEditingController _extrasDescriptionController = TextEditingController();

  bool _isVisible = true;
  bool _isCountedRun = true;
  bool _usersCanEditRunAttendence = false;
  bool _isPromotedEvent = false;
  int _eventGeographicScope = 1;

  @override
  void dispose() {
    _absoluteEventNumberController.dispose();
    _eventPriceForMembersController.dispose();
    _eventPriceForNonMembersController.dispose();
    _eventPriceForExtrasController.dispose();
    _extrasDescriptionController.dispose();

    _focusNodeAbsoluteEventNumber.dispose();
    _focusNodeEventPriceForMembers.dispose();
    _focusNodeEventPriceForNonMembers.dispose();
    _focusNodeEventPriceForExtras.dispose();
    _focusNodeExtrasDescription.dispose();

    super.dispose();
  }

  void setTextFields() {
    _absoluteEventNumberController.text = _updatedEventAggregate.event.absoluteEventNumber?.toString() ?? '<auto>';
    _eventPriceForMembersController.text = _updatedEventAggregate.event.eventPriceForMembers?.toString() ?? '<default>';
    _eventPriceForNonMembersController.text = _updatedEventAggregate.event.eventPriceForNonMembers?.toString() ?? '<default>';
    _eventPriceForExtrasController.text = _updatedEventAggregate.event.eventPriceForExtras?.toString() ?? '<none>';
    _extrasDescriptionController.text = _updatedEventAggregate.event.extrasDescription ?? '<none>';
    _eventGeographicScope = _updatedEventAggregate.event.eventGeographicScope;
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: <KeyboardActionsItem>[
        KeyboardActionsItem(
          focusNode: _focusNodeAbsoluteEventNumber,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventPriceForMembers,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventPriceForNonMembers,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventPriceForExtras,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeExtrasDescription,
        ),
      ],
    );
  }

  @override
  void initState() {
    _updatedEventAggregate = widget.eventAggregate;
    setTextFields();

    _focusNodeAbsoluteEventNumber.addListener(() {
      setState(() {});
    });

    _focusNodeEventPriceForMembers.addListener(() {
      setState(() {});
    });

    _focusNodeEventPriceForNonMembers.addListener(() {
      setState(() {});
    });

    _eventPriceForExtrasController.addListener(() {
      setState(() {});
    });

    _extrasDescriptionController.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(
          color: Colors.red.shade700,
          size: 35,
        ),
      ),
      child: KeyboardActions(
        config: _buildConfig(context),
        tapOutsideBehavior: TapOutsideBehavior.opaqueDismiss,
        child: Container(
          //elevation: 2.0,
          //decoration: Backgrounds.defaultHcBackgroundLight(),
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(8.0),
          // ),
          child: SingleChildScrollView(
            child: Form(
              key: _detailsFormKey,
              child: Wrap(
                children: <Widget>[
                  Column(
                    //mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 20.0, right: 20.0),
                        child: Text(_updatedEventAggregate.event.useFbRunDetails == 1 ? 'Run data from Facebook' : 'Run data from Harrier Central',
                            textAlign: TextAlign.center, style: headingStyle20Black),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          border: Border.all(width: 2.0),
                          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                        child: Text(
                          'Harrier Central automatically numbers runs. But if there is a reason to override this, you can manually enter a run number here.',
                          style: mediumTextBlack,
                        ),
                      ),
                      Container(
                        color: _focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          onChanged: (String text) {
                            if ((text == null) || (text.isEmpty)) {
                              _absoluteEventNumberController.text = '<auto>';
                            } else if ((text.length > 6) && (text.contains('<auto>'))) {
                              _absoluteEventNumberController.text = _absoluteEventNumberController.text.replaceAll('<auto>', '');
                              _absoluteEventNumberController.selection = TextSelection.fromPosition(TextPosition(offset: _absoluteEventNumberController.text.length));
                            }
                          },
                          maxLines: 1,
                          focusNode: _focusNodeAbsoluteEventNumber,
                          controller: _absoluteEventNumberController,
                          validator: (String val) {
                            if (val.isEmpty) {
                              return 'Please provide an event number or enter \'<auto>\'';
                            } else {
                              return null;
                            }
                          },
                          keyboardType: const TextInputType.numberWithOptions(),
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Event Number (or \'<auto>\')',
                            fillColor: Colors.red,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(),
                            ),
                            hintText: 'Event Number (or \'<auto>\')',
                            hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                        child: Text(
                          'Enter in the hash cash amount here if it is different than the normal hash cash value.',
                          style: mediumTextBlack,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: _focusNodeEventPriceForMembers.hasFocus ? Colors.yellow.shade50 : Colors.white,
                                margin: const EdgeInsets.only(right: 12.5),
                                child: TextFormField(
                                  onChanged: (String text) {
                                    if ((text == null) || (text.isEmpty)) {
                                      _eventPriceForMembersController.text = '<default>';
                                    } else if ((text.length > 9) && (text.contains('<default>'))) {
                                      _eventPriceForMembersController.text = _eventPriceForMembersController.text.replaceAll('<default>', '');
                                      _eventPriceForMembersController.selection = TextSelection.fromPosition(TextPosition(offset: _eventPriceForMembersController.text.length));
                                    }
                                  },
                                  maxLines: 1,
                                  focusNode: _focusNodeEventPriceForMembers,
                                  controller: _eventPriceForMembersController,
                                  keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'H-cash (members)',
                                    fillColor: Colors.red,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(),
                                    ),
                                    hintText: 'H-cash (members)',
                                    hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: _focusNodeEventPriceForNonMembers.hasFocus ? Colors.yellow.shade50 : Colors.white,
                                margin: const EdgeInsets.only(left: 12.5),
                                child: TextFormField(
                                  onChanged: (String text) {
                                    if ((text == null) || (text.isEmpty)) {
                                      _eventPriceForNonMembersController.text = '<default>';
                                    } else if ((text.length > 9) && (text.contains('<default>'))) {
                                      _eventPriceForNonMembersController.text = _eventPriceForNonMembersController.text.replaceAll('<default>', '');
                                      _eventPriceForNonMembersController.selection =
                                          TextSelection.fromPosition(TextPosition(offset: _eventPriceForNonMembersController.text.length));
                                    }
                                  },
                                  maxLines: 1,
                                  focusNode: _focusNodeEventPriceForNonMembers,
                                  controller: _eventPriceForNonMembersController,
                                  keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'H-cash (non-members)',
                                    fillColor: Colors.red,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(),
                                    ),
                                    hintText: 'H-cash (non-members)',
                                    hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                        child: Text(
                          'If you have extra charges associated with your run, such as for dinner, you can put in the price and description here.',
                          style: mediumTextBlack,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: _focusNodeEventPriceForExtras.hasFocus ? Colors.yellow.shade50 : Colors.white,
                                margin: const EdgeInsets.only(right: 12.5),
                                child: TextFormField(
                                  onChanged: (String text) {
                                    if ((text == null) || (text.isEmpty)) {
                                      _eventPriceForExtrasController.text = '<none>';
                                    } else if ((text.length > 6) && (text.contains('<none>'))) {
                                      _eventPriceForExtrasController.text = _eventPriceForExtrasController.text.replaceAll('<none>', '');
                                      _eventPriceForExtrasController.selection = TextSelection.fromPosition(TextPosition(offset: _eventPriceForExtrasController.text.length));
                                    }
                                  },
                                  maxLines: 1,
                                  focusNode: _focusNodeEventPriceForExtras,
                                  controller: _eventPriceForExtrasController,
                                  keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true),
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Price for extras',
                                    fillColor: Colors.red,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(),
                                    ),
                                    hintText: 'Price for extras',
                                    hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: _focusNodeExtrasDescription.hasFocus ? Colors.yellow.shade50 : Colors.white,
                                margin: const EdgeInsets.only(left: 12.5),
                                child: TextFormField(
                                  onChanged: (String text) {
                                    if ((text == null) || (text.isEmpty)) {
                                      _extrasDescriptionController.text = '<none>';
                                    } else if ((text.length > 6) && (text.contains('<none>'))) {
                                      _extrasDescriptionController.text = _extrasDescriptionController.text.replaceAll('<none>', '');
                                      _extrasDescriptionController.selection = TextSelection.fromPosition(TextPosition(offset: _extrasDescriptionController.text.length));
                                    }
                                  },
                                  maxLines: 1,
                                  focusNode: _focusNodeExtrasDescription,
                                  controller: _extrasDescriptionController,
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Extras description',
                                    fillColor: Colors.red,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(),
                                    ),
                                    hintText: 'Extras description',
                                    hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        //color: _focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade500),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            )),
                        child: Column(
                          children: <Widget>[
                            CheckboxFormField(
                              title: const Text('Show run in Harrier Central'),
                              validator: (bool result) {
                                _isVisible = result;
                                return null;
                              },
                              initialValue: _updatedEventAggregate.event.isVisible == 1,
                            ),
                            CheckboxFormField(
                              title: const Text('Count this run'),
                              initialValue: _updatedEventAggregate.event.isCountedRun == 1,
                              validator: (bool result) {
                                _isCountedRun = result;
                                return null;
                              },
                            ),
                            CheckboxFormField(
                              title: const Text('Users can edit run history'),
                              initialValue: _updatedEventAggregate.event.canEditRunAttendence == 1,
                              validator: (bool result) {
                                _usersCanEditRunAttendence = result;
                                return null;
                              },
                            ),
                            CheckboxFormField(
                              title: const Text('Promote this run'),
                              initialValue: _updatedEventAggregate.event.isPromotedEvent == 1,
                              validator: (bool result) {
                                _isPromotedEvent = result;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0, bottom: 0.0, left: 30.0, right: 30.0),
                        child: Text(
                          'Let Hashers around the corner or around the world know about your run if it is interesting to them! By telling us the geographic scope of your run it will help us do a better job promoting it for you!',
                          style: mediumTextBlack,
                        ),
                      ),
                      Container(
                        //color: _focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade500),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            )),
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              title: const Text('Local (normal run)'),
                              leading: Radio<int>(
                                value: 1,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Local (special event)'),
                              leading: Radio<int>(
                                value: 2,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Regional / State'),
                              leading: Radio<int>(
                                value: 3,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Nash Hash (national)'),
                              leading: Radio<int>(
                                value: 4,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Interhash / Continent'),
                              leading: Radio<int>(
                                value: 5,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('World Interhash / Global'),
                              leading: Radio<int>(
                                value: 6,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Other'),
                              leading: Radio<int>(
                                value: 7,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('Not specified'),
                              leading: Radio<int>(
                                value: 0,
                                groupValue: _eventGeographicScope,
                                onChanged: (int value) {
                                  setState(() {
                                    _eventGeographicScope = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10.0, bottom: 60.0, left: 25.0, right: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _isUpdating
                                ? Container(
                                    height: 70.0,
                                    width: 70.0,
                                    child: HcCircularProgressIndicator(key: UniqueKey()),
                                  )
                                : Container(
                                    width: 162.0,
                                    child: ElevatedButton(
                                      child: Text('Save Details', style: buttonLabelStyleMedium),
                                      onPressed: () {
                                        setState(() {
                                          _updateDetails();
                                        });
                                      },
                                    ),
                                  ),
                            // if ((widget.eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                            //   const SizedBox(width: 10.0),
                            //   Container(
                            //     width: 162.0,
                            //     child: ElevatedButton(
                            //       child: Text('Use Facebook', style: buttonLabelStyleMedium),
                            //       onPressed: () {
                            //         setState(() {
                            //           _isUpdating = true;
                            //           _useFacebookDetails();
                            //         });
                            //       },
                            //     ),
                            //   ),
                            // ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void _useFacebookDetails() {
  //   setState(() {
  //     _isUpdating = true;
  //     final EventsService nSvc = EventsService();
  //     nSvc
  //         .addEditEvent(
  //       eventId: widget.eventAggregate.event.eventId,
  //       useFbRunDetails: 1,
  //     )
  //         .then((void dummy) async {
  //       _updatedEventAggregate = await widget.getUpdatedEventAggregate();
  //       setState(() {
  //         _isUpdating = false;
  //         setTextFields();
  //       });
  //     });
  //   });
  // }

  void _updateDetails() {
    if (_detailsFormKey.currentState.validate()) {
      //    If all data are correct then save data to out variables
      _detailsFormKey.currentState.save();

      setState(() {
        _isUpdating = true;
        final EventsService nSvc = EventsService();
        nSvc
            .addEditEvent(
          eventId: widget.eventAggregate.event.eventId,
          eventPriceForMembers: _eventPriceForMembersController.text == '<default>' ? -2 : num.tryParse(_eventPriceForMembersController.text),
          eventPriceForNonMembers: _eventPriceForNonMembersController.text == '<default>' ? -2 : num.tryParse(_eventPriceForNonMembersController.text),
          // note for "auto" the value we send to the server is '0' because this will
          // remove any previous absoluteEventNumber that is stored there
          absoluteEventNumber: _absoluteEventNumberController.text == '<auto>' ? 0 : num.tryParse(_absoluteEventNumberController.text),
          eventPriceForExtras: _eventPriceForExtrasController.text == '<none>' ? -2 : num.tryParse(_eventPriceForExtrasController.text),
          extrasDescription: _extrasDescriptionController.text,
          isCountedRun: _isCountedRun,
          isVisible: _isVisible,
          isPromotedEvent: _isPromotedEvent,
          eventGeographicScope: _eventGeographicScope,
          usersCanEditRunAttendence: _usersCanEditRunAttendence,
        )
            .then((void dummy) async {
          _updatedEventAggregate = await widget.getUpdatedEventAggregate();
          setState(() {
            _isUpdating = false;
            final SnackBar snackBar = SnackBar(
              duration: const Duration(seconds: 3),
              content: const Text(
                'Information has been saved',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
              ),
              backgroundColor: Theme.of(context).accentColor,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          });
        });
      });
    } else {
//    If all data are not valid then start auto validation.
      // setState(() {
      //   _autoValidate = true;
      // });
    }
  }
}

class LocationTab extends StatefulWidget {
  const LocationTab(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _LocationTabState createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Key tabKey;
  RunDetailAggregate _updatedEventAggregate;
  bool _isUpdating = false;

  final MapController mapController = MapController();

  @override
  void initState() {
    _updatedEventAggregate = widget.eventAggregate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return runLocationsBody();
    // return Stack(children: <Widget>[
    //   Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width),
    //   Positioned(top: 0, left: 0, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height, child: runLocationsBody()),
    //   OfflineModeRibbon(
    //     showRibbon: G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected,
    //     lastSync: getDatePref(DatePrefsEnum.lastSuccessfulUserDataSyncAsDate),
    //     ribbonImage: 'images/icons/offline_mode.png',
    //   ),
    // ]);
  }

  Widget runLocationsBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              // Container(
              //   //decoration: Backgrounds.defaultHcBackground(),
              //   height: MediaQuery.of(context).size.height - 300,
              //   child:

              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(_updatedEventAggregate.event.narrowEventLatitude, _updatedEventAggregate.event.narrowEventLongitude),
                  zoom: 14.0,
                  minZoom: 1.0,
                  maxZoom: 18.0,
                  // plugins: <MarkerClusterPlugin>[
                  //   MarkerClusterPlugin(),
                  // ],
                ),
                layers: <LayerOptions>[
                  TileLayerOptions(
                      urlTemplate:
                          //'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      //subdomains: ['a', 'b', 'c']),
                      subdomains: <String>['mt0', 'mt1', 'mt2', 'mt3']),
                  MarkerLayerOptions(
                    markers: <Marker>[
                      Marker(
                        height: 50.0,
                        width: 50.0,
                        point: LatLng(G0<DeviceInfo>().deviceLat + .0, G0<DeviceInfo>().deviceLon + .0),
                        builder: (BuildContext ctx) => Container(
                          padding: const EdgeInsets.all(1.0),
                          height: 50.0,
                          width: 50.0,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Image.asset(
                              'images/other/map_current_location.png',
                              height: 50.0,
                              width: 50.0,
                            ),
                          ),
                        ),
                      ),
                      Marker(
                        width: 120.0,
                        height: 120.0,
                        point: LatLng(_updatedEventAggregate.event.narrowEventLatitude + .0, _updatedEventAggregate.event.narrowEventLongitude + .0),
                        builder: (BuildContext ctx) => GestureDetector(
                          //onTap: () => _launchMaps(widget.futureRun.event),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 58.0),
                            child: Image.asset('images/icons/map_pin_foot.png'),
                            //child: FlutterLogo(colors: Colors.purple),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),

              IgnorePointer(
                ignoring: true,
                child: Image.asset('images/other/map_center_target.png', height: 300.0, width: 300.0),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 40.0,
                child: Container(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                  child: Text(_updatedEventAggregate.event.useFbLatLon == 1 ? 'Location from Facebook' : 'Location from Harrier Central',
                      textAlign: TextAlign.center, style: headingStyle20Black),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    border: Border.all(width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              Positioned(
                right: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    mapController.move(
                      LatLng(G0<DeviceInfo>().deviceLat + .0, G0<DeviceInfo>().deviceLon + .0),
                      mapController.zoom,
                    );
                  },
                  child: Container(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset('images/other/set_map_to_current_location.png'),
                  ),
                ),
              ),
              Positioned(
                right: 70.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    mapController.move(
                      LatLng(_updatedEventAggregate.event.narrowEventLatitude + .0, _updatedEventAggregate.event.narrowEventLongitude + .0),
                      mapController.zoom,
                    );
                  },
                  child: Container(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset('images/other/set_map_to_event_location.png'),
                  ),
                ),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 80.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _isUpdating
                        ? Container(
                            height: 70.0,
                            width: 70.0,
                            child: HcCircularProgressIndicator(key: UniqueKey()),
                          )
                        : ElevatedButton(
                            child: Text('Set Location', style: buttonLabelStyleMedium),
                            onPressed: () {
                              setState(() {
                                _isUpdating = true;
                                final EventsService nSvc = EventsService();
                                nSvc
                                    .addEditEvent(
                                  eventId: widget.eventAggregate.event.eventId,
                                  lat: mapController.center.latitude,
                                  lon: mapController.center.longitude,
                                  useFbLatLon: 0,
                                )
                                    .then((void dummy) async {
                                  _updatedEventAggregate = await widget.getUpdatedEventAggregate();
                                  setState(() {
                                    _isUpdating = false;
                                    final SnackBar snackBar = SnackBar(
                                      duration: const Duration(seconds: 3),
                                      content: const Text(
                                        'Updated location saved in Harrier Central',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
                                      ),
                                      backgroundColor: Theme.of(context).accentColor,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                  });
                                });

                                //_showEventPopup(_calendarController.selectedDay);
                              });
                            },
                          ),
                    if ((widget.eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                      ElevatedButton(
                        child: Text('Use Facebook', style: buttonLabelStyleMedium),
                        onPressed: () {
                          setState(() {
                            _isUpdating = true;
                            final EventsService nSvc = EventsService();
                            nSvc
                                .addEditEvent(
                              eventId: widget.eventAggregate.event.eventId,
                              useFbLatLon: 1,
                            )
                                .then((void dummy) async {
                              _updatedEventAggregate = await widget.getUpdatedEventAggregate();
                              setState(() {
                                _isUpdating = false;
                                final SnackBar snackBar = SnackBar(
                                  duration: const Duration(seconds: 3),
                                  content: const Text(
                                    'Location is being synced from Facebook',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
                                  ),
                                  backgroundColor: Theme.of(context).accentColor,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              });
                            });
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DetailsTab extends StatefulWidget {
  const DetailsTab(this.eventAggregate, this.getUpdatedEventAggregate, {Key key}) : super(key: key);

  final RunDetailAggregate eventAggregate;
  final Function getUpdatedEventAggregate;

  @override
  _DetailsTabState createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  RunDetailAggregate _updatedEventAggregate;
  bool _isUpdating = false;

  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();

  final FocusNode _focusNodeDatetime = FocusNode();
  final FocusNode _focusNodeEventName = FocusNode();
  final FocusNode _focusNodeEventDescription = FocusNode();
  final FocusNode _focusNodeLocationOneLineDesc = FocusNode();

  final TextEditingController _eventDatetimeController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _locationOneLineDescController = TextEditingController();

  @override
  void dispose() {
    _eventDatetimeController.dispose();
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _locationOneLineDescController.dispose();

    _focusNodeDatetime.dispose();
    _focusNodeEventName.dispose();
    _focusNodeEventDescription.dispose();
    _focusNodeLocationOneLineDesc.dispose();

    super.dispose();
  }

  void setTextFields() {
    _eventNameController.text = _updatedEventAggregate.event.eventName;
    _eventDescriptionController.text = _updatedEventAggregate.event.eventDescription;
    _eventDatetimeController.text = _updatedEventAggregate.event.eventStartDatetime.toString();
    _locationOneLineDescController.text = _updatedEventAggregate.event.locationOneLineDesc;
  }

  @override
  void initState() {
    _updatedEventAggregate = widget.eventAggregate;
    setTextFields();

    _focusNodeEventName.addListener(() {
      setState(() {});
    });

    _focusNodeEventDescription.addListener(() {
      setState(() {});
    });

    _focusNodeDatetime.addListener(() {
      setState(() {});
    });

    _focusNodeLocationOneLineDesc.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: <KeyboardActionsItem>[
        KeyboardActionsItem(
          focusNode: _focusNodeEventName,
        ),
        KeyboardActionsItem(
          focusNode: _focusNodeEventDescription,
        ),
        // KeyboardActionsItem(
        //   focusNode: focusNodeDatetime,
        // ),
        KeyboardActionsItem(
          focusNode: _focusNodeLocationOneLineDesc,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(
          color: Colors.red.shade700,
          size: 35,
        ),
      ),
      child: KeyboardActions(
        config: _buildConfig(context),
        tapOutsideBehavior: TapOutsideBehavior.opaqueDismiss,
        child: Container(
          //elevation: 2.0,
          //decoration: Backgrounds.defaultHcBackgroundLight(),
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(8.0),
          // ),
          child: SingleChildScrollView(
            child: Form(
              key: _detailsFormKey,
              child: Wrap(
                children: <Widget>[
                  Column(
                    //mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 20.0, right: 20.0),
                        child: Text(_updatedEventAggregate.event.useFbRunDetails == 1 ? 'Run data from Facebook' : 'Run data from Harrier Central',
                            textAlign: TextAlign.center, style: headingStyle20Black),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          border: Border.all(width: 2.0),
                          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                      Container(
                        color: _focusNodeEventName.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          focusNode: _focusNodeEventName,
                          controller: _eventNameController,
                          minLines: 1,
                          maxLines: 2,
                          onChanged: (String text) {
                            //widget.EventName = text;
                          },
                          keyboardType: TextInputType.multiline,
                          validator: (String val) {
                            if (val.isEmpty) {
                              return 'Please provide an event name';
                            } else {
                              return null;
                            }
                          },
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Event name',
                            fillColor: Colors.red,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(),
                            ),
                            hintText: 'Event Name',
                            hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        color: _focusNodeEventDescription.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          onChanged: (String text) {
                            //widget.EventDescription = text;
                          },
                          maxLines: null,
                          focusNode: _focusNodeEventDescription,
                          controller: _eventDescriptionController,
                          validator: (String val) {
                            if (val.isEmpty) {
                              return 'Please provide an event description';
                            } else {
                              return null;
                            }
                          },
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Event Description',
                            fillColor: Colors.red,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(),
                            ),
                            hintText: 'Event Description',
                            hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        color: _focusNodeLocationOneLineDesc.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          focusNode: _focusNodeLocationOneLineDesc,
                          controller: _locationOneLineDescController,
                          minLines: 1,
                          maxLines: 2,
                          onChanged: (String text) {
                            //widget.EventName = text;
                          },
                          keyboardType: TextInputType.multiline,
                          validator: (String val) {
                            if (val.isEmpty) {
                              return 'Please provide a location description';
                            } else {
                              return null;
                            }
                          },
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Location one-line description',
                            fillColor: Colors.red,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(),
                            ),
                            hintText: 'Location description',
                            hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        color: _focusNodeDatetime.hasFocus ? Colors.yellow.shade50 : Colors.white,
                        margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 25.0, right: 25.0),
                        child: DateTimePicker(
                          decoration: InputDecoration(
                            labelText: 'Date / Time',
                            fillColor: Colors.red,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: const BorderSide(),
                            ),
                            //hintText: 'Event Number (or \'<auto>\')',
                            hintStyle: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
                          ),
                          focusNode: _focusNodeDatetime,
                          controller: _eventDatetimeController,
                          type: DateTimePickerType.dateTime,
                          use24HourFormat: false,
                          locale: const Locale('en', 'US'),
                          dateMask: 'E, d MMM, yyyy, h:mm a',
                          //initialValue: DateTime.now().toString(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          //icon: const Icon(Icons.event),
                          dateLabelText: 'Date',
                          timeLabelText: 'Hour',
                          // selectableDayPredicate: (DateTime date) {
                          //   // Disable weekend days to select from the calendar
                          //   if (date.weekday == 6 || date.weekday == 7) {
                          //     return false;
                          //   }

                          //   return true;
                          // },
                          // onChanged: (val) => print(val),
                          validator: (String val) {
                            //print(val);
                            return null;
                          },
                          //onSaved: (val) => print(val),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10.0, bottom: 60.0, left: 25.0, right: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _isUpdating
                                ? Container(
                                    height: 70.0,
                                    width: 70.0,
                                    child: HcCircularProgressIndicator(key: UniqueKey()),
                                  )
                                : Container(
                                    width: 162.0,
                                    child: ElevatedButton(
                                      child: Text('Save Details', style: buttonLabelStyleMedium),
                                      onPressed: () {
                                        setState(() {
                                          _updateDetails();
                                        });
                                      },
                                    ),
                                  ),
                            if ((widget.eventAggregate.event.eventFacebookId != null) && (!_isUpdating)) ...<Widget>[
                              const SizedBox(width: 10.0),
                              Container(
                                width: 162.0,
                                child: ElevatedButton(
                                  child: Text('Use Facebook', style: buttonLabelStyleMedium),
                                  onPressed: () {
                                    setState(() {
                                      _isUpdating = true;
                                      _useFacebookDetails();
                                    });
                                  },
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _useFacebookDetails() {
    setState(() {
      _isUpdating = true;
      final EventsService nSvc = EventsService();
      nSvc
          .addEditEvent(
        eventId: widget.eventAggregate.event.eventId,
        useFbRunDetails: 1,
      )
          .then((void dummy) async {
        _updatedEventAggregate = await widget.getUpdatedEventAggregate();
        setState(() {
          _isUpdating = false;
          setTextFields();
          final SnackBar snackBar = SnackBar(
            duration: const Duration(seconds: 3),
            content: const Text(
              'Run details being synced from Facebook',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
            ),
            backgroundColor: Theme.of(context).accentColor,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      });
    });
  }

  void _updateDetails() {
    if (_detailsFormKey.currentState.validate()) {
      //    If all data are correct then save data to out variables
      _detailsFormKey.currentState.save();

      setState(() {
        _isUpdating = true;
        final EventsService nSvc = EventsService();
        nSvc
            .addEditEvent(
          eventId: widget.eventAggregate.event.eventId,
          eventName: _eventNameController.text,
          eventStartDatetime: DateTime.tryParse(_eventDatetimeController.text),
          eventDescription: _eventDescriptionController.text,
          locationOneLineDesc: _locationOneLineDescController.text,
          useFbRunDetails: 0,
        )
            .then((void dummy) async {
          _updatedEventAggregate = await widget.getUpdatedEventAggregate();
          setState(() {
            _isUpdating = false;
            final SnackBar snackBar = SnackBar(
              duration: const Duration(seconds: 3),
              content: const Text(
                'Run details have been saved',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'AvenirNextCondensedDemiBold', fontStyle: FontStyle.normal, fontSize: 20.0, height: 0.85),
              ),
              backgroundColor: Theme.of(context).accentColor,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          });
        });
      });
    } else {
//    If all data are not valid then start auto validation.
      // setState(() {
      //   _autoValidate = true;
      // });
    }
  }
}

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({Widget title, FormFieldSetter<bool> onSaved, FormFieldValidator<bool> validator, bool initialValue = false})
      : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: initialValue,
            builder: (FormFieldState<bool> state) {
              return CheckboxListTile(
                dense: state.hasError,
                title: title,
                value: state.value,
                onChanged: state.didChange,
                subtitle: state.hasError
                    ? Builder(
                        builder: (BuildContext context) => Text(
                          state.errorText,
                          style: TextStyle(color: Theme.of(context).errorColor),
                        ),
                      )
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
              );
            });
}
