
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';

import 'package:harrier_central/localization.dart';

import 'package:intl/intl.dart';

class Utilities
{

    static String generateToken(String userId, String procName)
    {
         final Duration difference = DateTime.now().toUtc().difference(DateTime.utc(1993,7,25,15,0,0));
         //final int timeBlocks = (difference.inSeconds / 5760).toInt();
         final int timeBlocks = difference.inSeconds ~/ 5760;
         final String accessString = '${userId.toUpperCase()}#$procName#${timeBlocks.toString()}';
         final List<int> bytes = utf8.encode(accessString); // data being hashed
         final Digest digest = sha256.convert(bytes);
         return '$digest'.toUpperCase();
    }

    static String getFormattedMoney(num amount, num decimalPlaces, String currencySymbol) {
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

    String finalStr =
        currencySymbol.replaceAll('^', amountStr);

    return finalStr;
  }

    static String getDistance(int meters, BuildContext context)
    {
      const bool isMetric = true;
      String result = '';

       if(isMetric)
       {
          if (meters < 1000)
          {
              result = '$meters ${AppLocalizations.of(context).meters}';
          } else if (meters < 10000) {
              result = '${NumberFormat('#####.0').format(meters/1000.0)} ${AppLocalizations.of(context).kilometers}';
          } else {
              result = '${NumberFormat('#####').format(meters/1000.0)} ${AppLocalizations.of(context).kilometers}';
          }

       } else {
          final double miles = meters * 0.0006;

          if (miles < 3)
          {
              result = '${NumberFormat('#####.00').format(miles)} ${AppLocalizations.of(context).miles}';
          } else if (miles < 10) {
              result = '${NumberFormat('#####.0').format(miles)} ${AppLocalizations.of(context).miles}';
          } else {
              result = '${NumberFormat('#####').format(miles)} ${AppLocalizations.of(context).miles}';
          }
       }

       return result;
    }
}