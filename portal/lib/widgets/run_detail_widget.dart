//import 'dart:html' show window;

import 'package:hcportal/imports.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;

class RunDetailWidget extends StatelessWidget {
  const RunDetailWidget({
    required this.rdm,
    required this.participants,
    required this.textThemeIsLight,
    required this.isNarrowScreen,
    super.key,
    this.backgroundColor,
  });

  final RunDetailsModel rdm;
  final List<ParticipantModel> participants;
  final bool textThemeIsLight;
  final bool isNarrowScreen;
  final String? backgroundColor;

  static const int flexLeft = 30;
  static const int flexRight = 70;

  static const double spaceBetweenColumns = 11;
  static const double spaceBetweenRows = 26;

  List<Widget> _getRow(
    String label,
    String? internalField,
    String? externalField,
    int useExternalField,
  ) {
    if ((useExternalField == 1) && ((externalField ?? '') == '')) {
      return <Widget>[];
    }
    if ((useExternalField != 1) && ((internalField ?? '') == '')) {
      return <Widget>[];
    }

    return <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: flexLeft,
            child: Text(
              label,
              style: textThemeIsLight
                  ? listLabelStyle
                  : listLabelStyle.copyWith(color: Colors.blue.shade900),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(
            height: spaceBetweenRows,
            width: spaceBetweenColumns,
          ),
          Expanded(
            flex: flexRight,
            child: Text(
              (useExternalField == 1 ? externalField : internalField) ?? '',
              style: textThemeIsLight
                  ? listValueStyle
                  : listValueStyle.copyWith(color: Colors.black),
              textAlign: TextAlign.left,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ];
  }

  String _getMapUrl(
    BuildContext context,
    RunDetailsModel rdm,
    bool suppressWarning, {
    bool useGoogle = false,
    bool useApple = false,
  }) {
    var latStr = '';
    var lonStr = '';
    var address = '';
    var url = '';

    assert(
      useGoogle || useApple,
      'Must select either Google or Apple maps provider',
    );

    if ((rdm.useFbLatLon != 0) &&
        (rdm.fbLongitude != null) &&
        (rdm.fbLongitude! <= 180.0) &&
        (rdm.fbLongitude! >= -180.0)) {
      latStr = rdm.fbLatitude.toString();
      lonStr = rdm.fbLongitude.toString();
    } else if ((rdm.useFbLatLon == 0) &&
        (rdm.hcLongitude != null) &&
        (rdm.hcLongitude! <= 180.0) &&
        (rdm.hcLongitude! >= -180.0)) {
      latStr = rdm.hcLatitude.toString();
      lonStr = rdm.hcLongitude.toString();
    }

    if (latStr.isEmpty || lonStr.isEmpty) {
      if (rdm.locationStreet != null) {
        address = '$address${rdm.locationStreet!} ';
      }

      if (rdm.locationCity != null) {
        address = '$address${rdm.locationCity!} ';
      }

      if (rdm.locationPostCode != null) {
        address = '$address${rdm.locationPostCode!} ';
      }

      if (rdm.locationCountry != null) {
        address = '$address${rdm.locationCountry!} ';
      }

      address = address.trim();
    }

    if ((latStr.isNotEmpty) && (lonStr.isNotEmpty)) {
      url = '$latStr,$lonStr';
    } else if (address.isNotEmpty) {
      address = address.replaceAll(' ', '+');
      address = Uri.encodeComponent(address);
      url = address;
    } else {
      if (!suppressWarning) {
        unawaited(IveCoreUtilities.showAlert(
          context,
          'No location information available',
          'There is no location information available for this run and so we cannot display a map',
          'OK',
        ));
      }
    }

    if ((url.isNotEmpty) && useGoogle) {
      url = 'https://www.google.com/maps/search/?api=1&query=$url';
    }

    if (useApple && (latStr.isNotEmpty) && (lonStr.isNotEmpty)) {
      url = 'https://maps.apple.com/?sll=$latStr,$lonStr';
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = Get.mediaQuery.size.width / 1180.1;
    // print(Get.mediaQuery.size.width);
    // print(screenWidth);
    return Column(
      children: <Widget>[
        if (((rdm.useFbImage != 1
                        ? rdm.eventImage
                        : rdm.extEventImage) ??
                    '')
                .isNotEmpty &&
            (rdm.useFbImage != 1
                    ? rdm.eventImage
                    : rdm.extEventImage)!
                .startsWith('http')) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ZoomableImagePage2(
                      key: UniqueKey(),
                      pageTitle: 'Zoomable Event Image',
                      imageUrl: rdm.useFbImage != 1
                          ? rdm.eventImage
                          : rdm.extEventImage,
                      appBarBackgroundColor: themeAppBarBackground,
                      background: Backgrounds.defaultHcBackground(),
                    ),
                  ),
                );
              },
              child: HcNetworkImage(
                (rdm.useFbImage != 1
                    ? rdm.eventImage
                    : rdm.extEventImage)!,
                errorBuilder: (
                  BuildContext context,
                  Object exception,
                  StackTrace? stackTrace,
                ) {
                  // Appropriate logging or analytics, e.g.
                  // myAnalytics.recordError(
                  //   'An error occurred loading "https://example.does.not.exist/image.jpg"',
                  //   exception,
                  //   stackTrace,
                  // );
                  return Text(
                    '😢 Missing Image 😢',
                    style: TextStyle(
                      color: textThemeIsLight
                          ? Colors.white
                          : Colors.blue.shade900,
                      fontSize: 24,
                    ),
                  );
                },
              ),
              //decoration: BoxDecoration(color: Theme.of(context).selectedRowColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: FancyDivider(
              key: UniqueKey(),
              innerColor:
                  textThemeIsLight ? Colors.white : Colors.blue.shade900,
            ),
          ),
        ],

