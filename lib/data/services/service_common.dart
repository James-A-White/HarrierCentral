import 'package:harrier_central/imports.dart';

//int httpCounter = 1000;

class ServiceCommon {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  static Future<void> recordError(
    String httpBody,
    String error, {
    String? extraData,
  }) async {
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';

    final String body = jsonEncode(<String, String>{
      'queryType': 'logAppError',
      'deviceId': deviceId,
      'accessToken': '<not required>',
      'httpBody': httpBody,
      'errorText': error,
      'extraData': extraData ?? '',
    });

    await post(
      Uri.parse(BASE_AF_API_URL),
      headers: <String, String>{'content-type': 'application/json'},
      body: body,
    ).catchError((dynamic error) {
      return Future<Response>.value(Response('', 500)); // CHECK
    });

    return;
  }

  static Future<String> sendHttpPostV2(
    String requestBody, {
    Function? errorCallback,
    Client? client,
    bool bypassConnectionCheck = false,
  }) async {
    // if the connection check is bypassed, it is because we are doing an initial
    // connection check
    if ((!bypassConnectionCheck) &&
        appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
      // if we were previously not connected, let's check the connection
      // and update the connection status
      await Utilities.checkForInternetConnection(
        false,
        performHcServerCheck: false,
      );
      // if we are still not connected, return an error
      if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
        return ERROR_NO_CONNECTION;
      }
    }

    // print('>>> http post $httpCounter $requestBody');
    // httpCounter++;

    Response response;

    if (client == null) {
      response = await post(
        Uri.parse(BASE_AF_API_URL),
        headers: <String, String>{'content-type': 'application/json'},
        body: requestBody,
      ).catchError((dynamic error) {
        recordError(requestBody, error.toString());
        return Future<Response>.value(Response('', 500)); // CHECK
      });
    } else {
      response = await client
          .post(
            Uri.parse(BASE_AF_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: requestBody,
          )
          .catchError((dynamic error) {
            recordError(requestBody, error.toString());
            return Future<Response>.value(Response('', 500)); // CHECK
          });
    }

    String returnValue = await checkHttpPostResponse(
      response,
      requestBody,
      errorCallback: errorCallback,
    );

    return returnValue;
  }

  // static Future<String> sendHttpPost(
  //   String procName,
  //   String requestBody, {
  //   Function? errorCallback,
  //   Client? client,
  // }) async {
  //   if (appModel.connectionStatus == EnumConnectionStatus2.notConnected) {
  //     return ERROR_NO_CONNECTION;
  //   }

  //   print('>>> http post $httpCounter $procName');
  //   httpCounter++;

  //   Response response;

  //   if (client == null) {
  //     response = await post(Uri.parse(BASE_API_URL + procName),
  //             headers: <String, String>{'content-type': 'application/json'},
  //             body: requestBody)
  //         .catchError(
  //       (dynamic error) {
  //         return Future<Response>.value(Response('', 500)); // CHECK
  //       },
  //     );
  //   } else {
  //     response = await client
  //         .post(Uri.parse(BASE_API_URL + procName),
  //             headers: <String, String>{'content-type': 'application/json'},
  //             body: requestBody)
  //         .catchError(
  //       (dynamic error) {
  //         return Future<Response>.value(Response('', 500)); // CHECK
  //       },
  //     );
  //   }

  //   String returnValue =
  //       await checkHttpPostResponse(response, errorCallback: errorCallback);

  //   return returnValue;
  // }

  static Future<String> checkHttpPostResponse(
    Response response,
    String requestBody, {
    Function? errorCallback,
  }) async {
    String returnValue = ERROR_UNKNOWN_HTTP_ERROR;

    if ((response.statusCode < 200) || (response.statusCode >= 300)) {
      if (response.reasonPhrase == 'Site Disabled') {
        await Utilities.showAlert(
          'Down for Maintenance',
          'The Harrier Central server is temporarily offline for maintenance.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.',
          'Use Offline',
        );
        recordError(
          requestBody,
          response.reasonPhrase ?? '<null reason>',
          extraData: response.body,
        );
        appModel.connectionStatus = EnumConnectionStatus2.notConnected;
      } else {
        // bypass the Harrier Central backend server check and
        // check the internet connection using other services.
        // This is done to prevent an infinite loop
        await Utilities.checkForInternetConnection(
          false,
          performHcServerCheck: false,
        );
        if (appModel.connectionStatus == EnumConnectionStatus2.connected) {
          recordError(
            requestBody,
            response.reasonPhrase ?? '<null reason>',
            extraData: response.body,
          );

          Get.closeAllSnackbars();

          Get.showSnackbar(
            GetSnackBar(
              title: 'Unknown Server Error',
              message: response.reasonPhrase ?? ' - ${response.body}',
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.blue,
            ),
          );
        }
        // await Utilities.showAlert(
        //     'Unknown Server Error',
        //     'The Harrier Central server is experiencing an unknown server error. Please send this screenshot to us at harriercentral@gmail.com so we can attempt to resolve the issue.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.\r\n\r\nServer Error Code = ${response.statusCode.toString()}',
        //     'Use Offline');
        // appModel.connectionStatus = EnumConnectionStatus2.notConnected;
      }
    } else if (response.body.contains('"errorId"')) {
      recordError(
        requestBody,
        response.reasonPhrase ?? '<null reason>',
        extraData: response.body,
      );
      returnValue = ERROR_UNKNOWN_REMOTE_DB_ERROR;
      final DbErrorModel errorResult = DbErrorModel.fromJson(
        json.decode(response.body)[0][0],
      );

      if (errorCallback != null) {
        final bool errorCallbackResult = await errorCallback(errorResult);
        returnValue = errorCallbackResult ? ERROR_HANDLED : ERROR_NOT_HANDLED;
      } else {
        final bool alertResult =
            (await Utilities.showAlert(
              errorResult.errorTitle ?? '',
              (errorResult.errorUserMessage ?? '').replaceAll('~', '\r\n'),
              'Quit',
            )) ??
            false; // CHECK

        returnValue =
            alertResult
                ? ERROR_KEY_OK_BTN_PRESSED
                : ERROR_KEY_CANCEL_BTN_PRESSED;
      }
    } else {
      returnValue = response.body;
    }

    return returnValue;
  }
}
