import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

// import 'dart:core';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';

// import 'package:flutter_linkify/flutter_linkify.dart';
// import 'package:ive_flutter_core/widgets/zoomable_image_page.dart';

// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:harrier_central/data/hc3_services/kennels_service.dart';
// import 'package:harrier_central/data/hc3_services/events_service.dart';
// import 'package:harrier_central/util/constants.dart';
// import 'package:harrier_central/util/globals.dart';

// import 'package:url_launcher/url_launcher.dart';

// import 'package:harrier_central/util/utilities.dart';
// import 'package:ive_flutter_core/widgets/fancy_divider.dart';

// import 'package:harrier_central/util/styles.dart';
// import 'package:ive_flutter_core/util/core_utilities.dart';

class RunDetails extends StatelessWidget {
  const RunDetails(
    this.event,
    this.kennel,
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.distancePreference,
    this.distToEvent,
    this.paymentLinkUrl,
    this.showPaymentOptions, {
    this.isMember = 0,
    this.isPaid = 0,
    this.rsvpState = 0,
    this.processPayment,
  });

  final EventModel event;
  final KennelsModel kennel;
  final int digitsAfterDecimal;
  final String currencySymbol;
  final int distancePreference;
  final num distToEvent;
  final String paymentLinkUrl;
  final bool showPaymentOptions;
  final int isMember;
  final int isPaid;
  final int rsvpState;
  final Function processPayment;

  static const int flexLeft = 30;
  static const int flexRight = 70;

