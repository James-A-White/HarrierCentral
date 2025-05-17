import 'dart:math' as math;
import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class RunDetailsController extends GetxController {
  RunDetailsController({required this.event, required this.kennel}) {
    // Initialize controllers with initial data if available
  }

  EventModel event;
  KennelsModel kennel;

  RxBool showQrCodes = false.obs;

  String runUrlForCopy = '';
  String thisRunUrlForQr = '';
  String nextRunUrlForQr = '';
  String kennelUrlForQr = '';

  @override
  void onInit() {
    super.onInit();

    thisRunUrlForQr = 'https://www.hashruns.org';
    nextRunUrlForQr = thisRunUrlForQr;
    kennelUrlForQr = thisRunUrlForQr;

    if (event.isCountedRun != 0) {
      runUrlForCopy += '/${kennel.kennelUniqueShortName}/${event.eventNumber}';
      thisRunUrlForQr +=
          '/${kennel.kennelUniqueShortName}/${event.eventNumber}';
      nextRunUrlForQr += '/${kennel.kennelUniqueShortName}/nextrun';
      kennelUrlForQr += '/${kennel.kennelUniqueShortName}';
    } else {
      runUrlForCopy += '/#/RID?publicEventId=${event.publicEventId}';

      thisRunUrlForQr += '/#/RID?publicEventId=${event.publicEventId}';

      kennelUrlForQr = '';
    }
  }

  @override
  void onClose() {
    //print('chat controller closed');
    super.onClose();
  }
}

class RunDetails extends StatelessWidget {
  RunDetails(
    this.event,
    this.kennel,
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.distancePreference,
    this.distToEvent,
    this.paymentLinkUrl,
    this.showPaymentOptions,
    this.isMapAndDistanceValid, {
    super.key,
    this.isMember = 0,
    this.isPaid = 0,
    this.rsvpState = 0,
    this.processPayment,
    this.eventUrlWithKennelBackup,
  });

  final EventModel event;
  final KennelsModel kennel;
  final int digitsAfterDecimal;
  final String currencySymbol;
  final int distancePreference;
  final bool isMapAndDistanceValid;
  final double? distToEvent;
  final String? paymentLinkUrl;
  final bool showPaymentOptions;
  final int isMember;
  final int isPaid;
  final int rsvpState;
  final Function? processPayment;
  final String? eventUrlWithKennelBackup;

  static const int _flexLeft = 30;
  static const int _flexRight = 70;

  static const double _spaceBetweenColumns = 11.0;
  static const double _spaceBetweenRows = 26.0;

