import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class RunDetails extends StatelessWidget {
  const RunDetails(
    this.event,
    this.kennel,
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.distancePreference,
    this.distToEvent,
    this.paymentLinkUrl,
    this.showPaymentOptions,
    this.isMapAndDistanceValid, {
    Key? key,
    this.isMember = 0,
    this.isPaid = 0,
    this.rsvpState = 0,
    this.processPayment,
    this.eventUrlWithKennelBackup,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          ((event.eventImage ?? '').isNotEmpty && event.eventImage!.startsWith('http'))
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GestureDetector(
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => ZoomableImagePage2(
                              key: const Key('50201112'),
                              pageTitle: 'Zoomable Event Image',
                              imageUrl: event.eventImage,
                              appBarBackgroundColor: themeAppBarBackground,
                              background: Backgrounds.defaultHcBackground(),
                            ),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: event.eventImage!,
                        // errorWidget:
                        //     (BuildContext context, String url, Exception error) =>
                        //         const  Icon(Icons.error),
                      )
                      //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                      ),
                )
              : Container(),
          ((event.eventImage ?? '').isNotEmpty && event.eventImage!.startsWith('http'))
              ? const Padding(
                  padding: EdgeInsets.only(top: 32.0, bottom: 0.0),
                  child: FancyDivider(key: Key('666177323'), innerColor: Colors.white),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 10),
            child: AutoSizeText(event.eventName, style: titleStyle, textAlign: TextAlign.center, maxLines: 2),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
            child: FancyDivider(key: Key('61566713'), innerColor: Colors.white),
          ),
          Text(
            'Event details',
            style: headingStyle,
            textScaleFactor: G0<DeviceInfo>().textClamp50,
          ),
          const SizedBox(
            height: 15.0,
          ),
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
                        style: listLabelStyle,
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
                          style: listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
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
                              style: listLabelStyle,
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
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Date:',
                        style: listLabelStyle,
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
                          DateFormat('E, MMM d, yyyy').format(event.eventStartDatetime),
                          style: listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Time:',
                        style: listLabelStyle,
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
                          style: listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
                if ((event.locationOneLineDesc ?? '') != '') ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: _flexLeft,
                        child: Text(
                          'Place:',
                          style: listLabelStyle,
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
                            style: listValueStyle,
                            textAlign: TextAlign.left,

                            //maxLines: ,
                            //overflow: TextOverflow.ellipsis,
                          )),
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
                              style: listLabelStyle,
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
                                Utilities.getEventScopeText(event.eventGeographicScope),
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        'Run fees:',
                        style: listLabelStyle,
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
                          ((event.eventPriceForMembers ?? kennel.defaultPriceForMembers) > 0)
                              ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForMembers ?? kennel.defaultPriceForMembers, digitsAfterDecimal, currencySymbol)} (members)'
                              : '',
                          style: listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: _flexLeft,
                      child: Text(
                        '',
                        style: listLabelStyle,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      height: 0,
                      width: _spaceBetweenColumns,
                    ),
                    Expanded(
                        flex: _flexRight,
                        child: Text(
                          ((event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers) > 0)
                              ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers, digitsAfterDecimal, currencySymbol)} (non-members)'
                              : '',
                          style: listValueStyle,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
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
                              style: listLabelStyle,
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
                                ((event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers) > 0)
                                    ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForExtras ?? 0, digitsAfterDecimal, currencySymbol)} (${event.extrasDescription})'
                                    : '',
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
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
                              style: listLabelStyle,
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
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                (G0<AppModel>().hasLocationPermissions) && isMapAndDistanceValid
                    ? Row(
                        children: <Widget>[
                          Expanded(
                            flex: _flexLeft,
                            child: Text(
                              'Distance:',
                              style: listLabelStyle,
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
                              flex: G0<AppModel>().hasLocationPermissions ? _flexRight : 0,
                              child: Text(
                                G0<AppModel>().hasLocationPermissions
                                    ? (distToEvent ?? -1) >= 0
                                        ? '${Utilities.getDistance(distToEvent!, context, isMetric: ((distancePreference) & 0x01) == 0)} from here'
                                        : '<unknown>'
                                    : '',
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
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
                          style: listLabelStyle,
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
                          child: Text(
                            event.locationStreet ?? '',
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )),
                    ],
                  ),
                ],
                if ((((event.locationPostCode == null) || (event.locationPostCode!.isEmpty)) ? '' : '${event.locationPostCode} ') != '') ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: _flexLeft,
                        child: Text(
                          'Post Code:',
                          style: listLabelStyle,
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
                            ((event.locationPostCode == null) || (event.locationPostCode!.isEmpty)) ? '' : '${event.locationPostCode} ',
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
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
                          style: listLabelStyle,
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
                            event.locationCity ?? '',
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
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
                              (event.locationCountry ?? '').toLowerCase() == 'united states' ? 'County' : 'Region:',
                              style: listLabelStyle,
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
                                event.locationSubRegion ?? '',
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )),
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
                              style: listLabelStyle,
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
                                event.locationRegion ?? '',
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )),
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
                              style: listLabelStyle,
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
                                event.locationCountry ?? '',
                                style: listValueStyle,
                                textAlign: TextAlign.left,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )),
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
                      style: headingStyle,
                      textScaleFactor: G0<DeviceInfo>().textClamp50,
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    TextScaleFactorClamper(
                      textScaleFactor: G0<DeviceInfo>().textClamp50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: G0<DeviceInfo>().deviceWidth), // this is required to force the column to be the full width of the device
                          for (int i = 0; i < runTags1.length; i++)
                            if (((runTags1.values.elementAt(i)) & event.tags1) != 0)
                              Container(
                                margin: const EdgeInsets.only(left: 30.0, bottom: 10.0),
                                child: Text(
                                  '•  ${runTags1.keys.elementAt(i)}',
                                  style: listValueStyle,
                                ),
                              ),
                          for (int i = 0; i < runTags2.length; i++)
                            if (((runTags2.values.elementAt(i)) & event.tags2) != 0)
                              Container(
                                margin: const EdgeInsets.only(left: 30.0, bottom: 10.0),
                                child: Text(
                                  '•  ${runTags2.keys.elementAt(i)}',
                                  style: listValueStyle,
                                ),
                              )

                          //for (dynamic tag in runTags) Text(tag.key)
                        ],
                      ),
                    ),
                  ],
                ),
          (event.eventDescription ?? '') == ''
              ? Container()
              : const FancyDivider(
                  key: Key('67020392'),
                  innerColor: Colors.white,
                  topMargin: 30.0,
                ),
          (event.eventDescription ?? '') == ''
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0, bottom: 20.0),
                  child: Linkify(
                    text: event.eventDescription!.replaceAll('\r\n', '\n'),
                    style: bodyStyle.copyWith(fontSize: 20 * G0<DeviceInfo>().textClamp50),
                    linkStyle: bodyStyleYellow,
                    onOpen: (LinkableElement link) async {
                      if (Utilities.isValidUrl(link.url)) {
                        await launchUrl(
                          Uri.parse(link.url),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Unable to open link', 'Harrier Central was unable to open ${link.url}', 'OK');
                      }
                    },
                  ),
                ),
          // for the Facebook button, we want to check
          // if the actual eventUrl is empty without
          // considering the Kennel Events URL

          if ((((event.eventFacebookId ?? '') != '') && (event.eventInboundIntegrationId == INBOUND_INTEGRATION_FACEBOOK) && ((event.eventUrl == null) || (event.eventUrl!.isEmpty))) ||
              ((event.evtDisseminateAllowWebLinks == 1) || (kennel.disseminateAllowWebLinks == 1))) ...<Widget>[
            const FancyDivider(
              key: Key('40019292'),
              innerColor: Colors.white,
              topMargin: 30.0,
            ),
          ],

          if ((event.evtDisseminateAllowWebLinks == 1) || (kennel.disseminateAllowWebLinks == 1)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: ElevatedButton(
                // style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                child: Text(
                  'Copy HC Web link',
                  style: textStyleButton,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textScaleFactor: G0<DeviceInfo>().textClamp50,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: 'https://www.hashruns.org/#/RID?publicEventId=${event.publicEventId}&textTheme=light'));

                  await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Link copied', 'A link to the event on Harrier Central has been copied to you clipboard', 'OK');
                },
              ),
            ),
          ],

          if (((event.eventFacebookId ?? '') != '') && (event.eventInboundIntegrationId == INBOUND_INTEGRATION_FACEBOOK) && ((event.eventUrl == null) || (event.eventUrl!.isEmpty))) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 40.0),
              child: ElevatedButton(
                style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                child: Image.asset('images/other/visit_event_on_fb.png', height: 60.0, width: 325.0),
                onPressed: () async {
                  final String linkUrl = 'https://www.facebook.com/${event.eventFacebookId}';
                  if (Utilities.isValidUrl(linkUrl)) {
                    await launchUrl(
                      Uri.parse(linkUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Unable to open link', 'Harrier Central was unable to open $linkUrl', 'OK');
                  }
                },
              ),
            ),
          ],
          //
          if (!(((event.eventFacebookId ?? '') != '') && (event.eventInboundIntegrationId == INBOUND_INTEGRATION_FACEBOOK)) &&
              (eventUrlWithKennelBackup != null) &&
              (eventUrlWithKennelBackup!.isNotEmpty)) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 40.0),
              child: ElevatedButton(
                style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                child: Image.asset('images/icons/visit_run_on_web.png', height: 60.0, width: 325.0),
                onPressed: () async {
                  if (Utilities.isValidUrl(eventUrlWithKennelBackup!)) {
                    await launchUrl(
                      Uri.parse(eventUrlWithKennelBackup!),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Unable to open link', 'Harrier Central was unable to open $eventUrlWithKennelBackup', 'OK');
                  }
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}
