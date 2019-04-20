
import 'dart:async';
import 'dart:convert';

import 'package:harrier_central/data/models/process_qr_scan_for_checkin_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/util/utilities.dart';

import 'package:http/http.dart' as http;

//import 'package:geolocator/geolocator.dart';

class ProcessQrScanForCheckinService {

  Future<ProcessQrScanForCheckinModel> processQrScan(String eventId, String scanText, int runStartOrEnd,
      int selfScan) async {

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'processQrScanForCheckin');

    final String body = jsonEncode(<String,String>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'scanText': scanText,
      'runStartOrEnd': runStartOrEnd.toString(),
      'selfScan': selfScan.toString()
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'process_qr_scan_for_checkin',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    ProcessQrScanForCheckinModel item;

    json.decode(response.body).forEach(
      (dynamic jsonResult) {
        item = ProcessQrScanForCheckinModel(
          result: jsonResult['result'],
          resultStr: jsonResult['resultStr'],
          currencySymbol: jsonResult['currencySymbol'],
          paymentInstructions: jsonResult['paymentInstructions'],
          scannedUserName: jsonResult['scannedUserName'],
          targetUserId: jsonResult['targetUserId'],
          hasherEventMapId: jsonResult['hasherEventMapId'],
          userRunCountThisKennel: jsonResult['userRunCountThisKennel'],
          isPaid: jsonResult['isPaid'],
          paymentType: jsonResult['paymentType'],
          isCreditAllowed: jsonResult['isCreditAllowed'],
          currencyDigitsAfterDecimal: jsonResult['currencyDigitsAfterDecimal'],
          runPriceThisUser: jsonResult['runPriceThisUser'] * 1.0,
          remainingCredit: jsonResult['remainingCredit'] * 1.0,
          photo: jsonResult['photo'],
          attendenceState: jsonResult['attendenceState'],
          rsvpState: jsonResult['rsvpState'],
          isMember: jsonResult['isMember'],
          isHare: jsonResult['isHare'],
          virginVisitorType: jsonResult['virginVisitorType'],
          userStartEvent: DateTime.parse(
              jsonResult['userStartEvent'] ?? '2000-01-01 19:00:00'),
          userEndEvent:
              DateTime.parse(jsonResult['userEndEvent'] ?? '2000-01-01 19:00:00'),
          isFollowing: jsonResult['isFollowing'],
          allowNegativeCredit: jsonResult['allowNegativeCredit']
          
        );
      },
    );

    return item;
  }
}




