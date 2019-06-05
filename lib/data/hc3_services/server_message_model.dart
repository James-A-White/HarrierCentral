
import 'dart:convert';

class ServerMessageModel {
  ServerMessageModel({this.messageId,this.messageText,this.messageDisplayType,this.messageDuration,this.dialogButtonText,this.dialogTitle});

  final int messageId;
  final String messageText;
  final int messageDisplayType;
  final int messageDuration;
  final String dialogButtonText;
  final String dialogTitle;


  static List<ServerMessageModel> itemsFromJson(String jsonResult) {
    final List<ServerMessageModel> items = <ServerMessageModel>[];

    ServerMessageModel item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = ServerMessageModel(
            messageId: jsonItem['messageId'],
            messageText: jsonItem['messageText'],
            messageDisplayType: jsonItem['messageDisplayType'],
            messageDuration: jsonItem['messageDuration'],
            dialogButtonText: jsonItem['dialogButtonText'],
            dialogTitle: jsonItem['dialogTitle']);

        items.add(item);
      },
    );

    if (items.isEmpty) {
      return null;
    }

    return items;
  }
}


