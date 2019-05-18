import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:harrier_central/localization.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:harrier_central/util/enums.dart';

class LatLon {
  double latitude;
  double longitude;
}

class Utilities {
  static Future<LatLon> getLatLong() async {
    Position position;

    PermissionStatus _locationPermission;

    _locationPermission ??= await PermissionHandler().checkPermissionStatus(PermissionGroup.location);

    if (_locationPermission == PermissionStatus.granted) {
      position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    }

    final LatLon latLon = LatLon();

    latLon.latitude = DEFAULT_LATITUDE;
    latLon.longitude = DEFAULT_LONGITUDE;

    if (position != null) {
      latLon.latitude = position.latitude;
      latLon.longitude = position.longitude;
      setDoublePref(DoublePrefsEnum.latitude, latLon.latitude);
      setDoublePref(DoublePrefsEnum.longitude, latLon.longitude);
    } else {
      latLon.latitude = getDoublePref(DoublePrefsEnum.latitude);
      latLon.longitude = getDoublePref(DoublePrefsEnum.longitude);
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

  static String getDistance(int meters, BuildContext context) {
    const bool isMetric = true;
    String result = '';

    if (isMetric) {
      if (meters < 1000) {
        result = '$meters ${AppLocalizations.of(context).meters}';
      } else if (meters < 10000) {
        result = '${NumberFormat('#####.0').format(meters / 1000.0)} ${AppLocalizations.of(context).kilometers}';
      } else {
        result = '${NumberFormat('#####').format(meters / 1000.0)} ${AppLocalizations.of(context).kilometers}';
      }
    } else {
      final double miles = meters * 0.0006;

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

  static Widget styleForConnected(Widget w) {
  return Container(
    foregroundDecoration: globalConnectionStatus == connectionStatus_connected
        ? const BoxDecoration()
        : const BoxDecoration(
            color: Colors.grey,
            backgroundBlendMode: BlendMode.saturation,
          ),
    child: Opacity(opacity: globalConnectionStatus == connectionStatus_connected ? 1.0 : 0.5, child: w),
  );
}

static bool checkForConnection(BuildContext context,{String title, String message})
{
  if (globalConnectionStatus ==connectionStatus_notConnected)
  {
     Utilities.showAlert(context, title ?? 'Offline mode', message ?? 'This feature is not available in offline mode. Please connect to the internet to use this feature' , 'OK');
  }
  return globalConnectionStatus == connectionStatus_connected;
}

  static Future<bool> showAlert(BuildContext context, String title, String body, String buttonText) async {
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
