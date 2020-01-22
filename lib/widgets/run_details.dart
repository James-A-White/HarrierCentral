import 'dart:core';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_linkify/flutter_linkify.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/narrow_event_service.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harrier_central/util/utilities.dart';
import 'package:harrier_central/widgets/fancy_divider.dart';
import 'package:harrier_central/util/styles.dart';
import 'package:harrier_central/widgets/zoomable_image_page.dart';

class RunDetails extends StatelessWidget {
  const RunDetails({
    @required this.event, 
    this.kennel, 
    this.digitsAfterDecimal,
    this.currencySymbol,
    this.distancePreference,
    this.distToEvent,
    this.paymentLinkUrl
    });

  final NarrowEventsModel event;
  final KennelsModel kennel;
  final int digitsAfterDecimal;
  final String currencySymbol;
  final int distancePreference;
  final num distToEvent;
  final String paymentLinkUrl;

  static const int flexLeft = 30;
  static const int flexRight = 70;

  static const num spaceBetweenColumns = 11.0;
  static const num spaceBetweenRows = 28.0;

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
                                pageTitle: 'Zoomable Event Image',
                                imageUrl: event.eventImage,
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
                ? const Padding(
                    padding: EdgeInsets.only(top: 32.0, bottom: 0.0),
                    child: FancyDivider(innerColor: Colors.white),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 10),
              child: AutoSizeText(event.eventName, style: titleStyle, textAlign: TextAlign.center, maxLines: 2),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
              child: FancyDivider(innerColor: Colors.white),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Row(
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
                  SizedBox(
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
              Row(
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
                  SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                      child: Text(
                        DateFormat('E, MMM d').format(event.eventStartDatetime),
                        style: listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      flex: flexRight),
                ],
              ),
              Row(
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
                  SizedBox(
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
              Row(
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
                  SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                      child: Text(
                        ((event.eventPriceForMembers ?? kennel.defaultPriceForMembers ?? 0) > 0)
                            ? '${Utilities.getFormattedMoney(event.eventPriceForMembers ?? kennel.defaultPriceForMembers ?? 0, digitsAfterDecimal, currencySymbol)} (members)'
                            : '',
                        style: listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      flex: flexRight),
                ],
              ),
              Row(
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
                  SizedBox(
                    height: 0,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                      child: Text(
                        ((event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers ?? 0) > 0)
                            ? '${Utilities.getFormattedMoney(event.eventPriceForNonMembers ?? kennel.defaultPriceForNonMembers ?? 0, digitsAfterDecimal, currencySymbol)} (non-members)'
                            : '',
                        style: listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      flex: flexRight),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Bag drop:',
                      style: listLabelStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                      child: Text(
                        'Unknown',
                        style: listValueStyle,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      flex: flexRight),
                ],
              ),
              Row(
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
                  SizedBox(
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
              hasLocationPermissions
                          ? 
              Row(
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
                  SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                      child: Text(
                              hasLocationPermissions ? distToEvent >= 0 ? Utilities.getDistance(distToEvent, context, isMetric: distancePreference == 0) + ' from here' : '<unknown>' : '',
                              style: listValueStyle,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          ,
                      flex: hasLocationPermissions ? flexRight : 0),
                ],
              ) : Container(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Street:',
                      style: listLabelStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flex: flexLeft,
                  ),
                  SizedBox(
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
              Row(
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
                  SizedBox(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Location:',
                      style: listLabelStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                    ),
                    flex: flexLeft,
                  ),
                  SizedBox(
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
            ]),
            (paymentLinkUrl == '')
                ? Container()
                : const Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: FancyDivider(innerColor: Colors.white),
                  ),
            (paymentLinkUrl == '')
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(top: 30.0, right: 20.0, left: 20.0, bottom: 20.0),
                    child: RaisedButton(
                      onPressed: () async {
                        if (await canLaunch(paymentLinkUrl)) {
                          await launch(paymentLinkUrl);
                        } else {
                          Utilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open $paymentLinkUrl', 'OK');
                        }
                      },
                      child: Text('Pay for Hash', style: buttonTextStyle),
                    ),
                  ),
            (event.eventDescription ?? '') == ''
                ? Container()
                : const Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: FancyDivider(innerColor: Colors.white),
                  ),
            (event.eventDescription ?? '') == ''
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(top: 30.0, right: 20.0, left: 20.0, bottom: 20.0),
                    child: Linkify(
                      text: event.eventDescription.replaceAll('\r\n', '\n'),
                      style: bodyStyle,
                      linkStyle: bodyStyleYellow,
                      humanize: true,
                      onOpen: (LinkableElement link) async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        } else {
                          Utilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open ${link.url}', 'OK');
                        }
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
    

  }
}
