import 'package:harrier_central/imports.dart';

int httpCounter = 1000;

class ServiceCommon {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  static Future<String> sendHttpPostV2(
    String requestBody, {
    Function? errorCallback,
    Client? client,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return ERROR_NO_CONNECTION;
    }

    //print('>>> http post $httpCounter $procName');
    //httpCounter++;

    Response response;

    if (client == null) {
      response = await post(Uri.parse(BASE_AF_API_URL),
              headers: <String, String>{'content-type': 'application/json'},
              body: requestBody)
          .catchError(
        (dynamic error) {
          return Future<Response>.value(Response('', 500)); // CHECK
        },
      );
    } else {
      response = await client
          .post(Uri.parse(BASE_AF_API_URL),
              headers: <String, String>{'content-type': 'application/json'},
              body: requestBody)
          .catchError(
        (dynamic error) {
          return Future<Response>.value(Response('', 500)); // CHECK
        },
      );
    }

    String returnValue =
        await checkHttpPostResponse(response, errorCallback: errorCallback);

    return returnValue;
  }

  static Future<String> sendHttpPost(
    String procName,
    String requestBody, {
    Function? errorCallback,
    Client? client,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return ERROR_NO_CONNECTION;
    }

    print('>>> http post $httpCounter $procName');
    httpCounter++;

    Response response;

    if (client == null) {
      response = await post(Uri.parse(BASE_API_URL + procName),
              headers: <String, String>{'content-type': 'application/json'},
              body: requestBody)
          .catchError(
        (dynamic error) {
          return Future<Response>.value(Response('', 500)); // CHECK
        },
      );
    } else {
      response = await client
          .post(Uri.parse(BASE_API_URL + procName),
              headers: <String, String>{'content-type': 'application/json'},
              body: requestBody)
          .catchError(
        (dynamic error) {
          return Future<Response>.value(Response('', 500)); // CHECK
        },
      );
    }

    String returnValue =
        await checkHttpPostResponse(response, errorCallback: errorCallback);

    return returnValue;
  }

  static Future<String> checkHttpPostResponse(Response response,
      {Function? errorCallback}) async {
    String returnValue = ERROR_UNKNOWN_HTTP_ERROR;

    if ((response.statusCode < 200) || (response.statusCode >= 300)) {
      if (response.reasonPhrase == 'Site Disabled') {
        await Utilities.showAlert(
            'Down for Maintenance',
            'The Harrier Central server is temporarily offline for maintenance.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.',
            'Use Offline');
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
      } else {
        await Utilities.showAlert(
            'Unknown Server Error',
            'The Harrier Central server is experiencing an unknown server error. Please send this screenshot to us at connect@harriercentral.com so we can attempt to resolve the issue.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.\r\n\r\nServer Error Code = ${response.statusCode.toString()}',
            'Use Offline');
        G0<AppModel>().connectionStatus = EnumConnectionStatus2.notConnected;
      }
    } else if (response.body.contains('"errorId"')) {
      returnValue = ERROR_UNKNOWN_REMOTE_DB_ERROR;
      final DbErrorModel errorResult =
          DbErrorModel.fromJson(json.decode(response.body)[0][0]);

      if (errorCallback != null) {
        final bool errorCallbackResult = await errorCallback(errorResult);
        returnValue = errorCallbackResult ? ERROR_HANDLED : ERROR_NOT_HANDLED;
      } else {
        final bool alertResult = (await Utilities.showAlert(
              errorResult.errorTitle ?? '',
              (errorResult.errorUserMessage ?? '').replaceAll('~', '\r\n'),
              'Quit',
            )) ??
            false; // CHECK

        returnValue = alertResult
            ? ERROR_KEY_OK_BTN_PRESSED
            : ERROR_KEY_CANCEL_BTN_PRESSED;
      }
    } else {
      returnValue = response.body;
    }

    return returnValue;
  }
}
