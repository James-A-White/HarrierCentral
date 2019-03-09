import 'dart:convert';
import 'dart:core';


class ApproveLoginModel {

  // int isRsvped;

    String apiVersion;
    DateTime lastGazetteerUpdate;
    int approvalCode;
    String loginMessage;
    String loginMessageTitle;
    int serverStatusCode;
    DateTime messageEndDate;
    int messageDisplayType;

  ApproveLoginModel(
    {
      this.apiVersion,
      this.lastGazetteerUpdate,
      this.approvalCode,
      this.loginMessage,
      this.loginMessageTitle,
      this.serverStatusCode,
      this.messageEndDate,
      this.messageDisplayType
    });

  static ApproveLoginModel itemFromJson(String jsonResult)
  {
    List<ApproveLoginModel> items = List<ApproveLoginModel>();

    ApproveLoginModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = ApproveLoginModel(
          // isRsvped: jsonItem['isRsvped'],
          apiVersion: jsonItem['apiVersion'],
          lastGazetteerUpdate:DateTime.parse(jsonItem['lastGazetteerUpdate'] ?? '2000-01-01 19:00:00'),
          approvalCode: jsonItem['approvalCode'],
          serverStatusCode: jsonItem['serverStatusCode'],
          loginMessage: jsonItem['loginMessage'],
          loginMessageTitle: jsonItem['loginMessageTitle'],
          messageEndDate:DateTime.parse(jsonItem['serverStatusEndDate'] ?? '2000-01-01 19:00:00'),
          messageDisplayType: jsonItem['messageDisplayType'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty)
    {
      return null;
    }

    return items[0];
  }

}