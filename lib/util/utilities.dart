import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';

import 'package:ive_flutter_core/util/core_utilities.dart';

import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/globals.dart';
import 'package:ive_flutter_core/util/connection.dart';

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

  static int logCounter = 0;


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

  static Future<void> subscribeToGeoLocationStream() async {
    deviceLat = DEFAULT_LATITUDE;
    deviceLon = DEFAULT_LONGITUDE;

    final Geolocator geolocator = Geolocator();

    CoreUtilities.logTiming('Geostatus query start',appStartTime);
    final GeolocationStatus status = await Geolocator().checkGeolocationPermissionStatus(locationPermission: GeolocationPermission.location);

    CoreUtilities.logTiming('Geolocation query start',appStartTime);
    if (status == GeolocationStatus.granted) {
      final LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 50);
      geoLocationStream = geolocator.getPositionStream(locationOptions).listen((Position position) {
        if (position != null) {
          deviceLat = position.latitude;
          deviceLon = position.longitude;
        }
        print('>>>>>>>>>>> geoloc update' + (position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString()));
      });

      final Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      deviceLat = position.latitude;
      deviceLon = position.longitude;
    }
  }

  static String getDistance(num meters, BuildContext context, {bool isMetric = true}) {
    if (!hasLocationPermissions) {
      return '';
    }

    String result = '';

    if (isMetric) {
      if (meters < 1000) {
        result = '${NumberFormat('####').format(meters)} meters';
      } else if (meters < 10000) {
        result = '${NumberFormat('#####.0').format(meters / 1000.0)} km';
      } else {
        result = '${NumberFormat('#####').format(meters / 1000.0)} km';
      }
    } else {
      final num miles = meters * METERS_TO_MILES;

      if (miles < 3) {
        result = '${NumberFormat('#####.00').format(miles)} miles';
      } else if (miles < 10) {
        result = '${NumberFormat('#####.0').format(miles)} miles';
      } else {
        result = '${NumberFormat('#####').format(miles)} miles';
      }
    }

    return result;
  }
}
