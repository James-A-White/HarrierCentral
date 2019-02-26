import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';

import 'package:harrier_central/localization.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';

import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LatLon {
  double latitude;
  double longitude;
}

class Utilities {
  static Future<LatLon> getLatLong() async {
    Position position;

    PermissionStatus _location_permission;

    if (_location_permission == null) {
      _location_permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);
    }

    if (_location_permission == PermissionStatus.granted) {
      position = await Geolocator()
          .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    }

    LatLon latLon =LatLon();

    latLon.latitude = DEFAULT_LATITUDE;
    latLon.longitude = DEFAULT_LONGITUDE;

    if (position != null) {
      latLon.latitude = position.latitude;
      latLon.longitude = position.longitude;
      Preferences.setNumPref(NumPrefsEnum.latitude, latLon.latitude);
      Preferences.setNumPref(NumPrefsEnum.longitude, latLon.longitude);
    } else {
      latLon.latitude = Preferences.getNumPref(NumPrefsEnum.latitude);
      latLon.longitude = Preferences.getNumPref(NumPrefsEnum.longitude);
    }

    return latLon;
  }

  static String generateToken(String userId, String procName,
      {String paramString = ''}) {
    final Duration difference =
        DateTime.now().toUtc().difference(DateTime.utc(1993, 7, 25, 15, 0, 0));
    //final int timeBlocks = (difference.inSeconds / 5760).toInt();
    final int timeBlocks = difference.inSeconds ~/ 5760;
    if (paramString.isNotEmpty) {
      paramString = '#' + paramString;
    }
    final String accessString =
        '${userId.toUpperCase()}#$procName#${timeBlocks.toString()}$paramString';
    final List<int> bytes = utf8.encode(accessString); // data being hashed
    final Digest digest = sha256.convert(bytes);
    return '$digest'.toUpperCase();
  }

  static String getFormattedMoney(
      num amount, num decimalPlaces, String currencySymbol) {
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

    String amountStr = NumberFormat(formatDecimals).format(amount);

    String finalStr = currencySymbol.replaceAll('^', amountStr);

    return finalStr;
  }

  static String getDistance(int meters, BuildContext context) {
    const bool isMetric = true;
    String result = '';

    if (isMetric) {
      if (meters < 1000) {
        result = '$meters ${AppLocalizations.of(context).meters}';
      } else if (meters < 10000) {
        result =
            '${NumberFormat('#####.0').format(meters / 1000.0)} ${AppLocalizations.of(context).kilometers}';
      } else {
        result =
            '${NumberFormat('#####').format(meters / 1000.0)} ${AppLocalizations.of(context).kilometers}';
      }
    } else {
      final double miles = meters * 0.0006;

      if (miles < 3) {
        result =
            '${NumberFormat('#####.00').format(miles)} ${AppLocalizations.of(context).miles}';
      } else if (miles < 10) {
        result =
            '${NumberFormat('#####.0').format(miles)} ${AppLocalizations.of(context).miles}';
      } else {
        result =
            '${NumberFormat('#####').format(miles)} ${AppLocalizations.of(context).miles}';
      }
    }

    return result;
  }
}
