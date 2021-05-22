import 'package:harrier_central/imports.dart';

class DbErrorModel {
  DbErrorModel({
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

  static DbErrorModel itemFromJson(String jsonResult) {
    final List<DbErrorModel> items = <DbErrorModel>[];

    DbErrorModel item;

    // for queries that return multiple result sets
    // we need to unpack the inner Error object
    if (jsonResult.startsWith('[[')) {
      jsonResult = jsonResult.substring(1);
      jsonResult = jsonResult.substring(0, jsonResult.length - 1);
    }

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = DbErrorModel(
          // isRsvped: jsonItem['isRsvped'],
          errorId: jsonItem['errorId'].toString(),
          errorType: jsonItem['errorType'],
          errorTitle: jsonItem['errorTitle'],
          errorUserMessage: jsonItem['errorUserMessage'],
          debugMessage: jsonItem['debugMessage'],
          errorProc: jsonItem['errorProc'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items[0];
  }
}