  static const num spaceBetweenColumns = 11.0;
  static const num spaceBetweenRows = 26.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Details
      // decoration:
      //     BoxDecoration(color: Theme.of(context).selectedRowColor),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ((event.eventImage ?? '').isNotEmpty && event.eventImage.startsWith('http'))
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GestureDetector(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => ZoomableImagePage(
                                key: UniqueKey(),
                                pageTitle: 'Zoomable Event Image',
                                imageUrl: event.eventImage,
                                appBarBackgroundColor: themeAppBarBackground,
                                background: Backgrounds.defaultHcBackground(),
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: event.eventImage,
                          // errorWidget:
                          //     (BuildContext context, String url, Exception error) =>
                          //         const  Icon(Icons.error),
                        )
                        //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
                        ),
                  )
                : Container(),
            ((event.eventImage ?? '').isNotEmpty && event.eventImage.startsWith('http'))
                ? Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 0.0),
                    child: FancyDivider(key: UniqueKey(), innerColor: Colors.white),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 10),
              child: AutoSizeText(event.eventName, style: titleStyle, textAlign: TextAlign.center, maxLines: 2),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 10.0),
              child: FancyDivider(key: UniqueKey(), innerColor: Colors.white),
            ),
            Text('Event details', style: headingStyle),
            const SizedBox(
              height: 15.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  //height: spaceBetweenRows,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Kennel:',
                          style: listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        flex: flexLeft,
                      ),
                      const SizedBox(
                        height: spaceBetweenRows,
                        width: spaceBetweenColumns,
                      ),
                      Expanded(
                          child: Text(
                            '${kennel.kennelName}',
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexRight),
                    ],
                  ),
                ),
                ((event.eventNumber ?? 0) == 0) || (event.isCountedRun == 0)
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Run #:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  '${event.eventNumber}',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
                Container(
                  //height: spaceBetweenRows,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Date:',
                          style: listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        flex: flexLeft,
                      ),
                      const SizedBox(
                        height: spaceBetweenRows,
                        width: spaceBetweenColumns,
                      ),
                      Expanded(
                          child: Text(
                            DateFormat('E, MMM d, yyyy').format(event.eventStartDatetime),
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexRight),
                    ],
                  ),
                ),
                Container(
                  //height: spaceBetweenRows,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Time:',
                          style: listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        flex: flexLeft,
                      ),
                      const SizedBox(
                        height: spaceBetweenRows,
                        width: spaceBetweenColumns,
                      ),
                      Expanded(
                          child: Text(
                            DateFormat('h:mm a').format(event.eventStartDatetime),
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexRight),
                    ],
                  ),
                ),
                if ((event.locationOneLineDesc ?? '') != '') ...<Widget>[
                  Container(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Place:',
                            style: listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(
                          height: spaceBetweenRows,
                          width: spaceBetweenColumns,
                        ),
                        Expanded(
                            child: Text(
                              event.locationOneLineDesc ?? '',
                              style: listValueStyle,
                              textAlign: TextAlign.left,

                              //maxLines: ,
                              //overflow: TextOverflow.ellipsis,
                            ),
                            flex: flexRight),
                      ],
                    ),
                  ),
                ],
                ((event.eventGeographicScope ?? 0) == 0)
                    ? Container()
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Event:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  getEventText(event),
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
                Container(
                  //height: spaceBetweenRows,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Run fees:',
                          style: listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        flex: flexLeft,
                      ),
                      const SizedBox(
                        height: spaceBetweenRows,
                        width: spaceBetweenColumns,
                      ),
                      Expanded(
                          child: Text(
                            ((event.eventPriceForMembers ?? kennel.defaultPriceForMembers ?? 0) > 0)
                                ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForMembers ?? kennel.defaultPriceForMembers ?? 0, digitsAfterDecimal, currencySymbol)} (members)'
                                : '',
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexRight),
                    ],
                  ),
                ),
                Container(
                  //height: spaceBetweenRows,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '',
                          style: listLabelStyle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        flex: flexLeft,
                      ),
                      const SizedBox(
                        height: 0,
                        width: spaceBetweenColumns,
                      ),
                      Expanded(
                          child: Text(
                            ((event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers ?? 0) > 0)
                                ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers ?? 0, digitsAfterDecimal, currencySymbol)} (non-members)'
                                : '',
                            style: listValueStyle,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexRight),
                    ],
                  ),
                ),
                (event.eventPriceForExtras ?? 0) == 0
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Extra fee:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  ((event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers ?? 0) > 0)
                                      ? '${IveCoreUtilities.getFormattedMoney(event.eventPriceForExtras ?? 0, digitsAfterDecimal, currencySymbol)} (${event.extrasDescription})'
                                      : '',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
                (event.hares ?? '') == ''
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Hares:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  event.hares ?? '',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
                G0<AppModel>().hasLocationPermissions
                    ? Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Distance:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  G0<AppModel>().hasLocationPermissions
                                      ? distToEvent >= 0
                                          ? Utilities.getDistance(distToEvent, context, isMetric: distancePreference == 0) + ' from here'
                                          : '<unknown>'
                                      : '',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: G0<AppModel>().hasLocationPermissions ? flexRight : 0),
                          ],
                        ),
                      )
                    : const SizedBox(height: 0.0, width: 0.0),
                if ((event.locationStreet ?? '') != '') ...<Widget>[
                  Container(
                    //height: spaceBetweenRows,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Street:',
                            style: listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(
                          height: spaceBetweenRows,
                          width: spaceBetweenColumns,
                        ),
                        Expanded(
                            child: Text(
                              event.locationStreet ?? '',
                              style: listValueStyle,
                              textAlign: TextAlign.left,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            flex: flexRight),
                      ],
                    ),
                  ),
                ],
                if ((((event.locationPostCode == null) || (event.locationPostCode.isEmpty)) ? '' : event.locationPostCode + ' ') + (event.locationCity ?? '') != '') ...<Widget>[
                  Container(
                    //height: spaceBetweenRows,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'City:',
                            style: listLabelStyle,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          flex: flexLeft,
                        ),
                        const SizedBox(
                          height: spaceBetweenRows,
                          width: spaceBetweenColumns,
                        ),
                        Expanded(
                            child: Text(
                              (((event.locationPostCode == null) || (event.locationPostCode.isEmpty)) ? '' : event.locationPostCode + ' ') + (event.locationCity ?? ''),
                              style: listValueStyle,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            flex: flexRight),
                      ],
                    ),
                  ),
                ],
                ((event.locationSubRegion ?? '') == '')
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                event.locationCountry.toLowerCase() == 'united states' ? 'County' : 'Region:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  event.locationSubRegion ?? '',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
                ((event.locationRegion ?? '') == '')
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'State:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  event.locationRegion ?? '',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
                ((event.locationCountry ?? '') == '')
                    ? const SizedBox(height: 0.0, width: 0.0)
                    : Container(
                        //height: spaceBetweenRows,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Country:',
                                style: listLabelStyle,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              flex: flexLeft,
                            ),
                            const SizedBox(
                              height: spaceBetweenRows,
                              width: spaceBetweenColumns,
                            ),
                            Expanded(
                                child: Text(
                                  event.locationCountry ?? '',
                                  style: listValueStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                flex: flexRight),
                          ],
                        ),
                      ),
              ],
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
                        processPayment(r, p);
                      }
                    },
                  ),

            // (paymentLinkUrl == '')
            //     ? Container()
            //     : const Padding(
            //         padding: EdgeInsets.only(top: 32.0),
            //         child: FancyDivider(key: UniqueKey(),innerColor: Colors.white),
            //       ),
            // (paymentLinkUrl == '')
            //     ? Container()
            //     : Padding(
            //         padding: const EdgeInsets.only(top: 30.0, right: 20.0, left: 20.0, bottom: 20.0),
            //         child: ElevatedButton(
            //           onPressed: () async {
            //             if (await canLaunch(paymentLinkUrl)) {
            //               await launch(paymentLinkUrl);
            //             } else {
            //               IveCoreUtilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open $paymentLinkUrl', 'OK');
            //             }
            //           },
            //           child: Text('Pay for Hash', style: buttonTextStyle),
            //         ),
            //       ),
            (event.tags1 ?? 0) == 0
                ? Container()
                : Column(
                    children: <Widget>[
                      FancyDivider(
                        key: UniqueKey(),
                        innerColor: Colors.white,
                        topMargin: 30.0,
                        bottomMargin: 10.0,
                      ),
                      Text('Event tags', style: headingStyle),
                      const SizedBox(
                        height: 15.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: G0<DeviceInfo>().deviceWidth), // this is required to force the column to be the full width of the device
                          for (int i = 0; i < runTags.length; i++)
                            ((runTags.values.elementAt(i) ?? 0) & event.tags1) == 0
                                ? Container()
                                : // TODO(James): Figure out how to do this without adding empty containers
                                Container(
                                    child: Text(
                                      '•  ' + runTags.keys.elementAt(i),
                                      style: listValueStyle,
                                    ),
                                    margin: const EdgeInsets.only(left: 30.0, bottom: 10.0),
                                  )

                          //for (dynamic tag in runTags) Text(tag.key)
                        ],
                      ),
                    ],
                  ),
            (event.eventDescription ?? '') == ''
                ? Container()
                : FancyDivider(
                    key: UniqueKey(),
                    innerColor: Colors.white,
                    topMargin: 30.0,
                  ),
            (event.eventDescription ?? '') == ''
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0, bottom: 20.0),
                    child: Linkify(
                      text: event.eventDescription.replaceAll('\r\n', '\n'),
                      style: bodyStyle,
                      linkStyle: bodyStyleYellow,
                      onOpen: (LinkableElement link) async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        } else {
                          IveCoreUtilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open ${link.url}', 'OK');
                        }
                      },
                    ),
                  ),
            if ((event.eventFacebookId ?? '') != '') ...<Widget>[
              FancyDivider(
                key: UniqueKey(),
                innerColor: Colors.white,
                topMargin: 30.0,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 40.0),
                child: ElevatedButton(
                  style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                  child: Image.asset('images/other/visit_event_on_fb.png', height: 60.0, width: 325.0),
                  onPressed: () async {
                    final String linkUrl = 'https://www.facebook.com/${event.eventFacebookId}';
                    if (await canLaunch(linkUrl)) {
                      await launch(linkUrl);
                    } else {
                      IveCoreUtilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open $linkUrl', 'OK');
                    }
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  String getEventText(EventModel event) {
    String result = '';
    switch (event.eventGeographicScope) {
      case 1:
        result = 'Local event';
        break;
      case 2:
        result = 'Regional event';
        break;
      case 3:
        result = 'Nash hash';
        break;
      case 4:
        result = 'Inter hash';
        break;
      case 5:
        result = 'World interhash / global event';
        break;
    }
    return result;
  }
}