  // Initialize the controller with the provided arguments
  late final RunDetailsController runDetailsController = Get.put(
    RunDetailsController(event: event, kennel: kennel),
    // permanent: true,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          ((event.eventImage ?? '').isNotEmpty &&
                  event.eventImage!.startsWith('http'))
              ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder:
                            (BuildContext context) => ZoomableImagePage2(
                              key: const Key('50201112'),
                              pageTitle: 'Zoomable Event Image',
                              imageUrl: event.eventImage,
                              appBarBackgroundColor: themeAppBarBackground,
                              background: Backgrounds.defaultHcBackground(),
                            ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5), // shadow color
                          spreadRadius: 2, // how much the shadow spreads
                          blurRadius: 8, // softening the shadow
                          offset: Offset(4, 4), // direction of the shadow
                        ),
                      ],
                    ),
                    child: CachedNetworkImage(
                      imageUrl: event.eventImage!,
                      // errorWidget:
                      //     (BuildContext context, String url, Exception error) =>
                      //         const  Icon(Icons.error),
                    ),
                    //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                  ),
                ),
              )
              : Container(),
          ((event.eventImage ?? '').isNotEmpty &&
                  event.eventImage!.startsWith('http'))
              ? const Padding(
                padding: EdgeInsets.only(top: 32.0, bottom: 0.0),
                child: FancyDivider(
                  key: Key('666177323'),
                  innerColor: Colors.white,
                ),
              )
              : Container(),
          Padding(
            padding: const EdgeInsets.only(
              top: 25,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            child: AutoSizeText(
              event.eventName,
              style: ts_titleLarge,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
            child: FancyDivider(key: Key('61566713'), innerColor: Colors.white),
          ),
          Text(
            'Event details',
            style: ts_headingLarge,
            //textScaleFactor: G0<DeviceInfo>().textClamp50,
          ),
          const SizedBox(height: 15.0),
          TextScaleFactorClamper(
            textScaleFactor: G0<DeviceInfo>().textClamp50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Kennel:',
                        style: ts_listLabelStyle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      height: _spaceBetweenRows,
                      width: _spaceBetweenColumns,
                    ),
                    Expanded(
                      flex: _flexRight,
                      child: Text(
                        kennel.kennelName,
                        style: ts_listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                ((event.eventNumber == 0) || (event.isCountedRun == 0))
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Row(
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'Run #:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: Text(
                            '${event.eventNumber}',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Date:',
                        style: ts_listLabelStyle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      height: _spaceBetweenRows,
                      width: _spaceBetweenColumns,
                    ),
                    Expanded(
                      flex: _flexRight,
                      child: Text(
                        DateFormat(
                          'E, MMM d, yyyy',
                        ).format(event.eventStartDatetime),
                        style: ts_listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Time:',
                        style: ts_listLabelStyle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      height: _spaceBetweenRows,
                      width: _spaceBetweenColumns,
                    ),
                    Expanded(
                      flex: _flexRight,
                      child: Text(
                        DateFormat('h:mm a').format(event.eventStartDatetime),
                        style: ts_listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if ((event.locationOneLineDesc ?? '') != '') ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: _flexLeft,
                        child: Text(
                          'Place:',
                          style: ts_listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(
                        height: _spaceBetweenRows,
                        width: _spaceBetweenColumns,
                      ),
                      Expanded(
                        flex: _flexRight,
                        child: Text(
                          event.locationOneLineDesc ?? '',
                          style: ts_listValueStyle,
                          textAlign: TextAlign.left,

                          //maxLines: ,
                          //overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                (event.eventGeographicScope == 0)
                    ? Container()
                    : Row(
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'Event:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: Text(
                            Utilities.getEventScopeText(
                              event.eventGeographicScope,
                            ),
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Run fees:',
                        style: ts_listLabelStyle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      height: _spaceBetweenRows,
                      width: _spaceBetweenColumns,
                    ),
                    Expanded(
                      flex: _flexRight,
                      child: Text(
                        ((event.eventPriceForMembers ??
                                    kennel.defaultPriceForMembers) >
                                0)
                            ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForMembers ?? kennel.defaultPriceForMembers, digitsAfterDecimal, currencySymbol)} (members)'
                            : '',
                        style: ts_listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        '',
                        style: ts_listLabelStyle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 0, width: _spaceBetweenColumns),
                    Expanded(
                      flex: _flexRight,
                      child: Text(
                        ((event.eventPriceForNonMembers ??
                                    kennel.defaultPriceForNonMembers) >
                                0)
                            ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers, digitsAfterDecimal, currencySymbol)} (non-members)'
                            : '',
                        style: ts_listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                (event.eventPriceForExtras ?? 0) == 0
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Row(
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'Extra fee:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: Text(
                            ((event.eventPriceForNonMembers ??
                                        kennel.defaultPriceForNonMembers) >
                                    0)
                                ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForExtras ?? 0, digitsAfterDecimal, currencySymbol)} (${event.extrasDescription})'
                                : '',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                (event.hares ?? '') == ''
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Row(
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'Hares:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: Text(
                            event.hares ?? '',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                (G0<AppModel>().hasLocationPermissions) && isMapAndDistanceValid
                    ? Row(
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'Distance:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex:
                              G0<AppModel>().hasLocationPermissions
                                  ? _flexRight
                                  : 0,
                          child: Text(
                            G0<AppModel>().hasLocationPermissions
                                ? (distToEvent ?? -1) >= 0
                                    ? '${Utilities.getDistance(distToEvent!, isMetric: ((distancePreference) & 0x01) == 0)} from here'
                                    : '<unknown>'
                                : '',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                    : const SizedBox(height: 0.0, width: 0.0),
                if ((event.locationStreet ?? '') != '') ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: _flexLeft,
                        child: Text(
                          'Street:',
                          style: ts_listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        height: _spaceBetweenRows,
                        width: _spaceBetweenColumns,
                      ),
                      Expanded(
                        flex: _flexRight,
                        child: SelectableText(
                          event.locationStreet ?? '',
                          style: ts_listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          contextMenuBuilder: (
                            BuildContext context,
                            EditableTextState editableTextState,
                          ) {
                            return _addressContextMenu(editableTextState);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                if ((((event.locationPostCode == null) ||
                            (event.locationPostCode!.isEmpty))
                        ? ''
                        : '${event.locationPostCode} ') !=
                    '') ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: _flexLeft,
                        child: Text(
                          'Post Code:',
                          style: ts_listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        height: _spaceBetweenRows,
                        width: _spaceBetweenColumns,
                      ),
                      Expanded(
                        flex: _flexRight,
                        child: SelectableText(
                          ((event.locationPostCode == null) ||
                                  (event.locationPostCode!.isEmpty))
                              ? ''
                              : '${event.locationPostCode} ',
                          style: ts_listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          contextMenuBuilder: (
                            BuildContext context,
                            EditableTextState editableTextState,
                          ) {
                            return _addressContextMenu(editableTextState);
                          },
                          //overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if ((event.locationCity ?? '') != '') ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: _flexLeft,
                        child: Text(
                          'City:',
                          style: ts_listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        height: _spaceBetweenRows,
                        width: _spaceBetweenColumns,
                      ),
                      Expanded(
                        flex: _flexRight,
                        child: SelectableText(
                          event.locationCity ?? '',
                          style: ts_listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          contextMenuBuilder: (
                            BuildContext context,
                            EditableTextState editableTextState,
                          ) {
                            return _addressContextMenu(editableTextState);
                          },
                          //overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                ((event.locationSubRegion ?? '') == '')
                    ? const SizedBox()
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            (event.locationCountry ?? '').toLowerCase() ==
                                    'united states'
                                ? 'County'
                                : 'Region:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: SelectableText(
                            event.locationSubRegion ?? '',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 3,
                            contextMenuBuilder: (
                              BuildContext context,
                              EditableTextState editableTextState,
                            ) {
                              return _addressContextMenu(editableTextState);
                            },
                            //overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ((event.locationRegion ?? '') == '')
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'State:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: SelectableText(
                            event.locationRegion ?? '',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 3,
                            contextMenuBuilder: (
                              BuildContext context,
                              EditableTextState editableTextState,
                            ) {
                              return _addressContextMenu(editableTextState);
                            },
                            //overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ((event.locationCountry ?? '') == '')
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: _flexLeft,
                          child: Text(
                            'Country:',
                            style: ts_listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          height: _spaceBetweenRows,
                          width: _spaceBetweenColumns,
                        ),
                        Expanded(
                          flex: _flexRight,
                          child: SelectableText(
                            event.locationCountry ?? '',
                            style: ts_listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 3,
                            contextMenuBuilder: (
                              BuildContext context,
                              EditableTextState editableTextState,
                            ) {
                              return _addressContextMenu(editableTextState);
                            },
                            //overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
          !showPaymentOptions
              ? Container()
              : PaymentIcons(
                event,
                kennel,
                digitsAfterDecimal,
                currencySymbol,
                distancePreference,
                distToEvent,
                paymentLinkUrl,
                rsvpState,
                isMember,
                isPaid,
                false,
                (int r, int p) {
                  if (processPayment != null) {
                    processPayment!(r, p);
                  }
                },
              ),
          (event.tags1) == 0 && (event.tags2) == 0
              ? Container()
              : Column(
                children: <Widget>[
                  const FancyDivider(
                    key: Key('1156920939'),
                    innerColor: Colors.white,
                    topMargin: 30.0,
                    bottomMargin: 10.0,
                  ),
                  Text(
                    'Event tags',
                    style: ts_headingLarge,
                    //textScaleFactor: G0<DeviceInfo>().textClamp50,
                  ),
                  const SizedBox(height: 15.0),
                  TextScaleFactorClamper(
                    textScaleFactor: G0<DeviceInfo>().textClamp50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: G0<DeviceInfo>().deviceWidth,
                        ), // this is required to force the column to be the full width of the device
                        for (int i = 0; i < runTags1.length; i++)
                          if (((runTags1.values.elementAt(i)) & event.tags1) !=
                              0)
                            Container(
                              margin: const EdgeInsets.only(
                                left: 30.0,
                                bottom: 10.0,
                              ),
                              child: Text(
                                '•  ${runTags1.keys.elementAt(i)}',
                                style: ts_listValueStyle,
                              ),
                            ),
                        for (int i = 0; i < runTags2.length; i++)
                          if (((runTags2.values.elementAt(i)) & event.tags2) !=
                              0)
                            Container(
                              margin: const EdgeInsets.only(
                                left: 30.0,
                                bottom: 10.0,
                              ),
                              child: Text(
                                '•  ${runTags2.keys.elementAt(i)}',
                                style: ts_listValueStyle,
                              ),
                            ),

                        //for (dynamic tag in runTags) Text(tag.key)
                      ],
                    ),
                  ),
                ],
              ),
          FancyDivider(
            key: UniqueKey(),
            innerColor: Colors.white,
            topMargin: 30.0,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
            child: ElevatedButton(
              // style: ButtonStyle(shadowColor: WidgetStateProperty.all(Colors.transparent), backgroundColor: WidgetStateProperty.all(Colors.transparent)),
              child: Obx(
                () => Text(
                  runDetailsController.showQrCodes.value
                      ? 'Hide Run Codes'
                      : 'Share ${kennel.kennelShortName} Runs',
                  style: ts_button,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  //textScaleFactor: G0<DeviceInfo>().textClamp50,
                ),
              ),

              onPressed: () async {
                runDetailsController.showQrCodes.value =
                    !runDetailsController.showQrCodes.value;
              },
            ),
          ),
          Obx(() {
            return runDetailsController.showQrCodes.value
                ? Column(
                  children: [
                    Text(
                      'QR Codes for Sharing Runs',
                      style: ts_headingLarge,
                      //textScaleFactor: G0<DeviceInfo>().textClamp50,
                    ),
                    const SizedBox(height: 20),
                    OverflowBar(
                      spacing: 80,
                      overflowSpacing: 40,
                      alignment: MainAxisAlignment.center,
                      overflowAlignment: OverflowBarAlignment.center,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text('This Run', style: ts_title),
                            const SizedBox(height: 20),
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(10),
                              child: QrImageView(
                                data: runDetailsController.thisRunUrlForQr,
                                version: QrVersions.auto,
                                size: math.min(
                                  200,
                                  MediaQuery.of(context).size.width / 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Text(
                              'Next ${kennel.kennelShortName} Run',
                              style: ts_title,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(10),
                              child: QrImageView(
                                data: runDetailsController.nextRunUrlForQr,
                                version: QrVersions.auto,
                                size: math.min(
                                  200,
                                  MediaQuery.of(context).size.width / 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (runDetailsController
                            .kennelUrlForQr
                            .isNotEmpty) ...<Widget>[
                          Column(
                            children: <Widget>[
                              Text(
                                '${kennel.kennelShortName} upcoming runs list',
                                style: ts_title,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(10),
                                child: QrImageView(
                                  data: runDetailsController.kennelUrlForQr,
                                  version: QrVersions.auto,
                                  size: math.min(
                                    200,
                                    MediaQuery.of(context).size.width / 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (((kennel.kennelWebsiteUrl ?? '').isNotEmpty) &&
                            (kennel.kennelWebsiteUrl!.toLowerCase().startsWith(
                              'http',
                            ))) ...<Widget>[
                          Column(
                            children: <Widget>[
                              Text(
                                '${kennel.kennelShortName} Website',
                                style: ts_title,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(10),
                                child: QrImageView(
                                  data: kennel.kennelWebsiteUrl!,
                                  version: QrVersions.auto,
                                  size: math.min(
                                    200,
                                    MediaQuery.of(context).size.width / 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                )
                : const SizedBox.shrink();
          }),
          if ((event.evtDisseminateAllowWebLinks == 1) ||
              (kennel.disseminateAllowWebLinks == 1)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: ElevatedButton(
                // style: ButtonStyle(shadowColor: WidgetStateProperty.all(Colors.transparent), backgroundColor: WidgetStateProperty.all(Colors.transparent)),
                child: Text(
                  'Copy HC Web link',
                  style: ts_button,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  //textScaleFactor: G0<DeviceInfo>().textClamp50,
                ),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          'https://www.hashruns.org/#/RID?publicEventId=${event.publicEventId}&textTheme=light',
                    ),
                  );

                  await Utilities.showAlert(
                    'Link copied',
                    'A link to the event on Harrier Central has been copied to you clipboard',
                    'OK',
                  );
                },
              ),
            ),
          ],
          if (!(((event.eventFacebookId ?? '') != '') &&
                  (event.eventInboundIntegrationId ==
                      INBOUND_INTEGRATION_FACEBOOK)) &&
              (eventUrlWithKennelBackup != null) &&
              (eventUrlWithKennelBackup!.isNotEmpty)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 40.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Image.asset(
                  'images/icons/visit_run_on_web.png',
                  height: 60.0,
                  width: 325.0,
                ),
                onPressed: () async {
                  if (Utilities.isValidUrl(eventUrlWithKennelBackup!)) {
                    await launchUrl(
                      Uri.parse(eventUrlWithKennelBackup!),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await Utilities.showAlert(
                      'Unable to open link',
                      'Harrier Central was unable to open $eventUrlWithKennelBackup',
                      'OK',
                    );
                  }
                },
              ),
            ),
          ],
          if ((event.eventDescription ?? '') != '') ...<Widget>[
            FancyDivider(
              key: UniqueKey(),
              innerColor: Colors.white,
              topMargin: 30.0,
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 20.0,
                right: 20.0,
                left: 20.0,
                bottom: 20.0,
              ),
              child: Linkify(
                text: event.eventDescription!.replaceAll('\r\n', '\n'),
                style: ts_body.copyWith(
                  fontSize: 20 * G0<DeviceInfo>().textClamp50,
                ),
                linkStyle: ts_bodyYellow,
                onOpen: (LinkableElement link) async {
                  if (Utilities.isValidUrl(link.url)) {
                    await launchUrl(
                      Uri.parse(link.url),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await Utilities.showAlert(
                      'Unable to open link',
                      'Harrier Central was unable to open ${link.url}',
                      'OK',
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addressContextMenu(EditableTextState editableTextState) {
    // final List<ContextMenuButtonItem> buttonItems =
    //     editableTextState.contextMenuButtonItems;

    final List<ContextMenuButtonItem> buttonItems = [];

    buttonItems.add(editableTextState.contextMenuButtonItems[0]);

    buttonItems.add(
      ContextMenuButtonItem(
        label: 'Copy Full Address',
        type: ContextMenuButtonType.custom,
        onPressed: () {
          String s = '';

          if ((event.locationStreet ?? '').isNotEmpty) {
            s = event.locationStreet!;
          }

          if ((event.locationCity ?? '').isNotEmpty) {
            if (s.isNotEmpty) {
              s += ', ';
            }
            s += event.locationCity!;
          }

          if ((event.locationSubRegion ?? '').isNotEmpty) {
            if (s.isNotEmpty) {
              s += ', ';
            }
            s += event.locationSubRegion!;
          }

          if ((event.locationRegion ?? '').isNotEmpty) {
            if (s.isNotEmpty) {
              s += ', ';
            }
            s += event.locationRegion!;
          }

          if ((event.locationCountry ?? '').isNotEmpty) {
            if (s.isNotEmpty) {
              s += ', ';
            }
            s += event.locationCountry!;
          }

          if ((event.locationPostCode ?? '').isNotEmpty) {
            if (s.isNotEmpty) {
              s += ', ';
            }
            s += event.locationPostCode!;
          }

          Clipboard.setData(ClipboardData(text: s));
          ContextMenuController.removeAny();
        },
      ),
    );

    double? lat = event.hcLatitude;
    double? lon = event.hcLongitude;

    if (event.useFbLatLon != 0) {
      lat = event.fbLatitude;
      lon = event.fbLongitude;
    }

    if ((lat != null) && (lon != null)) {
      buttonItems.add(
        ContextMenuButtonItem(
          label: 'Copy Lat/Lon',
          type: ContextMenuButtonType.custom,
          onPressed: () {
            String s = '';
            s = '$lat, $lon';
            Clipboard.setData(ClipboardData(text: s));
            ContextMenuController.removeAny();
          },
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }
}
