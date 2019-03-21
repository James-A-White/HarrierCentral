import 'dart:convert';
import 'dart:core';


class DbErrorModel {

   DbErrorModel(
    {
      this.errorId,
      this.errorType,
      this.errorTitle,
      this.errorUserMessage,
      this.debugMessage,
      this.errorProc,
    });

    final String errorId;
    final num errorType;
    final String errorTitle;
    final String errorUserMessage;
    final String debugMessage;
    final String errorProc;


  static DbErrorModel itemFromJson(String jsonResult)
  {
    final List<DbErrorModel> items = <DbErrorModel>[];

    DbErrorModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = DbErrorModel(
          // isRsvped: jsonItem['isRsvped'],
          errorId: jsonItem['errorId'],
          errorType: jsonItem['errorType'],
          errorTitle: jsonItem['errorTitle'],
          errorUserMessage: jsonItem['errorUserMessage'],
          debugMessage: jsonItem['debugMessage'],
          errorProc: jsonItem['errorProc'],
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