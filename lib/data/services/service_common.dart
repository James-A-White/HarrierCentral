import 'package:harrier_central/imports.dart';

class ServiceCommon {
  static Future<String> sendRequest(
      BuildContext context, String procName, String requestBody) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final Response response = await post(BASE_API_URL + procName,
            headers: <String, String>{'content-type': 'application/json'},
            body: requestBody
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return ERROR_KEY;
      },
    );

    if (response.body.contains('"errorId"')) {
      final DbErrorModel result = DbErrorModel.itemFromJson(response.body);
      if (result != null) {
        await IveCoreUtilities.showAlert(
            context, result.errorTitle, result.errorUserMessage, 'OK');
      }

      return ERROR_KEY;
    }

    return response.body;
  }
}
