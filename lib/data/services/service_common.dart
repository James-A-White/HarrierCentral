import 'package:harrier_central/imports.dart';

class ServiceCommon {
  static Future<String> sendHttpPost(String procName, String requestBody, {Function errorCallback}) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return ERROR_NO_CONNECTION;
    }

    final Response response = await post(BASE_API_URL + procName, headers: <String, String>{'content-type': 'application/json'}, body: requestBody).catchError(
      (dynamic error) {
        return Future<Response>.value(null);
      },
    );

    String returnValue = '';

    if (response == null) {
      returnValue = ERROR_UNKNOWN_HTTP_ERROR;
    } else if ((response.statusCode < 200) || (response.statusCode >= 300)) {
      returnValue = ERROR_UNKNOWN_HTTP_ERROR;
    } else {
      if (response.body.contains('"errorId"')) {
        returnValue = ERROR_UNKNOWN_REMOTE_DB_ERROR;
        final DbErrorModel errorResult = DbErrorModel.itemFromJson(response.body);
        if (errorResult != null) {
          if (errorCallback != null) {
            final bool errorCallbackResult = await errorCallback(errorResult);
            returnValue = errorCallbackResult ? ERROR_HANDLED : ERROR_NOT_HANDLED;
          } else {
            final bool alertResult = await IveCoreUtilities.showAlert(navigatorKey.currentContext, errorResult.errorTitle, errorResult.errorUserMessage, 'OK');

            returnValue = alertResult ? ERROR_KEY_OK_BTN_PRESSED : ERROR_KEY_CANCEL_BTN_PRESSED;
          }
        }
      } else {
        returnValue = response.body;
      }
    }

    return returnValue;
  }
}
