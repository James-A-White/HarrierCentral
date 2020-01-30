import 'dart:convert';
import 'dart:core';


class ApproveLoginModel {

   ApproveLoginModel(
    {
      this.apiVersion,
      this.approvalCode,
      this.loginMessage,
      this.loginMessageTitle,
      this.serverStatusCode,
      this.messageEndDate,
      this.messageDisplayType,
      this.iosDownloadLink,
      this.androidDownloadLink,
      this.imageRootUrl
    });

    String apiVersion;
    int approvalCode;
    String loginMessage;
    String loginMessageTitle;
    int serverStatusCode;
    DateTime messageEndDate;
    int messageDisplayType;
    String iosDownloadLink;
    String androidDownloadLink;
    String imageRootUrl;

  static ApproveLoginModel itemFromJson(String jsonResult)
  {
    final List<ApproveLoginModel> items = <ApproveLoginModel>[];

    ApproveLoginModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = ApproveLoginModel(
          // isRsvped: jsonItem['isRsvped'],
          apiVersion: jsonItem['apiVersion'],
          approvalCode: jsonItem['approvalCode'],
          serverStatusCode: jsonItem['serverStatusCode'],
          loginMessage: jsonItem['loginMessage'],
          loginMessageTitle: jsonItem['loginMessageTitle'],
          messageEndDate:DateTime.parse(jsonItem['serverStatusEndDate'] ?? '2000-01-01 19:00:00'),
          messageDisplayType: jsonItem['messageDisplayType'],
          iosDownloadLink: jsonItem['iosDownloadLink'],
          androidDownloadLink: jsonItem['androidDownloadLink'],
          imageRootUrl: jsonItem['imageRootUrl']
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