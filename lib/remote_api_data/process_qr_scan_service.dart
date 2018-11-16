import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:harrier_central/util/utilities.dart';

import 'package:harrier_central/data_models/process_qr_scan_model.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/util/preferences.dart';

//import 'package:geolocator/geolocator.dart';

class ProcessQrScanService {

  Future<ProcessQrScanModel> processQrScan(String eventId, String scanText, String context1,
      String context2, String param1, String param2) async {

    final String userId = Preferences.getStringPref(StringPrefsEnum.userId);

    final String accessToken =
        Utilities.generateToken(userId.toUpperCase(), 'processQrScan');

    final String body = jsonEncode(<String,String>{
      'userId': userId,
      'accessToken': accessToken,
      'eventId': eventId,
      'scanText': scanText,
      'context1': context1,
      'context2': context2,
      'param1': param1,
      'param2': param2
    });

    final http.Response response = await http
        .post(BASE_API_URL + 'process_qr_scan_2',
            headers: <String,String> {'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return false;
      },
    );

    ProcessQrScanModel item;

    json.decode(response.body).forEach(
      (dynamic user) {
        item = ProcessQrScanModel(
          resultStr1: user['resultStr1'],
          resultStr2: user['resultStr2'],
          resultStr3: user['resultStr3'],
          resultGuid1: user['resultGuid1'],
          resultGuid2: user['resultGuid2'],
          resultInt1: user['resultInt1'],
          resultInt2: user['resultInt2'],
          resultInt3: user['resultInt3'],
          resultInt4: user['resultInt4'],
          resultDecimal1: user['resultDecimal1'] * 1.0,
          resultDecimal2: user['resultDecimal2'] * 1.0,
        );
      },
    );

    return item;
  }
}
