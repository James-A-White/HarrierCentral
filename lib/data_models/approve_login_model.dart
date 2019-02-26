import 'dart:convert';
import 'dart:core';


class ApproveLoginModel {

  // int isRsvped;

    String apiVersion;
    DateTime lastGazetteerUpdate;
    num approvalCode;
    DateTime systemEstimatedBackInService;


  ApproveLoginModel(
    {
      // this.isRsvped,
      this.apiVersion,
      this.lastGazetteerUpdate,
      this.approvalCode,
      this.systemEstimatedBackInService,
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
          systemEstimatedBackInService:DateTime.parse(jsonItem['systemEstimatedBackInService'] ?? '2000-01-01 19:00:00'),
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