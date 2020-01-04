import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';

import 'package:harrier_central/localization.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';

class LatLon {
  num latitude;
  num longitude;
}

class Utilities {
  static const int qrScanTypeFlag_user = 0x00000001;
  static const int qrScanTypeFlag_userSecretCode = 0x00000002;
  static const int qrScanTypeFlag_runStart = 0x00000004;
  static const int qrScanTypeFlag_runEnd = 0x00000008;
  static const int qrScanTypeFlag_kennelRunStart = 0x00000010;
  static const int qrScanTypeFlag_kennelRunEnd = 0x00000020;
  static const int qrScanTypeFlag_resetCode = 0x00000040;

  static Map<String, String> validateScan(String scanText, int allowedScanTypes) {
    Map<String, String> result;

    final int colonOffset = scanText.indexOf(':');
    if (colonOffset != 3) {
      result = <String, String>{'validScan': false.toString(), 'prefix': '', 'content': ''};
    } else {
      final String prefix = scanText.substring(0, colonOffset + 1);
      final String content = scanText.substring(4);

      int scanType = 0;
      bool validHcQr = true;

      switch (prefix.toUpperCase()) {
        case QR_PREFIX_USER_CODE:
          scanType = qrScanTypeFlag_user;
          break;
        case QR_PREFIX_USER_SECRET_CODE:
          scanType = qrScanTypeFlag_userSecretCode;
          break;
        case QR_PREFIX_USER_RESET_CODE:
          scanType = qrScanTypeFlag_resetCode;
          break;
        case QR_PREFIX_SPECIFIC_RUN_START:
          scanType = qrScanTypeFlag_runStart;
          break;
        case QR_PREFIX_SPECIFIC_RUN_END:
          scanType = qrScanTypeFlag_runEnd;
          break;
        case QR_PREFIX_KENNEL_GENERIC_RUN_START:
          scanType = qrScanTypeFlag_kennelRunStart;
          break;
        case QR_PREFIX_KENNEL_GENERIC_RUN_END:
          scanType = qrScanTypeFlag_kennelRunEnd;
          break;
        default:
          validHcQr = false;
          break;
      }

      final bool scanAllowed = (scanType & allowedScanTypes) != 0;

      result = <String, String>{'validScan': scanAllowed.toString(), 'prefix': prefix, 'content': content, 'validHcQr': validHcQr.toString()};
    }

    return result;
  }

  static Future<LatLon> getLatLong() async {
    Position position;

    final GeolocationStatus status = await Geolocator().checkGeolocationPermissionStatus(locationPermission: GeolocationPermission.location);

    if (status == GeolocationStatus.granted) {
      position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    }

    final LatLon latLon = LatLon();

    latLon.latitude = DEFAULT_LATITUDE;
    latLon.longitude = DEFAULT_LONGITUDE;

    if (position != null) {
      latLon.latitude = position.latitude;
      latLon.longitude = position.longitude;
      setNumPref(NumPrefsEnum.latitude, latLon.latitude);
      setNumPref(NumPrefsEnum.longitude, latLon.longitude);
    } else {
      latLon.latitude = getNumPref(NumPrefsEnum.latitude) ?? DEFAULT_LATITUDE;
      latLon.longitude = getNumPref(NumPrefsEnum.longitude) ?? DEFAULT_LONGITUDE;
    }

    return latLon;
  }

  static String generateToken(String userId, String procName, {String paramString = ''}) {
    final Duration difference = DateTime.now().toUtc().difference(DateTime.utc(1993, 7, 25, 15, 0, 0));
    //final int timeBlocks = (difference.inSeconds / 5760).toInt();
    final int timeBlocks = difference.inSeconds ~/ 5760;
    if (paramString.isNotEmpty) {
      paramString = '#' + paramString;
    }
    final String accessString = '${userId.toUpperCase()}#$procName#${timeBlocks.toString()}$paramString';
    final List<int> bytes = utf8.encode(accessString); // data being hashed
    final Digest digest = sha256.convert(bytes);
    return '$digest'.toUpperCase();
  }

