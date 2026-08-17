import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/run_admin/edit_run_details_controller.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

class EditRunDetailsPage extends StatelessWidget {
  const EditRunDetailsPage(this.isNewRun, this.eventAggregate, {super.key});

  final bool isNewRun;
  final RunAdminAggregate eventAggregate;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditRunDetailsController>(
      // global: false keeps this instance out of GetX's registry, so pushing a
      // second editor on top of the first cannot collide with it.
      global: false,
      init: EditRunDetailsController(
        isNewRun: isNewRun,
        aggregate: eventAggregate,
      ),
      // A controller GetBuilder never registered is a controller GetBuilder
      // never deletes — its dispose() only calls delete() for instances found
      // in the registry. Without this the editor would leak 16 text
      // controllers, 16 focus nodes and a TabController on every open.
      // onDelete is guarded against running twice.
      dispose: (GetBuilderState<EditRunDetailsController> state) =>
          state.controller?.onDelete(),
      builder: (EditRunDetailsController c) => _buildPage(context, c),
    );
  }

  /// The anchored save bar. Always on screen so the button never has to be
  /// scrolled to, and greyed out until something actually changes.
  ///
  /// This is the one part of the page that reacts on its own. Typing only calls
  /// `recomputeDirty()`, never `update()`, so a keystroke repaints this bar and
  /// nothing else — the tabs and the map stay untouched.
  Widget _buildSaveBar(EditRunDetailsController c) {
    return Obx(() {
      // For a new run the bar is the wizard's Next/Finish, so it stays live
      // even on a tab the user chose not to fill in.
      final bool enabled =
          (c.isDirty.value || c.isNewRun) && !c.isUpdating.value;
      final String label = c.isNewRun
          ? (c.currentTab.value == EditingTabEnum.other ? 'Finish' : 'Next')
          : 'Save changes to Harrier Central';

      return Container(
        height: 70.0,
        color: Colors.yellow[100],
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Center(
          child: c.isUpdating.value
              ? const SizedBox(
                  height: 45.0,
                  width: 45.0,
                  child: HcAppCircularProgressIndicator(key: Key('331904772')),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hc_red,
                      disabledBackgroundColor: Colors.grey,
                      disabledForegroundColor: Colors.white70,
                    ),
                    onPressed: enabled ? c.onSaveBarPressed : null,
                    child: Text(label, style: ts_button),
                  ),
                ),
        ),
      );
    });
  }

  Container _genericTextField({
    required FocusNode focusNode,
    required TextEditingController textEditignController,
    required String labelText,
    required bool useValidator,
  }) {
    return Container(
      color: focusNode.hasFocus ? Colors.yellow.shade50 : Colors.white,
      margin: const EdgeInsets.only(
        top: 10.0,
        bottom: 5.0,
        left: 25.0,
        right: 25.0,
      ),
      child: TextFormField(
        focusNode: focusNode,
        controller: textEditignController,
        minLines: 1,
        maxLines: 2,
        onChanged: (String text) {
          //widget.EventName = text;
        },
        keyboardType: TextInputType.multiline,
        validator: (String? val) {
          if (!useValidator) {
            return null;
          }
          if ((val ?? '').isEmpty) {
            return 'Please provide a ${labelText.toLowerCase()}';
          } else {
            return null;
          }
        },
        textCapitalization: TextCapitalization.sentences,
        style: ts_titleMediumBlack,
        decoration: InputDecoration(
          labelText: labelText,
          fillColor: hc_red,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(),
          ),
          hintText: labelText,
          hintStyle: ts_hint,
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, EditRunDetailsController c) {
    // The Map and Image tabs act on a picked point or an uploaded file rather
    // than on form content, so they keep their own buttons and get no save bar.
    final bool showSaveBar =
        c.currentTab.value == EditingTabEnum.details ||
        c.currentTab.value == EditingTabEnum.address ||
        c.currentTab.value == EditingTabEnum.other;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        final bool leave = await c.confirmDiscardOnExit();
        if (leave && context.mounted) {
          navigator.pop();
        }
      },
      child: AppScaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: themeAppBarBackground,
          iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
          title: Text('Edit run details', style: ts_appBarTitle),
        ),
        bottomNavigationBar: showSaveBar
            ? SafeArea(top: false, child: _buildSaveBar(c))
            : null,
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
                  height: 45,
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
                ),
              ),
              Positioned(
                top: -25,
                left: 0,
                right: 0,
                child: Container(
                  //color: Colors.red,
                  //width: 200,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    //width: 140.0,
                    height: 75.0,
                    // reviewed for 2.0+
                    child: TabBar(
                      onTap: (void _) {
                        c.mutate(() {});
                      },
                      labelStyle: ts_tabSelected,
                      unselectedLabelStyle: ts_tabUnselected,
                      isScrollable: false,
                      unselectedLabelColor: Colors.black,
                      labelColor: Colors.white,
                      labelPadding: const EdgeInsets.only(
                        top: 5,
                        left: 0,
                        right: 0,
                      ),
                      indicatorSize: TabBarIndicatorSize.label,
                      // labelPadding: EdgeInsets.symmetric(
                      //   horizontal: 20.0,
                      // ),
                      indicatorPadding: EdgeInsets.symmetric(
                        horizontal: -15.0,
                        vertical: 13.0,
                      ),
                      indicator: BoxDecoration(
                        color: hc_red,
                        borderRadius: BorderRadius.circular(999),
                      ),

                      tabs: c.tabs,
                      controller: c.tabController,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 46,
                bottom: 0,
                child: SizedBox(
                  //key: _tabKey,
                  //color: Colors.teal,
                  width: MediaQuery.sizeOf(context).width,
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: c.tabController,
                    children: <Widget>[
                      _buildDetailsPage(context, c),
                      _buildAddressPage(context, c),
                      _buildMapPage(c),
                      _buildImagePage(c),
                      _buildOtherDetailsPage(context, c),
                      //OtherInfoTab(c.eventAggregate, widget.getUpdatedEventAggregate),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyboardActionsConfig _buildConfig(
    BuildContext context,
    EditRunDetailsController c,
  ) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: <KeyboardActionsItem>[
        KeyboardActionsItem(focusNode: c.focusNodeEventName),
        KeyboardActionsItem(focusNode: c.focusNodeEventDescription),

        KeyboardActionsItem(focusNode: c.focusNodeAbsoluteEventNumber),
        KeyboardActionsItem(focusNode: c.focusNodeEventPriceForMembers),
        KeyboardActionsItem(focusNode: c.focusNodeEventPriceForNonMembers),
        KeyboardActionsItem(focusNode: c.focusNodeEventPriceForExtras),
        KeyboardActionsItem(focusNode: c.focusNodeExtrasDescription),
        KeyboardActionsItem(focusNode: c.focusNodeHares),

        // KeyboardActionsItem(
        //   focusNode: focusNodeDatetime,
        // ),
        KeyboardActionsItem(focusNode: c.focusNodeLocationOneLineDesc),
      ],
    );
  }

  Widget _buildAddressPage(BuildContext context, EditRunDetailsController c) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(color: hc_red, size: 35),
      ),
      child: KeyboardActions(
        config: _buildConfig(context, c),
        tapOutsideBehavior: TapOutsideBehavior.none,
        child: SingleChildScrollView(
          child: Form(
            key: c.addressFormKey,
            child: Wrap(
              children: <Widget>[
                Column(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(
                        top: 5.0,
                        bottom: 5.0,
                        left: 20.0,
                        right: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        c.eventAggregate.event.useFbRunDetails == 1
                            ? c
                                          .eventAggregate
                                          .event
                                          .eventInboundIntegrationId >=
                                      integrationPlatformNames.length
                                  ? 'Run data from external source'
                                  : 'Run data from ${integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}'
                            : 'Run data from Harrier Central',
                        textAlign: TextAlign.center,
                        style: ts_headingBlack,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 15.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        icon: const Icon(Icons.search, size: 20),
                        label: Text('Look up address', style: ts_button),
                        onPressed: c.openLocationLookup,
                      ),
                    ),
                    _genericTextField(
                      focusNode: c.focusNodeStreetAddress,
                      textEditignController: c.locationStreetController,
                      labelText: 'Street Address',
                      useValidator: false,
                    ),
                    _genericTextField(
                      focusNode: c.focusNodeCity,
                      textEditignController: c.locationCityController,
                      labelText: 'City',
                      useValidator: false,
                    ),
                    _genericTextField(
                      focusNode: c.focusNodeRegion,
                      textEditignController: c.locationRegionController,
                      labelText: 'Region/State',
                      useValidator: false,
                    ),
                    _genericTextField(
                      focusNode: c.focusNodeSubRegion,
                      textEditignController: c.locationSubRegionController,
                      labelText: 'Sub-Region/County',
                      useValidator: false,
                    ),
                    _genericTextField(
                      focusNode: c.focusNodePostCode,
                      textEditignController: c.locationPostCodeController,
                      labelText: 'Postal Code',
                      useValidator: false,
                    ),
                    _genericTextField(
                      focusNode: c.focusNodeCountry,
                      textEditignController: c.locationCountryController,
                      labelText: 'Country',
                      useValidator: false,
                    ),
                    const SizedBox(height: 20.0),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPage(BuildContext context, EditRunDetailsController c) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(color: hc_red, size: 35),
      ),
      child: KeyboardActions(
        config: _buildConfig(context, c),
        tapOutsideBehavior: TapOutsideBehavior.none,
        child: SingleChildScrollView(
          child: Form(
            key: c.detailsFormKey,
            child: Wrap(
              children: <Widget>[
                Column(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(
                        top: 5.0,
                        bottom: 5.0,
                        left: 20.0,
                        right: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        c.eventAggregate.event.useFbRunDetails == 1
                            ? c
                                          .eventAggregate
                                          .event
                                          .eventInboundIntegrationId >=
                                      integrationPlatformNames.length
                                  ? 'Run data from external source'
                                  : 'Run data from ${integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}'
                            : 'Run data from Harrier Central',
                        textAlign: TextAlign.center,
                        style: ts_headingBlack,
                      ),
                    ),
                    Container(
                      color: c.focusNodeEventName.hasFocus
                          ? Colors.yellow.shade50
                          : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: TextFormField(
                        focusNode: c.focusNodeEventName,
                        controller: c.eventNameController,
                        minLines: 1,
                        maxLines: 2,
                        onChanged: (String text) {
                          //widget.EventName = text;
                        },
                        keyboardType: TextInputType.multiline,
                        validator: (String? val) {
                          if ((val ?? '').isEmpty) {
                            return 'Please provide an event name';
                          } else {
                            return null;
                          }
                        },
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Event name',
                          fillColor: hc_red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: 'Event Name',
                          hintStyle: ts_hint,
                        ),
                      ),
                    ),
                    Container(
                      color: c.focusNodeEventDescription.hasFocus
                          ? Colors.yellow.shade50
                          : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: TextFormField(
                        onChanged: (String text) {
                          //widget.EventDescription = text;
                        },
                        maxLines: null,
                        focusNode: c.focusNodeEventDescription,
                        controller: c.eventDescriptionController,
                        validator: (String? val) {
                          if ((val ?? '').isEmpty) {
                            return 'Please provide an event description';
                          } else {
                            return null;
                          }
                        },
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Event Description',
                          fillColor: hc_red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: 'Event Description',
                          hintStyle: ts_hint,
                        ),
                      ),
                    ),
                    Container(
                      color: c.focusNodeLocationOneLineDesc.hasFocus
                          ? Colors.yellow.shade50
                          : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: TextFormField(
                        focusNode: c.focusNodeLocationOneLineDesc,
                        controller: c.locationOneLineDescController,
                        minLines: 1,
                        maxLines: 2,
                        onChanged: (String text) {
                          //widget.EventName = text;
                        },
                        keyboardType: TextInputType.multiline,
                        validator: (String? val) {
                          if ((val ?? '').isEmpty) {
                            return 'Please provide a location description';
                          } else {
                            return null;
                          }
                        },
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Location one-line description',
                          fillColor: hc_red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: 'Location description',
                          hintStyle: ts_hint,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: 'Lookup location',
                            onPressed: c.openLocationLookup,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: c.focusNodeDatetime.hasFocus
                          ? Colors.yellow.shade50
                          : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      // child: OmniDateTimePicker(
                      //   onDateTimeChanged: (value) {},
                      // ),
                      child: TextFormField(
                        controller: c.eventDatetimeController,
                        focusNode: c.focusNodeDatetime,
                        readOnly: true,
                        onTap: () async {
                          final DateFormat formatter = DateFormat(
                            'E, d MMM, yyyy, h:mm a',
                          );
                          DateTime eventStartDate =
                              formatter.tryParse(
                                c.eventDatetimeController.text,
                              ) ??
                              DateTime.now();

                          // Dismiss keyboard (just in case)
                          FocusScope.of(context).requestFocus(FocusNode());

                          // Show date picker
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: eventStartDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate == null) return;

                          if (context.mounted) {
                            // Show time picker
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                eventStartDate,
                              ),
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(
                                    context,
                                  ).copyWith(alwaysUse24HourFormat: false),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedTime == null) return;

                            final selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // Format to desired string
                            final formatted = DateFormat(
                              'E, d MMM, yyyy, h:mm a',
                            ).format(selectedDateTime);

                            // Update the controller
                            c.eventDatetimeController.text = formatted;

                            // Optionally trigger rebuild or setState
                            c.mutate(() {});
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Date / Time',
                          fillColor: hc_red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintStyle: ts_hint,
                        ),
                        validator: (String? val) {
                          return null; // or your custom validation
                        },
                      ),

                      // DateTimePicker(
                      //   onFieldSubmitted: (value) {
                      //     c.eventDatetimeController.text = value;
                      //     c.mutate(() {});
                      //   },
                      //   onChanged: (value) {
                      //     c.eventDatetimeController.text = value;
                      //     c.mutate(() {});
                      //   },
                      //   onSaved: (newValue) {
                      //     c.eventDatetimeController.text = newValue ?? '';
                      //     c.mutate(() {});
                      //   },
                      //   decoration: InputDecoration(
                      //     labelText: 'Date / Time',
                      //     fillColor: hc_red,
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10.0),
                      //       borderSide: const BorderSide(),
                      //     ),
                      //     hintStyle: ts_hint,
                      //   ),
                      //   focusNode: c.focusNodeDatetime,
                      //   controller: c.eventDatetimeController,
                      //   type: DateTimePickerType.dateTime,
                      //   use24HourFormat: false,
                      //   locale: const Locale('en', 'US'),
                      //   dateMask: 'E, d MMM, yyyy, h:mm a',
                      //   firstDate: DateTime(2000),
                      //   lastDate: DateTime(2100),
                      //   dateLabelText: 'Date',
                      //   timeLabelText: 'Hour',
                      //   validator: (String? val) {
                      //     return null;
                      //   },
                      // ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(
                        top: 5.0,
                        bottom: 5.0,
                        left: 20.0,
                        right: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        c.eventAggregate.event.useFbRunDetails == 1
                            ? c
                                          .eventAggregate
                                          .event
                                          .eventInboundIntegrationId >=
                                      integrationPlatformNames.length
                                  ? 'Run data from external source'
                                  : 'Run data from ${integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}'
                            : 'Run data from Harrier Central',
                        textAlign: TextAlign.center,
                        style: ts_headingBlack,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    if ((c.eventAggregate.event.eventFacebookId != null) &&
                        (!c.isUpdating.value)) ...<Widget>[
                      ElevatedButton(
                        child: Text(
                          'Copy data from ${c.eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                          style: ts_button,
                        ),
                        onPressed: () async {
                          await c.useExternalSourceDetails();
                          c.mutate(() {});
                        },
                      ),
                    ],
                    const SizedBox(height: 80.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePage(EditRunDetailsController c) {
    return FutureBuilder<File?>(
      future: c.imageFromGallery,
      builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
        if (snapshot.hasData) {
          if (c.isUpdating.value) {
            return const SizedBox(
              height: 70.0,
              width: 70.0,
              child: HcAppCircularProgressIndicator(key: Key('8812340021')),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20.0),
                  child: Image.file(snapshot.data!, fit: BoxFit.scaleDown),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      40,
                    ), // double.infinity is the width and 30 is the height
                  ),
                  child: Text('Use this image', style: ts_button),
                  onPressed: () async {
                    if ((c.eventAggregate.event.eventId.isNotEmpty) &&
                        (c.eventAggregate.event.eventId != GUID_EMPTY)) {
                      c.mutate(() {
                        c.isUpdating.value = true;
                      });
                      final String fileName = await c.upload(
                        snapshot.data!,
                        c.eventAggregate.event.eventId,
                      );

                      final EventsService nSvc = EventsService();
                      final String eventId = await nSvc.addEditEvent(
                        eventId: c.eventAggregate.event.eventId,
                        kennelId: c.eventAggregate.event.kennelId,
                        eventImageUrl: BASE_EVENT_IMAGE_URL + fileName,
                        useFbImage: 0,
                      );

                      await c.refreshAfterSave(eventId);

                      if (c.isNewRun) {
                        c.mutate(() {
                          c.isUpdating.value = false;
                        });
                        await Future<void>.delayed(
                          const Duration(milliseconds: 1000),
                        );
                        c.tabController.animateTo(c.currentTab.value.next);
                      } else {
                        c.mutate(() {
                          c.isUpdating.value = false;
                        });

                        final SnackBar snackBar = SnackBar(
                          duration: const Duration(seconds: 3),
                          content: Text(
                            'Event image has been updated',
                            textAlign: TextAlign.center,
                            style: ts_titleCondensed,
                          ),
                          backgroundColor: hc_blue,
                        );

                        ScaffoldMessenger.of(
                          navigatorKey.currentContext!,
                        ).showSnackBar(snackBar);
                      }
                    }
                  },
                ),
              ),
              //const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      40,
                    ), // double.infinity is the width and 30 is the height
                  ),
                  child: Text('Select again from gallery', style: ts_button),
                  onPressed: () async {
                    await c.getImageFromGallery(ImageSource.gallery);
                  },
                ),
              ),
              if ((c.eventAggregate.event.eventFacebookId != null) &&
                  (!c.isUpdating.value)) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        40,
                      ), // double.infinity is the width and 30 is the height
                    ),
                    child: Text(
                      'Use image from ${integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                      style: ts_button,
                    ),
                    onPressed: () async {
                      c.mutate(() {
                        c.isUpdating.value = true;
                      });
                      final EventsService nSvc = EventsService();
                      final String eventId = await nSvc.addEditEvent(
                        eventId: c.eventAggregate.event.eventId,
                        kennelId: c.eventAggregate.event.kennelId,
                        useFbImage: 1,
                      );

                      await c.refreshAfterSave(eventId);
                      c.mutate(() {
                        c.isUpdating.value = false;
                        final SnackBar snackBar = SnackBar(
                          duration: const Duration(seconds: 3),
                          content: Text(
                            'Image is being synced from ${integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                            textAlign: TextAlign.center,
                            style: ts_titleCondensedBlack,
                          ),
                          backgroundColor: hc_blue,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      });
                    },
                  ),
                ),
              ],
              //const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      40,
                    ), // double.infinity is the width and 30 is the height
                  ),
                  child: Text('Use original image', style: ts_button),
                  onPressed: () {
                    c.mutate(() {
                      c.imageFromGallery = Future<File?>.value(null);
                    });
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        } else {
          return c.isUpdating.value
              ? const SizedBox(
                  height: 70.0,
                  width: 70.0,
                  child: HcAppCircularProgressIndicator(key: Key('6669001123')),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (c.eventAggregate.event.eventImage != null) ...<Widget>[
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(20.0),
                          //height: deviceInfo.deviceHeight - 235,
                          child: Column(
                            //mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: c.eventAggregate.event.eventImage!,
                                  // errorWidget:
                                  //     (BuildContext context, String url, Exception error) =>
                                  //         const  Icon(Icons.error),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          40,
                                        ), // double.infinity is the width and 30 is the height
                                      ),
                                      child: Text(
                                        'Select from gallery',
                                        style: ts_button,
                                      ),
                                      onPressed: () async {
                                        await c.getImageFromGallery(
                                          ImageSource.gallery,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          40,
                                        ),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                      child: Text(
                                        'Delete image',
                                        style: ts_button,
                                      ),
                                      onPressed: () async {
                                        final bool?
                                        confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext ctx) => AlertDialog(
                                            title: const Text('Delete image'),
                                            content: const Text(
                                              'Remove the image from this run? This cannot be undone.',
                                            ),
                                            actions: <Widget>[
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.teal,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red[700],
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed != true) return;
                                        c.mutate(() {
                                          c.isUpdating.value = true;
                                        });
                                        final EventsService nSvc =
                                            EventsService();
                                        final String
                                        eventId = await nSvc.addEditEvent(
                                          eventId:
                                              c.eventAggregate.event.eventId,
                                          kennelId:
                                              c.eventAggregate.event.kennelId,
                                          deleteEventImage: true,
                                        );
                                        await c.refreshAfterSave(eventId);
                                        c.mutate(() {
                                          c.isUpdating.value = false;
                                          final SnackBar snackBar = SnackBar(
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                            content: Text(
                                              'Image has been removed',
                                              textAlign: TextAlign.center,
                                              style: ts_titleCondensed,
                                            ),
                                            backgroundColor: hc_blue,
                                          );
                                          ScaffoldMessenger.of(
                                            navigatorKey.currentContext!,
                                          ).showSnackBar(snackBar);
                                        });
                                      },
                                    ),
                                  ),
                                  if ((c.eventAggregate.event.eventFacebookId !=
                                          null) &&
                                      (!c.isUpdating.value)) ...<Widget>[
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(
                                            double.infinity,
                                            40,
                                          ), // double.infinity is the width and 30 is the height
                                        ),
                                        child: Text(
                                          'Use ${c.eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                                          style: ts_button,
                                        ),
                                        onPressed: () async {
                                          c.mutate(() {
                                            c.isUpdating.value = true;
                                          });
                                          final EventsService nSvc =
                                              EventsService();
                                          final String eventId = await nSvc
                                              .addEditEvent(
                                                eventId: c
                                                    .eventAggregate
                                                    .event
                                                    .eventId,
                                                useFbImage: 1,
                                              );

                                          await c.refreshAfterSave(eventId);
                                          c.mutate(() {
                                            c.isUpdating.value = false;
                                            final SnackBar snackBar = SnackBar(
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                              content: Text(
                                                'Image is being synced from ${c.eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                                                textAlign: TextAlign.center,
                                                style: ts_titleCondensedBlack,
                                              ),
                                              backgroundColor: hc_blue,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(snackBar);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (c.eventAggregate.event.eventImage == null) ...<Widget>[
                      Text(
                        'No image provided',
                        textAlign: TextAlign.center,
                        style: ts_headingVeryLarge.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 50.0,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              40,
                            ), // double.infinity is the width and 30 is the height
                          ),
                          child: Text('Select from gallery', style: ts_button),
                          onPressed: () async {
                            await c.getImageFromGallery(ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                    if (c.isNewRun) ...<Widget>[
                      ElevatedButton(
                        child: Text('Skip', style: ts_button),
                        onPressed: () {
                          c.mutate(() {
                            c.tabController.animateTo(c.currentTab.value.next);
                          });
                        },
                      ),
                      const SizedBox(width: 20.0),
                    ],
                  ],
                );
        }
      },
    );
  }

  Widget _buildMapPage(EditRunDetailsController c) {
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
              //   height: MediaQuery.sizeOf(context).height - 300,
              //   child:
              EditorMap(
                c.eventAggregate.extensions.latitude == null
                    ? null
                    : latlng.LatLng(
                        c.eventAggregate.extensions.latitude!,
                        c.eventAggregate.extensions.longitude!,
                      ),
                c.mapCenter,
                latlng.LatLng(
                  c.eventAggregate.extensions.kenlLat,
                  c.eventAggregate.extensions.kenlLon,
                ),
                1.0,
                18.0,
                14.0,
                c.trueNorthLock,
                c.mapKey,
                mapMoved: (latlng.LatLng newPosition) {
                  c.mapCenter = newPosition;
                },
              ),
              if ((c.mapCenter.latitude == CLEAR_LATLONG) ||
                  (c.mapCenter.longitude == CLEAR_LATLONG)) ...<Widget>[
                GestureDetector(
                  onTapDown: (dynamic tapDownDetails) {
                    c.mutate(() {
                      c.mapCenter = latlng.LatLng(
                        c.eventAggregate.extensions.kenlLat,
                        c.eventAggregate.extensions.kenlLon,
                      );
                    });
                  },
                  child: Container(color: Colors.black54),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 60.0),
                    child: Text(
                      'No location selected',
                      textAlign: TextAlign.center,
                      style: ts_headingVeryLarge,
                    ),
                  ),
                ),
              ],
              if ((c.mapCenter.latitude != CLEAR_LATLONG) ||
                  (c.mapCenter.longitude != CLEAR_LATLONG)) ...<Widget>[
                IgnorePointer(
                  ignoring: true,
                  child: Image.asset(
                    'images/other/map_center_target.png',
                    height: 300.0,
                    width: 300.0,
                  ),
                ),
              ],

              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 40.0,
                child: Container(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    border: Border.all(width: 2.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: Text(
                    c.eventAggregate.event.useFbLatLon == 1
                        ? 'Location from ${c.eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}'
                        : 'Location from Harrier Central',
                    textAlign: TextAlign.center,
                    style: ts_headingBlack,
                  ),
                ),
              ),

              Positioned(
                right: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    c.mutate(() {
                      c.mapCenter = const latlng.LatLng(
                        CLEAR_LATLONG,
                        CLEAR_LATLONG,
                      );
                    });
                  },
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset(
                      'images/other/set_map_to_no_location.png',
                    ),
                  ),
                ),
              ),

              if ((deviceInfo.deviceLat != null) &&
                  (deviceInfo.deviceLon != null)) ...<Widget>[
                Positioned(
                  right: 70.0,
                  top: 10.0,
                  child: GestureDetector(
                    onTap: () {
                      c.mutate(() {
                        c.mapCenter = latlng.LatLng(
                          deviceInfo.deviceLat!,
                          deviceInfo.deviceLon!,
                        );
                      });
                    },
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset(
                        'images/other/set_map_to_current_location.png',
                      ),
                    ),
                  ),
                ),
              ],

              if (c.eventAggregate.extensions.isMapAndDistanceValid ??
                  false) ...<Widget>[
                Positioned(
                  right: 130.0,
                  top: 10.0,
                  child: GestureDetector(
                    onTap: () {
                      c.mutate(() {
                        c.mapCenter = latlng.LatLng(
                          c.eventAggregate.extensions.latitude!,
                          c.eventAggregate.extensions.longitude!,
                        );
                      });
                    },
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image.asset(
                        'images/other/set_map_to_event_location.png',
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                left: 10.0,
                top: 10.0,
                child: GestureDetector(
                  onTap: () {
                    c.mutate(() {
                      c.trueNorthLock = !c.trueNorthLock;
                    });
                  },
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Image.asset(
                      c.trueNorthLock
                          ? 'images/other/set_map_to_true_north_lock.png'
                          : 'images/other/set_map_rotation_enabled.png',
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10.0,
                right: 10.0,
                bottom: 80.0,
                child: c.isUpdating.value
                    ? const SizedBox(
                        height: 70.0,
                        width: 70.0,
                        child: HcAppCircularProgressIndicator(
                          key: Key('655931031'),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (c.isNewRun) ...<Widget>[
                            ElevatedButton(
                              child: Text('Skip', style: ts_button),
                              onPressed: () {
                                c.mutate(() {
                                  c.tabController.animateTo(
                                    c.currentTab.value.next,
                                  );
                                });
                              },
                            ),
                            const SizedBox(width: 10.0),
                            ElevatedButton(
                              onPressed: c.geocodeAndNavigateToMap,
                              child: Text('Auto-locate', style: ts_button),
                            ),
                            const SizedBox(width: 10.0),
                          ],
                          ElevatedButton(
                            child: Text(
                              ((c.mapCenter.latitude == CLEAR_LATLONG) &&
                                      (c.mapCenter.longitude == CLEAR_LATLONG))
                                  ? 'Set no location'
                                  : 'Set Location',
                              style: ts_button,
                            ),
                            onPressed: () async {
                              if ((c.eventAggregate.event.eventId.isEmpty) ||
                                  (c.eventAggregate.event.eventId ==
                                      GUID_EMPTY)) {
                                await Utilities.showAlert(
                                  'Please save details first',
                                  'When creating a new event, please save the information on the Details tab before saving the location',
                                  'OK',
                                );

                                c.tabController.animateTo(
                                  EditingTabEnum.details.index,
                                );
                              } else {
                                c.mutate(() {
                                  c.isUpdating.value = true;
                                });
                                final EventsService nSvc = EventsService();
                                //check to see if "no location" is set. If so, don't overwrite it
                                if ((c.mapCenter.latitude != CLEAR_LATLONG) &&
                                    (c.mapCenter.longitude != CLEAR_LATLONG) &&
                                    (c.mapKey.currentState?.mapController !=
                                        null)) {
                                  c.mapCenter = c
                                      .mapKey
                                      .currentState!
                                      .mapController
                                      .camera
                                      .center;
                                }
                                final String eventId = await nSvc.addEditEvent(
                                  eventId: c.eventAggregate.event.eventId,
                                  kennelId: c.eventAggregate.event.kennelId,
                                  lat: c.mapCenter.latitude,
                                  lon: c.mapCenter.longitude,
                                  useFbLatLon: 0,
                                );
                                await c.refreshAfterSave(eventId);

                                if (c.isNewRun) {
                                  c.mutate(() {
                                    c.isUpdating.value = false;
                                  });
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 1000),
                                  );
                                  c.tabController.animateTo(
                                    c.currentTab.value.next,
                                  );
                                } else {
                                  final SnackBar snackBar = SnackBar(
                                    duration: const Duration(seconds: 3),
                                    content: Text(
                                      'Updated location saved in Harrier Central',
                                      textAlign: TextAlign.center,
                                      style: ts_titleCondensed,
                                    ),
                                    backgroundColor: hc_blue,
                                  );

                                  ScaffoldMessenger.of(
                                    navigatorKey.currentContext!,
                                  ).showSnackBar(snackBar);
                                }

                                await Future<void>.delayed(
                                  const Duration(milliseconds: 500),
                                );
                                c.mutate(() {
                                  c.isUpdating.value = false;
                                });

                                //_showEventPopup(_calendarController.selectedDay);
                              }
                            },
                          ),
                          if ((c.eventAggregate.event.eventFacebookId !=
                                  null) &&
                              (!c.isUpdating.value)) ...<Widget>[
                            const SizedBox(width: 20.0),
                            Expanded(
                              child: ElevatedButton(
                                child: AutoSizeText(
                                  'Use ${c.eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                                  style: ts_button,
                                  minFontSize: 3.0,
                                  maxLines: 1,
                                  //overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () async {
                                  c.mutate(() {
                                    c.isUpdating.value = true;
                                  });
                                  final EventsService nSvc = EventsService();
                                  final String eventId = await nSvc
                                      .addEditEvent(
                                        eventId: c.eventAggregate.event.eventId,
                                        useFbLatLon: 1,
                                      );

                                  await c.refreshAfterSave(eventId);
                                  c.mutate(() {
                                    if ((c.eventAggregate.extensions.latitude ==
                                            null) ||
                                        (c
                                                .eventAggregate
                                                .extensions
                                                .longitude ==
                                            null)) {
                                      c.mapCenter = latlng.LatLng(
                                        c.eventAggregate.extensions.kenlLat,
                                        c.eventAggregate.extensions.kenlLon,
                                      );
                                    } else {
                                      c.mapCenter = latlng.LatLng(
                                        c.eventAggregate.extensions.latitude!,
                                        c.eventAggregate.extensions.longitude!,
                                      );
                                    }
                                    c.isUpdating.value = false;
                                    final SnackBar snackBar = SnackBar(
                                      duration: const Duration(seconds: 3),
                                      content: Text(
                                        'Location is being synced from ${c.eventAggregate.event.eventInboundIntegrationId >= integrationPlatformNames.length ? 'external source' : integrationPlatformNames[c.eventAggregate.event.eventInboundIntegrationId]}',
                                        textAlign: TextAlign.center,
                                        style: ts_titleCondensedBlack,
                                      ),
                                      backgroundColor: hc_blue,
                                    );
                                    ScaffoldMessenger.of(
                                      navigatorKey.currentContext!,
                                    ).showSnackBar(snackBar);
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherDetailsPage(
    BuildContext context,
    EditRunDetailsController c,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        disabledColor: Colors.grey,
        iconTheme: IconTheme.of(context).copyWith(color: hc_red, size: 35),
      ),
      child: KeyboardActions(
        config: _buildConfig(context, c),
        tapOutsideBehavior: TapOutsideBehavior.none,
        child: SingleChildScrollView(
          child: Form(
            key: c.otherDetailsFormKey,
            child: Wrap(
              children: <Widget>[
                Column(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 25.0, bottom: 5.0),
                      padding: const EdgeInsets.only(
                        top: 5.0,
                        bottom: 5.0,
                        left: 20.0,
                        right: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(width: 2.0),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Run data from Harrier Central',
                        textAlign: TextAlign.center,
                        style: ts_headingBlack,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 0.0,
                        left: 30.0,
                        right: 30.0,
                      ),
                      child: Text(
                        'Enter hares here. These names will be presented in addition to anyone who has RSVPed as a Hare using the app',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      color: c.focusNodeHares.hasFocus
                          ? Colors.yellow.shade50
                          : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: TextFormField(
                        // onChanged: (String text) {
                        //   if ((text == null) || (text.isEmpty)) {
                        //     c.absoluteEventNumberController.text = '<auto>';
                        //   } else if ((text.length > 6) && (text.contains('<auto>'))) {
                        //     c.absoluteEventNumberController.text = c.absoluteEventNumberController.text.replaceAll('<auto>', '');
                        //     c.absoluteEventNumberController.selection = TextSelection.fromPosition(TextPosition(offset: c.absoluteEventNumberController.text.length));
                        //   }
                        // },
                        maxLines: 1,
                        focusNode: c.focusNodeHares,
                        controller: c.haresController,
                        // validator: (String val) {
                        //   if (val.isEmpty) {
                        //     return 'Please provide an event number or leave blank for auto numbering';
                        //   } else {
                        //     return null;
                        //   }
                        // },
                        //keyboardType: const TextInputType.(),
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Hares',
                          fillColor: hc_red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: '<enter Hares here>',
                          hintStyle: ts_hint,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 0.0,
                        left: 30.0,
                        right: 30.0,
                      ),
                      child: Text(
                        'Harrier Central automatically numbers runs. But if there is a reason to override this, you can manually enter a run number here.',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      color: c.focusNodeAbsoluteEventNumber.hasFocus
                          ? Colors.yellow.shade50
                          : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: TextFormField(
                        // onChanged: (String text) {
                        //   if ((text == null) || (text.isEmpty)) {
                        //     c.absoluteEventNumberController.text = '<auto>';
                        //   } else if ((text.length > 6) && (text.contains('<auto>'))) {
                        //     c.absoluteEventNumberController.text = c.absoluteEventNumberController.text.replaceAll('<auto>', '');
                        //     c.absoluteEventNumberController.selection = TextSelection.fromPosition(TextPosition(offset: c.absoluteEventNumberController.text.length));
                        //   }
                        // },
                        maxLines: 1,
                        focusNode: c.focusNodeAbsoluteEventNumber,
                        controller: c.absoluteEventNumberController,
                        // validator: (String val) {
                        //   if (val.isEmpty) {
                        //     return 'Please provide an event number or leave blank for auto numbering';
                        //   } else {
                        //     return null;
                        //   }
                        // },
                        keyboardType: const TextInputType.numberWithOptions(),
                        textCapitalization: TextCapitalization.sentences,
                        style: ts_titleMediumBlack,
                        decoration: InputDecoration(
                          labelText: 'Event Number',
                          fillColor: hc_red,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(),
                          ),
                          hintText: '<use auto numbering>',
                          hintStyle: ts_hint,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 0.0,
                        left: 30.0,
                        right: 30.0,
                      ),
                      child: Text(
                        'Enter in the hash cash amount here if it is different than the normal hash cash value.',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: c.focusNodeEventPriceForMembers.hasFocus
                                  ? Colors.yellow.shade50
                                  : Colors.white,
                              margin: const EdgeInsets.only(right: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     //c.eventPriceForMembersController.text = '';
                                //   } else if ((text.length > 9) && (text.contains('<default>'))) {
                                //     // c.eventPriceForMembersController.text = c.eventPriceForMembersController.text.replaceAll('<default>', '');
                                //     // c.eventPriceForMembersController.selection = TextSelection.fromPosition(TextPosition(offset: c.eventPriceForMembersController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: c.focusNodeEventPriceForMembers,
                                controller: c.eventPriceForMembersController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: true,
                                    ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Member price',
                                  fillColor: hc_red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<use default>',
                                  hintStyle: ts_hint,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: c.focusNodeEventPriceForNonMembers.hasFocus
                                  ? Colors.yellow.shade50
                                  : Colors.white,
                              margin: const EdgeInsets.only(left: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     //c.eventPriceForNonMembersController.text = '<default>';
                                //   } else if ((text.length > 9) && (text.contains('<default>'))) {
                                //     c.eventPriceForNonMembersController.text = c.eventPriceForNonMembersController.text.replaceAll('<default>', '');
                                //     c.eventPriceForNonMembersController.selection =
                                //         TextSelection.fromPosition(TextPosition(offset: c.eventPriceForNonMembersController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: c.focusNodeEventPriceForNonMembers,
                                controller: c.eventPriceForNonMembersController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: true,
                                    ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Non-member price',
                                  fillColor: hc_red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<use default>',
                                  hintStyle: ts_hint,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 0.0,
                        left: 30.0,
                        right: 30.0,
                      ),
                      child: Text(
                        'If you have extra charges associated with your run, such as for dinner, you can put in the price and description here.',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: c.focusNodeEventPriceForExtras.hasFocus
                                  ? Colors.yellow.shade50
                                  : Colors.white,
                              margin: const EdgeInsets.only(right: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     c.eventPriceForExtrasController.text = '<none>';
                                //   } else if ((text.length > 6) && (text.contains('<none>'))) {
                                //     c.eventPriceForExtrasController.text = c.eventPriceForExtrasController.text.replaceAll('<none>', '');
                                //     c.eventPriceForExtrasController.selection = TextSelection.fromPosition(TextPosition(offset: c.eventPriceForExtrasController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: c.focusNodeEventPriceForExtras,
                                controller: c.eventPriceForExtrasController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      signed: false,
                                      decimal: true,
                                    ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Price for extras',
                                  fillColor: hc_red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<none>',
                                  hintStyle: ts_hint,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: c.focusNodeExtrasDescription.hasFocus
                                  ? Colors.yellow.shade50
                                  : Colors.white,
                              margin: const EdgeInsets.only(left: 12.5),
                              child: TextFormField(
                                // onChanged: (String text) {
                                //   if ((text == null) || (text.isEmpty)) {
                                //     c.extrasDescriptionController.text = '<none>';
                                //   } else if ((text.length > 6) && (text.contains('<none>'))) {
                                //     c.extrasDescriptionController.text = c.extrasDescriptionController.text.replaceAll('<none>', '');
                                //     c.extrasDescriptionController.selection = TextSelection.fromPosition(TextPosition(offset: c.extrasDescriptionController.text.length));
                                //   }
                                // },
                                maxLines: 1,
                                focusNode: c.focusNodeExtrasDescription,
                                controller: c.extrasDescriptionController,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: ts_titleMediumBlack,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  fillColor: hc_red,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: const BorderSide(),
                                  ),
                                  hintText: '<none>',
                                  hintStyle: ts_hint,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      //color: c.focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade500),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          CheckboxFormField(
                            title: Text(
                              'Show run in Harrier Central',
                              style: ts_regularBlack,
                            ),
                            validator: (bool? result) {
                              c.isVisible = result ?? false;
                              return null;
                            },
                            initialValue: c.isVisible,
                            onChanged: (bool? result) {
                              c.mutate(() {
                                c.isVisible = result ?? false;
                              });
                            },
                          ),
                          CheckboxFormField(
                            title: Text(
                              'Count this run',
                              style: ts_regularBlack,
                            ),
                            initialValue: c.isCountedRun,
                            validator: (bool? result) {
                              c.isCountedRun = result ?? false;
                              return null;
                            },
                            onChanged: (bool? result) {
                              c.mutate(() {
                                c.isCountedRun = result ?? false;
                              });
                            },
                          ),
                          CheckboxFormField(
                            title: Text(
                              'Users can edit run history',
                              style: ts_regularBlack,
                            ),
                            initialValue: c.usersCanEditRunAttendence == 1,
                            tristate: true,
                            validator: (bool? result) {
                              if (result == null) {
                                c.usersCanEditRunAttendence = -1;
                              } else {
                                c.usersCanEditRunAttendence = result ? 1 : 0;
                              }

                              return null;
                            },
                            onChanged: (bool? result) {
                              c.mutate(() {
                                if (result == null) {
                                  c.usersCanEditRunAttendence = -1;
                                } else {
                                  c.usersCanEditRunAttendence = result ? 1 : 0;
                                }
                              });
                            },
                          ),
                          CheckboxFormField(
                            title: Text(
                              'Promote this run',
                              style: ts_regularBlack,
                            ),
                            initialValue: c.isPromotedEvent,
                            validator: (bool? result) {
                              c.isPromotedEvent = result ?? false;
                              return null;
                            },
                            onChanged: (bool? result) {
                              c.mutate(() {
                                c.isPromotedEvent = result ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 20.0,
                        bottom: 0.0,
                        left: 30.0,
                        right: 30.0,
                      ),
                      child: Text(
                        'Let Hashers around the corner or around the world know about your run if it is interesting to them! By telling us the geographic scope of your run it will help us do a better job promoting it for you!',
                        style: ts_mediumBlack,
                      ),
                    ),
                    Container(
                      //color: c.focusNodeAbsoluteEventNumber.hasFocus ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(
                        top: 10.0,
                        bottom: 10.0,
                        left: 25.0,
                        right: 25.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade500),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: RadioGroup(
                        groupValue: c.eventGeographicScope,
                        onChanged: (int? value) {
                          c.mutate(() {
                            c.eventGeographicScope = value ?? 0;
                          });
                        },

                        child: Column(
                          children: <Widget>[
                            ListTile(
                              title: Text(
                                'Local (normal run)',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 1),
                            ),
                            ListTile(
                              title: Text(
                                'Local (special event)',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 2),
                            ),
                            ListTile(
                              title: Text(
                                'Regional / State',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 3),
                            ),
                            ListTile(
                              title: Text(
                                'Nash Hash (national)',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 4),
                            ),
                            ListTile(
                              title: Text(
                                'Interhash / Continent',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 5),
                            ),
                            ListTile(
                              title: Text(
                                'World Interhash / Global',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 6),
                            ),
                            ListTile(
                              title: Text('Other', style: ts_regularBlack),
                              leading: Radio<int>(value: 7),
                            ),
                            ListTile(
                              title: Text(
                                'Not specified',
                                style: ts_regularBlack,
                              ),
                              leading: Radio<int>(value: 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    super.key,
    required Widget title,
    super.onSaved,
    super.validator,
    bool super.initialValue = false,
    bool tristate = false,
    ValueChanged<bool?>? onChanged,
  }) : super(
         builder: (FormFieldState<bool> state) {
           return CheckboxListTile(
             dense: state.hasError,
             title: title,
             tristate: tristate,
             value: state.value,
             onChanged: (bool? value) {
               state.didChange(value);
               onChanged?.call(value);
             },
             subtitle: state.hasError
                 ? Builder(
                     builder: (BuildContext context) => Text(
                       state.errorText ?? '',
                       style: TextStyle(
                         color: Theme.of(context).colorScheme.error,
                       ),
                     ),
                   )
                 : null,
             controlAffinity: ListTileControlAffinity.leading,
           );
         },
       );
}