        Padding(
          padding:
              const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if ((rdm.kennelLogo != null) &&
                  (rdm.kennelShortName != null)) ...<Widget>[
                KennelLogo(
                  kennelLogoUrl: rdm.kennelLogo!,
                  kennelShortName: rdm.kennelShortName!,
                  logoHeight: (isNarrowScreen) ? 130.0 : 75.0,
                  rightPadding: isNarrowScreen ? 0.0 : 25.0,
                ),
              ],
              if (!isNarrowScreen) ...<Widget>[
                Flexible(
                  child: AutoSizeText(
                    ((rdm.useFbRunDetails != 1) ||
                            (rdm.extEventName == null))
                        ? rdm.eventName
                        : rdm.extEventName!,
                    minFontSize: 9,
                    style: textThemeIsLight
                        ? titleStyle
                        : titleStyle.copyWith(color: Colors.blue.shade900),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isNarrowScreen) ...<Widget>[
          const SizedBox(height: 15),
          AutoSizeText(
            ((rdm.useFbRunDetails != 1) ||
                    (rdm.extEventName == null))
                ? rdm.eventName
                : rdm.extEventName!,
            minFontSize: 9,
            style: textThemeIsLight
                ? titleStyle
                : titleStyle.copyWith(color: Colors.blue.shade900),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 10),
          child: FancyDivider(
            key: UniqueKey(),
            innerColor:
                textThemeIsLight ? Colors.white : Colors.blue.shade900,
          ),
        ),
        Text(
          'Event details',
          style: textThemeIsLight
              ? headingStyle
              : headingStyle.copyWith(color: Colors.blue.shade900),
        ),
        const SizedBox(
          height: 15,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  flex: flexLeft,
                  child: Text(
                    'Kennel:',
                    style: textThemeIsLight
                        ? listLabelStyle
                        : listLabelStyle.copyWith(color: Colors.blue.shade900),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: spaceBetweenRows,
                  width: spaceBetweenColumns,
                ),
                Expanded(
                  flex: flexRight,
                  child: Text(
                    rdm.kennelName ?? '<no kennel>',
                    style: textThemeIsLight
                        ? listValueStyle
                        : listValueStyle.copyWith(color: Colors.black),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if ((rdm.eventNumber != 0) &&
                (rdm.isCountedRun != 0)) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: flexLeft,
                    child: Text(
                      'Run #:',
                      style: textThemeIsLight
                          ? listLabelStyle
                          : listLabelStyle.copyWith(
                              color: Colors.blue.shade900,
                            ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                    flex: flexRight,
                    child: Text(
                      '${rdm.eventNumber}',
                      style: textThemeIsLight
                          ? listValueStyle
                          : listValueStyle.copyWith(color: Colors.black),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            Row(
              children: <Widget>[
                Expanded(
                  flex: flexLeft,
                  child: Text(
                    'Date:',
                    style: textThemeIsLight
                        ? listLabelStyle
                        : listLabelStyle.copyWith(color: Colors.blue.shade900),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: spaceBetweenRows,
                  width: spaceBetweenColumns,
                ),
                Expanded(
                  flex: flexRight,
                  child: Text(
                    DateFormat('E, MMM d, yyyy').format(
                      ((rdm.useFbRunDetails != 1) ||
                              (rdm.extEventStartDatetime == null))
                          ? rdm.eventStartDatetime
                          : rdm.extEventStartDatetime!,
                    ),
                    style: textThemeIsLight
                        ? listValueStyle
                        : listValueStyle.copyWith(color: Colors.black),
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
                  flex: flexLeft,
                  child: Text(
                    'Time:',
                    style: textThemeIsLight
                        ? listLabelStyle
                        : listLabelStyle.copyWith(color: Colors.blue.shade900),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: spaceBetweenRows,
                  width: spaceBetweenColumns,
                ),
                Expanded(
                  flex: flexRight,
                  child: Text(
                    DateFormat('h:mm a').format(
                      ((rdm.useFbRunDetails != 1) ||
                              (rdm.extEventStartDatetime == null))
                          ? rdm.eventStartDatetime
                          : rdm.extEventStartDatetime!,
                    ),
                    style: textThemeIsLight
                        ? listValueStyle
                        : listValueStyle.copyWith(color: Colors.black),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            ..._getRow(
              'Place',
              rdm.locationOneLineDesc,
              rdm.extLocationOneLineDesc,
              rdm.useFbRunDetails,
            ),

            if (rdm.eventGeographicScope != 0) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: flexLeft,
                    child: Text(
                      'Event:',
                      style: textThemeIsLight
                          ? listLabelStyle
                          : listLabelStyle.copyWith(
                              color: Colors.blue.shade900,
                            ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                    flex: flexRight,
                    child: Text(
                      SPECIAL_EVENT_STRINGS.keys
                          .elementAt(rdm.eventGeographicScope),
                      style: textThemeIsLight
                          ? listValueStyle
                          : listValueStyle.copyWith(color: Colors.black),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  flex: flexLeft,
                  child: Text(
                    'Run fees:',
                    style: textThemeIsLight
                        ? listLabelStyle
                        : listLabelStyle.copyWith(color: Colors.blue.shade900),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: spaceBetweenRows,
                  width: spaceBetweenColumns,
                ),
                Expanded(
                  flex: flexRight,
                  child: Text(
                    ((rdm.eventPriceForMembers ??
                                rdm.kennelDefaultEventPriceForMembers ??
                                0) >
                            0)
                        ? '${IveCoreUtilities.getFormattedMoney(rdm.eventPriceForMembers ?? rdm.kennelDefaultEventPriceForMembers ?? 0, rdm.digitsAfterDecimal ?? 2, rdm.currencySymbol ?? '^')} (members)'
                        : '',
                    style: textThemeIsLight
                        ? listValueStyle
                        : listValueStyle.copyWith(color: Colors.black),
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
                  flex: flexLeft,
                  child: Text(
                    '',
                    style: textThemeIsLight
                        ? listLabelStyle
                        : listLabelStyle.copyWith(color: Colors.blue.shade900),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: 0,
                  width: spaceBetweenColumns + .0,
                ),
                Expanded(
                  flex: flexRight,
                  child: Text(
                    ((rdm.eventPriceForNonMembers ??
                                rdm.kennelDefaultEventPriceForNonMembers ??
                                0) >
                            0)
                        ? '${IveCoreUtilities.getFormattedMoney(rdm.eventPriceForNonMembers ?? rdm.kennelDefaultEventPriceForNonMembers ?? 0, rdm.digitsAfterDecimal ?? 2, rdm.currencySymbol ?? '^')} (non-members)'
                        : '',
                    style: textThemeIsLight
                        ? listValueStyle
                        : listValueStyle.copyWith(color: Colors.black),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if ((rdm.eventPriceForExtras ?? 0) != 0) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: flexLeft,
                    child: Text(
                      'Extra fee:',
                      style: textThemeIsLight
                          ? listLabelStyle
                          : listLabelStyle.copyWith(
                              color: Colors.blue.shade900,
                            ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                    flex: flexRight,
                    child: Text(
                      ((rdm.eventPriceForNonMembers ??
                                  rdm
                                      .kennelDefaultEventPriceForNonMembers ??
                                  0) >
                              0)
                          ? '${IveCoreUtilities.getFormattedMoney(rdm.eventPriceForExtras ?? 0, rdm.digitsAfterDecimal ?? 2, rdm.currencySymbol ?? '^')} (${rdm.extrasDescription})'
                          : '',
                      style: textThemeIsLight
                          ? listValueStyle
                          : listValueStyle.copyWith(color: Colors.black),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if ((rdm.hares ?? '') != '') ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: flexLeft,
                    child: Text(
                      'Hares:',
                      style: textThemeIsLight
                          ? listLabelStyle
                          : listLabelStyle.copyWith(
                              color: Colors.blue.shade900,
                            ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(
                    height: spaceBetweenRows,
                    width: spaceBetweenColumns,
                  ),
                  Expanded(
                    flex: flexRight,
                    child: Text(
                      rdm.hares ?? '',
                      style: textThemeIsLight
                          ? listValueStyle
                          : listValueStyle.copyWith(color: Colors.black),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // (G0<AppModel>().hasLocationPermissions) && isMapAndDistanceValid
            //     ? Row(
            //         children: <Widget>[
            //           Expanded(
            //             child: Text(
            //               'Distance:',
            //               style: textThemeIsLight ? listLabelStyle : listLabelStyle.copyWith(color:Colors.blue.shade900),
            //               textAlign: TextAlign.right,
            //               maxLines: 1,
            //               overflow: TextOverflow.ellipsis,
            //             ),
            //             flex: flexLeft,
            //           ),
            //           const SizedBox(
            //             height: spaceBetweenRows,
            //             width: spaceBetweenColumns,
            //           ),
            //           Expanded(
            //               child: Text(
            //                 G0<AppModel>().hasLocationPermissions
            //                     ? distToEvent >= 0
            //                         ? Utilities.getDistance(distToEvent, context, isMetric: distancePreference == 0) + ' from here'
            //                         : '<unknown>'
            //                     : '',
            //                 style: textThemeIsLight ? listValueStyle : listValueStyle.copyWith(color: Colors.black),
            //                 textAlign: TextAlign.left,
            //                 maxLines: 1,
            //                 overflow: TextOverflow.ellipsis,
            //               ),
            //               flex: G0<AppModel>().hasLocationPermissions ? flexRight : 0),
            //         ],
            //       )
            //     : const SizedBox(height: 0.0, width: 0.0),

            ..._getRow(
              'Street:',
              rdm.locationStreet,
              rdm.extLocationStreet,
              rdm.useFbLocation,
            ),
            ..._getRow(
              'Post code:',
              rdm.locationPostCode,
              rdm.extLocationPostCode,
              rdm.useFbLocation,
            ),
            ..._getRow(
              'City:',
              rdm.locationCity,
              rdm.extLocationCity,
              rdm.useFbLocation,
            ),
            ..._getRow(
              'Sub-region:',
              rdm.locationSubRegion,
              rdm.extLocationSubRegion,
              rdm.useFbLocation,
            ),
            ..._getRow(
              'Region:',
              rdm.locationRegion,
              rdm.extLocationRegion,
              rdm.useFbLocation,
            ),
            ..._getRow(
              'Country:',
              rdm.locationCountry,
              rdm.extLocationCountry,
              rdm.useFbLocation,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 40),
              child: ElevatedButton(
                //style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                child: const Text(
                  'Copy link to run',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (rdm.publicEventId != null) {
                    final isDebugging =
                        web.window.location.href.contains('localhost');

                    final url =
                        '${isDebugging ? 'localhost:8080' : 'https://www.hashruns.org'}/${rdm.kennelUniqueShortName}/${rdm.absoluteEventNumber ?? rdm.eventNumber}';

                    await Clipboard.setData(ClipboardData(text: url));

                    if (!context.mounted) return;
                    await IveCoreUtilities.showAlert(
                      context,
                      'Copy link',
                      'The link to this run was copied to your clipboard',
                      'OK',
                    );
                  }
                },
              ),
            ),
            if (_getMapUrl(context, rdm, true, useGoogle: true)
                .isNotEmpty) ...<Widget>[
              const SizedBox(width: 40),
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 40),
                child: ElevatedButton(
                  //style: ButtonStyle(shadowColor: MaterialStateProperty.all(Colors.transparent), backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                  child: const Text(
                    'Open Map',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    final linkUrl =
                        _getMapUrl(context, rdm, false, useGoogle: true);
                    if (Uri.parse(linkUrl).isAbsolute) {
                      openWindow(linkUrl, '_blank');
                      //js.context.callMethod('open', <String>[linkUrl]);
                    } else {
                      await IveCoreUtilities.showAlert(
                        context,
                        'Unable to open link',
                        'Harrier Central was unable to open $linkUrl',
                        'OK',
                      );
                    }
                    // if (await canLaunch(linkUrl)) {
                    //   await launch(linkUrl);
                    // } else {
                    //   linkUrl = _getMapUrl(rdm, false, useApple: true);
                    //   if (await canLaunch(linkUrl)) {
                    //     await launch(linkUrl);
                    //   } else {
                    //     await IveCoreUtilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open $linkUrl', 'OK');
                    //   }
                    // }
                  },
                ),
              ),
            ],
          ],
        ),

        // (paymentLinkUrl == '')
        //     ? Container()
        //     : const Padding(
        //         padding: EdgeInsets.only(top: 32.0),
        //         child: FancyDivider(key: UniqueKey(),innercolor: _textThemeIsDark ? Colors.white),
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
        //               await IveCoreUtilities.showAlert(context, 'Unable to open link', 'Harrier Central was unable to open $paymentLinkUrl', 'OK');
        //             }
        //           },
        //           child: Text('Pay for Hash', style: buttonTextStyle),
        //         ),
        //       ),
        if ((rdm.tags1 != 0) || (rdm.tags2 != 0)) ...<Widget>[
          Column(
            children: <Widget>[
              FancyDivider(
                key: UniqueKey(),
                innerColor: textThemeIsLight
                    ? Colors.white
                    : Colors.blue.shade900,
                topMargin: 30.0,
                bottomMargin: 10.0,
              ),
              Text(
                'Event tags',
                style: textThemeIsLight
                    ? headingStyle
                    : headingStyle.copyWith(color: Colors.blue.shade900),
              ),
              const SizedBox(
                height: 15,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < RUN_TAGS.length; i++)
                    if (((((RUN_TAGS.values.elementAt(i)) ~/ 4294967296) ==
                                1) &&
                            (((RUN_TAGS.values.elementAt(i)) &
                                    rdm.tags1 &
                                    0x7FFFFFFF) !=
                                0)) ||
                        ((((RUN_TAGS.values.elementAt(i)) ~/ 4294967296) ==
                                2) &&
                            (((RUN_TAGS.values.elementAt(i)) &
                                    rdm.tags2 &
                                    0x7FFFFFFF) !=
                                0))) ...<Widget>[
                      Container(
                        margin: const EdgeInsets.only(left: 30, bottom: 10),
                        child: Text(
                          '•  ${RUN_TAGS.keys.elementAt(i)}',
                          style: textThemeIsLight
                              ? listValueStyle
                              : listValueStyle.copyWith(color: Colors.black),
                        ),
                      ),
                    ],

                  //for (dynamic tag in runTags) Text(tag.key)
                ],
              ),
            ],
          ),
        ],

        if ((rdm.eventDescription.isNotEmpty) ||
            ((rdm.extEventDescription ?? '').isNotEmpty)) ...<Widget>[
          FancyDivider(
            key: UniqueKey(),
            innerColor:
                textThemeIsLight ? Colors.white : Colors.blue.shade900,
            topMargin: 30.0,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isNarrowScreen ? 20.0 : 80.0,
            ),
            child: rdm.useFbRunDetails != 1
                ? Linkify(
                    text: rdm.eventDescription.replaceAll('\r\n', '\n'),
                    style: textThemeIsLight
                        ? bodyStyle
                        : bodyStyle.copyWith(
                            color: Colors.black,
                          ),
                    linkStyle: textThemeIsLight
                        ? bodyStyleYellow
                        : bodyStyleYellow.copyWith(
                            color: Colors.blue.shade900,
                          ),
                    onOpen: (LinkableElement link) async {
                      if (Uri.parse(link.url).isAbsolute) {
                        openWindow(link.url, '_blank');
                      } else {
                        await IveCoreUtilities.showAlert(
                          context,
                          'Unable to open link',
                          'Harrier Central was unable to open ${link.url}',
                          'OK',
                        );
                      }
                    },
                  )
                : Linkify(
                    text: (rdm.extEventDescription ?? '')
                        .replaceAll('\r\n', '\n'),
                    style: textThemeIsLight
                        ? bodyStyle
                        : bodyStyle.copyWith(
                            color: Colors.black,
                          ),
                    linkStyle: textThemeIsLight
                        ? bodyStyleYellow
                        : bodyStyleYellow.copyWith(
                            color: Colors.blue.shade900,
                          ),
                    onOpen: (LinkableElement link) async {
                      if (Uri.parse(link.url).isAbsolute) {
                        openWindow(link.url, '_blank');
                      } else {
                        await IveCoreUtilities.showAlert(
                          context,
                          'Unable to open link',
                          'Harrier Central was unable to open ${link.url}',
                          'OK',
                        );
                      }
                    },
                  ),
          ),
        ],

        if ((rdm.eventFacebookId ?? '') != '') ...<Widget>[
          FancyDivider(
            key: UniqueKey(),
            innerColor:
                textThemeIsLight ? Colors.white : Colors.blue.shade900,
            topMargin: 30.0,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 40),
            child: ElevatedButton(
              style: ButtonStyle(
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: Image.asset(
                'images/other/visit_event_on_fb.png',
                height: 60,
                width: 325,
              ),
              onPressed: () async {
                final linkUrl =
                    'https://www.facebook.com/${rdm.eventFacebookId}';
                if (Uri.parse(linkUrl).isAbsolute) {
                  openWindow(linkUrl, '_blank');
                  //js.context.callMethod('open', <String>[linkUrl]);
                } else {
                  await IveCoreUtilities.showAlert(
                    context,
                    'Unable to open link',
                    'Harrier Central was unable to open $linkUrl',
                    'OK',
                  );
                }
              },
            ),
          ),
        ],

        const SizedBox(height: 15),
        if ((rdm.eventStartDatetime.isBefore(DateTime.now())) &&
            (participants.isNotEmpty)) ...<Widget>[
          FancyDivider(
            key: UniqueKey(),
            innerColor:
                textThemeIsLight ? Colors.white : Colors.blue.shade900,
            topMargin: 30.0,
          ),
          const SizedBox(height: 25),
          Text(
            'The Pack',
            style: textThemeIsLight
                ? headingStyle
                : headingStyle.copyWith(color: Colors.blue.shade900),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ParticipantsTable(participants),
          ),
          const SizedBox(height: 40),
        ],
      ],
    );
  }
}

class ParticipantsController extends GetxController {
  ParticipantsController(List<ParticipantModel> initialParticipants) {
    participants.value = initialParticipants;
    sortTable(0, true);
  }

  RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  RxBool sortAscending = true.obs;
  RxInt sortColumnIndex = 0.obs;

  void updateParticipants(List<ParticipantModel> newParticipants) {
    participants.value = newParticipants;
    sortTable(0, true);
  }

  List<ParticipantModel> get filteredParticipants =>
      participants.where((p) => p.attendanceState >= 20).toList();

  // have to ignore this because DataColumn onSort requires
  // the signature of sortTable to have a non-named bool parameter
  // ignore: avoid_positional_boolean_parameters
  void sortTable(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;

    switch (columnIndex) {
      case 0: // Sort by Name
        participants.sort(
          (a, b) => ascending
              ? a.displayName.compareTo(b.displayName)
              : b.displayName.compareTo(a.displayName),
        );
      case 1: // Sort by Total Runs
        participants.sort(
          (a, b) => ascending
              ? a.totalRunsThisKennel.compareTo(b.totalRunsThisKennel)
              : b.totalRunsThisKennel.compareTo(a.totalRunsThisKennel),
        );
      case 2: // Sort by Total Haring
        participants.sort(
          (a, b) => ascending
              ? a.totalHaringThisKennel.compareTo(b.totalHaringThisKennel)
              : b.totalHaringThisKennel.compareTo(a.totalHaringThisKennel),
        );
      case 3: // Sort by Amount Owed
        participants.sort((a, b) {
          // Extract numeric values for sorting
          final amountA = extractNumeric(a.amountOwedStr);
          final amountB = extractNumeric(b.amountOwedStr);

          // Perform the numeric comparison
          return ascending
              ? amountA.compareTo(amountB)
              : amountB.compareTo(amountA);
        });
      case 4: // Sort by Amount Paid
        participants.sort((a, b) {
          // Extract numeric values for sorting
          final amountA = extractNumeric(a.amountPaidStr);
          final amountB = extractNumeric(b.amountPaidStr);

          // Perform the numeric comparison
          return ascending
              ? amountA.compareTo(amountB)
              : amountB.compareTo(amountA);
        });
      case 5: // Sort by Credit Available
        participants.sort((a, b) {
          // Extract numeric values for sorting
          final amountA = extractNumeric(a.creditAvailableStr);
          final amountB = extractNumeric(b.creditAvailableStr);

          // Perform the numeric comparison
          return ascending
              ? amountA.compareTo(amountB)
              : amountB.compareTo(amountA);
        });
    }

    participants.refresh();
  }

  // Helper function to extract numeric value from the string
  num extractNumeric(String value) {
    final numericString = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return num.tryParse(numericString) ?? 0; // Convert to numeric value
  }
}

class ParticipantsTable extends StatelessWidget {
  ParticipantsTable(this.participants, {super.key}) {
    if (Get.isRegistered<ParticipantsController>()) {
      // Update the existing controller
      Get.find<ParticipantsController>().updateParticipants(participants);
    } else {
      // Create a new controller
      Get.put(ParticipantsController(participants));
    }
  }

  final List<ParticipantModel> participants;

  // Helper function to extract numeric value from the string
  num extractNumeric(String value) {
    final numericString = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return num.tryParse(numericString) ?? 0; // Convert to numeric value
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<ParticipantsController>();
    var screenWidth = (Get.mediaQuery.size.width - 500) / (1180.1 - 500);
    if (screenWidth < 0.1) {
      screenWidth = 0.1;
    }

    return Obx(() {
      return Theme(
        data: theme.copyWith(
          iconTheme: theme.iconTheme.copyWith(color: Colors.black),
        ),
        child: DataTable(
          sortAscending: controller.sortAscending.value,
          sortColumnIndex: controller.sortColumnIndex.value,
          dividerThickness: 0,
          dataRowMinHeight: 22,
          dataRowMaxHeight: 22,
          columnSpacing: 0,
          columns: [
            DataColumn(
              label: const Text(
                'Name',
                textAlign: TextAlign.left,
              ),
              onSort: controller.sortTable,
            ),
            DataColumn(
              label: const Text(
                'Runs',
              ),
              numeric: true,
              onSort: controller.sortTable,
            ),
            DataColumn(
              label: const Text(
                'Haring',
              ),
              numeric: true,
              onSort: controller.sortTable,
            ),
            DataColumn(
              label: const Text(
                'Fee',
                textAlign: TextAlign.left,
              ),
              numeric: true,
              onSort: controller.sortTable,
            ),
            DataColumn(
              label: const Text(
                'Paid',
                textAlign: TextAlign.left,
              ),
              numeric: true,
              onSort: controller.sortTable,
            ),
            DataColumn(
              label: const Text(
                'Credit',
                textAlign: TextAlign.left,
              ),
              numeric: true,
              onSort: controller.sortTable,
            ),
          ],
          rows: controller.filteredParticipants.map((participant) {
            Color creditTextColor;

            if (extractNumeric(participant.amountOwedStr) >
                extractNumeric(participant.amountPaidStr)) {
              creditTextColor = Colors.red.shade800;
            } else if (extractNumeric(participant.amountOwedStr) <
                extractNumeric(participant.amountPaidStr)) {
              creditTextColor = Colors.green.shade800;
            } else {
              creditTextColor = Colors.black;
            }

            // Determine text color based on hasher type
            Color textColor;
            switch (participant.virginVisitorType) {
              case 0: // Member
                textColor = Colors.black;

              case 1: // Visitor
                textColor = Colors.blue.shade800;

              case 2: // Virgin
                textColor = Colors.green.shade800;

              default:
                textColor = Colors.black;
            }

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: screenWidth * 200,
                    child: Text(
                      participant.displayName +
                          ((participant.virginVisitorType == 1)
                              ? ' (visitor)'
                              : (participant.virginVisitorType == 2)
                                  ? ' (virgin)'
                                  : ''),
                      style: mediumTextBlack.copyWith(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: screenWidth * 60,
                    child: Text(
                      participant.totalRunsThisKennel.toString(),
                      style: mediumTextBlack.copyWith(color: textColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: screenWidth * 60,
                    child: Text(
                      participant.totalHaringThisKennel.toString(),
                      style: mediumTextBlack.copyWith(color: textColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: screenWidth * 100,
                    child: Text(
                      participant.amountOwedStr,
                      style: mediumTextBlack.copyWith(color: creditTextColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: screenWidth * 100,
                    child: Text(
                      participant.amountPaidStr,
                      style: mediumTextBlack.copyWith(color: creditTextColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: screenWidth * 100,
                    child: Text(
                      participant.creditAvailableStr,
                      style: mediumTextBlack.copyWith(color: creditTextColor),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    });
  }
}