  static String getFormattedMoney(num amount, num decimalPlaces, String currencySymbol) {
    String finalStr = '';
    if (amount != null) {
      String formatDecimals = '#####0.00';
      switch (decimalPlaces) {
        case 0:
          formatDecimals = '#####0';
          break;
        case 1:
          formatDecimals = '#####0.0';
          break;
        case 2:
          formatDecimals = '#####0.00';
          break;
        case 3:
          formatDecimals = '#####0.000';
          break;
        case 4:
          formatDecimals = '#####0.0000';
          break;
        default:
          formatDecimals = '#####0.00';
          break;
      }

      final String amountStr = NumberFormat(formatDecimals).format(amount);

      finalStr = currencySymbol.replaceAll('^', amountStr);
    }

    return finalStr;
  }

  static String getDistance(num meters, BuildContext context,{bool isMetric = true}) {
    String result = '';

    if (isMetric) {
      if (meters < 1000) {
        result = '${NumberFormat('####').format(meters)} ${AppLocalizations.of(context).meters}';
      } else if (meters < 10000) {
        result = '${NumberFormat('#####.0').format(meters / 1000.0)} ${AppLocalizations.of(context).kilometers}';
      } else {
        result = '${NumberFormat('#####').format(meters / 1000.0)} ${AppLocalizations.of(context).kilometers}';
      }
    } else {
      final num miles = meters * METERS_TO_MILES;

      if (miles < 3) {
        result = '${NumberFormat('#####.00').format(miles)} ${AppLocalizations.of(context).miles}';
      } else if (miles < 10) {
        result = '${NumberFormat('#####.0').format(miles)} ${AppLocalizations.of(context).miles}';
      } else {
        result = '${NumberFormat('#####').format(miles)} ${AppLocalizations.of(context).miles}';
      }
    }

    return result;
  }

  static Widget elegantDivider(String text, num topPadding, num bottomPadding) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white10,
                    Colors.white,
                  ],
                  begin: FractionalOffset(0.0, 0.0),
                  end: FractionalOffset(1.0, 1.0),
                  stops: <double>[0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
            width: 100.0,
            height: 1.0,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16.0, fontFamily: 'WorkSansMedium'),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white,
                    Colors.white10,
                  ],
                  begin: FractionalOffset(0.0, 0.0),
                  end: FractionalOffset(1.0, 1.0),
                  stops: <double>[0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
            width: 100.0,
            height: 1.0,
          ),
        ],
      ),
    );
  }

  static void showInSnackBar(BuildContext context, GlobalKey<ScaffoldState> scaffoldKey, String value, {int durationInSeconds = 3}) {
    FocusScope.of(context).requestFocus(FocusNode());
    scaffoldKey.currentState?.removeCurrentSnackBar();
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16.0, fontFamily: 'WorkSansSemiBold'),
      ),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: durationInSeconds),
    ));
  }

  static Widget styleForConnected(Widget w, {num borderRadius = 0.0}) {
    return Container(
      foregroundDecoration: globalConnectionStatus == connectionStatus_connected
          ? const BoxDecoration()
          : BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.grey,
              backgroundBlendMode: BlendMode.lighten,
            ),
      child: Container(
        foregroundDecoration: globalConnectionStatus == connectionStatus_connected
            ? const BoxDecoration()
            : const BoxDecoration(
                color: Colors.grey,
                backgroundBlendMode: BlendMode.saturation,
              ),
        child: w,
      ),
    );
  }

  static Widget styleForDisabled(Widget w, {num borderRadius = 0.0}) {
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.grey,
        backgroundBlendMode: BlendMode.lighten,
      ),
      child: Container(
        foregroundDecoration: const BoxDecoration(
          color: Colors.grey,
          backgroundBlendMode: BlendMode.saturation,
        ),
        child: w,
      ),
    );
  }

  static bool checkForConnection(BuildContext context, {String title, String message}) {
    if (globalConnectionStatus == connectionStatus_notConnected) {
      Utilities.showAlert(context, title ?? 'Offline mode', message ?? 'This feature is not available in offline mode. Please connect to the internet to use this feature', 'OK');
    }
    return globalConnectionStatus == connectionStatus_connected;
  }

  static Future<bool> showAlert(BuildContext context, String title, String body, String buttonText, {bool showCancelButton = false, String cancelButtonText = 'Cancel'}) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  body,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontFamily: 'AvenirNextRegular', fontStyle: FontStyle.normal, fontSize: 16.0, height: 1.0),
                )
              ],
            ),
          ),
          actions: <Widget>[
            showCancelButton == true
                ? FlatButton(
                    child: Text(cancelButtonText),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  )
                : Container(),
            FlatButton(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
