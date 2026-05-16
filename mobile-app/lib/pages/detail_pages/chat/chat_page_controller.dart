import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:harrier_central/imports.dart';

class ChatPageController extends GetxController {
  ChatPageController({required this.eventId, required this.publicEventId}) {
    // Initialize controllers with initial data if available
  }
  String eventId;
  String publicEventId;

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

  double visibility = 0.0;

  RxBool messagesLoading = true.obs;

  List<types.Message> messages = <types.Message>[];

  @override
  void onClose() {
    // No explicit resources to dispose here (messages is a plain List;
    // onAppResumed is a one-shot async call with no ongoing subscription).
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    final String publicHasherId = getStringPref(
      StringPrefsEnum.publicHasherId,
    )!;

    //final String publicHasherId = getStringPref(StringPrefsEnum.pu)!;
    final String hashName =
        getStringPref(StringPrefsEnum.displayName) ??
        getStringPref(StringPrefsEnum.firstName) ??
        '';
    final String photo = getStringPref(StringPrefsEnum.profilePhotoUrl)!;

    user = types.User(
      id: publicHasherId.toUpperCase(),
      firstName: hashName,
      imageUrl: photo,
    );

    // it's safe to call this async method synchronously here
    unawaited(onAppResumed());
  }

  void notificationReceived(RemoteMessage message) {
    // EventId = eventId,
    // Title = title,
    // UserId = userId,
    // UserDisplayName = userDisplayName,
    // UserPhoto = userPhoto,
    // Message = messageContent,
    // MessageId = messageId,
    // MessageRelesabilityFlags = messageRelesabilityFlags

    if (eventId.toUpperCase() ==
        message.data['EventId'].toString().toUpperCase()) {
      final msgUser = types.User(
        id: message.data['UserId'].toString().toUpperCase(),
        firstName: message.data['UserDisplayName'],
        imageUrl: message.data['UserPhoto'],
      );

      final textMessage = types.TextMessage(
        author: msgUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: message.data['MessageId'].toString().toUpperCase(),
        text: message.data['Message'],
      );

      final index = messages.indexWhere(
        (element) =>
            element.id.toUpperCase() ==
            message.data['MessageId'].toString().toUpperCase(),
      );

      if (index == -1) {
        final updatedMessage = textMessage.copyWith(status: types.Status.sent);
        addMessage(updatedMessage);
      } else {
        final updatedMessage = (messages[index] as types.TextMessage).copyWith(
          status: types.Status.sent,
        );

        messages[index] = updatedMessage;
        update([UpdateIds.chatMessages]);
      }
    }
  }

  Future<void> onAppResumed() async {
    messagesLoading.value = true;
    var result = await _getEventMessages(eventId);
    if (result != null) {
      final outerItem = jsonDecode(result) as List<dynamic>;
      messages = loadMessages(outerItem[0] as List<dynamic>);
      messagesLoading.value = false;
      update([UpdateIds.chatMessages]);
    }
  }

  Future<String?> _getEventMessages(String eventId) async {
    final String userId = getStringPref(StringPrefsEnum.userId)!;
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    //print('Get Event Messages called at ${DateTime.now().toIso8601String()}');

    final accessToken = Utilities.generateToken(
      userId,
      'hcapp_getEventMessages',
      paramString: deviceSecret,
    );

    final body = <String, String>{
      'queryType': 'getEventMessages',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'eventId': eventId,
    };

    final jsonResult = await ServiceCommon.sendHttpPost(jsonEncode(body));

    return jsonResult;
  }

  late final types.User user;

  void updateSizeWithDebounce(double newWidth, double newHeight) {
    if (width.value != newWidth) {
      width.value = newWidth;
    }
    if (height.value != newHeight) {
      height.value = newHeight;
    }
  }

  void addMessage(types.Message message) {
    messages.insert(0, message);

    // if (visibility > .1) {
    //   final chatsCounts = getMapIntPref(MapPrefsEnum.unusedChatCounts);
    //   //print('Add message chat message length = ${messages.length}');

    //   chatsCounts[publicEventId] = messages.length;

    //   // it's fine to call this async method unawaited
    //   setMapIntPref(MapPrefsEnum.unusedChatCounts, chatsCounts);
    // }

    update([UpdateIds.chatMessages]);
  }

  void handleAttachmentPressed() {
    unawaited(
      Get.bottomSheet<void>(
        SafeArea(
          child: SizedBox(
            height: 144,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextButton(
                  onPressed: () async {
                    Get.back<void>(); // Close the bottom sheet
                    await handleImageSelection();
                  },
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('Photo'),
                  ),
                ),
                // TextButton(
                //   onPressed: () {
                //     Get.back<void>(); // Close the bottom sheet
                //     handleFileSelection();
                //   },
                //   child: const Align(
                //     alignment: AlignmentDirectional.centerStart,
                //     child: Text('File'),
                //   ),
                // ),
                TextButton(
                  onPressed: () => Get.back<void>(), // Close the bottom sheet
                  child: const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierColor: Colors.black54, // Optional: Background dimming
        // isDismissible: true,          // Optional: Allows dismissing by tapping outside
        // enableDrag: true,             // Optional: Allows dragging to close
      ),
    );
  }

  // Future<void> handleFileSelection() async {
  //   final result = await FilePicker.platform.pickFiles(
  //       //type: FileType.any,
  //       );

  //   if (result != null && result.files.single.path != null) {
  //     final message = types.FileMessage(
  //       author: user,
  //       createdAt: DateTime.now().millisecondsSinceEpoch,
  //       id: const Uuid().v4(),
  //       mimeType: lookupMimeType(result.files.single.path!),
  //       name: result.files.single.name,
  //       size: result.files.single.size,
  //       uri: result.files.single.path!,
  //     );

  //     addMessage(message);
  //   }
  // }

  Future<void> handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      addMessage(message);
    }
  }

  Future<void> handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      //var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = messages.indexWhere(
            (element) => element.id == message.id,
          );
          final updatedMessage = (messages[index] as types.FileMessage)
              .copyWith(isLoading: true);

          messages[index] = updatedMessage;
        } finally {
          final index = messages.indexWhere(
            (element) => element.id == message.id,
          );
          final updatedMessage = (messages[index] as types.FileMessage)
              .copyWith(
                //isLoading: null,
              );

          messages[index] = updatedMessage;
        }
      }

      //await OpenFilex.open(localPath);
    }
  }

  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    messages[index] = updatedMessage;
  }

  Future<void> handleSendPressed(types.PartialText message) async {
    String uuid = const Uuid().v4();
    final textMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: uuid,
      text: message.text,
      showStatus: true,
      status: types.Status.sending,
    );

    addMessage(textMessage);

    //final hasherId = await box!.get(HIVE_HASHER_ID) as String;
    final userId = getStringPref(StringPrefsEnum.userId)!;
    String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    String deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final accessToken = Utilities.generateToken(
      userId,
      'hcapp_sendEventMessage',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'sendEventMessage',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'eventId': eventId,
      'messageId': uuid,
      'messageContent': textMessage.text,
      'messageReleasabilityFlags': 63,
    };

    await ServiceCommon.sendHttpPost(jsonEncode(body));

    // print(result);
    // await sendNotification(
    //   'fSH1Tfm2jEo_p_XsWxExsl:APA91bHIspRWUqleOS5OxtXz2dqjuQdswjpM8IPb0WeV0LuVx-dmaVboDKBgqJr9LTB2BX3BsylF7ygZpEjWNE3ZN9oGv8o4aQwiI24C7t8KBw2RY4jFo5U',
    //   'Run Start Changed',
    //   textMessage.text,
    // );
  }

  List<Map<String, dynamic>> preprocessMessages(List<dynamic> messageList) {
    return messageList.map((item) {
      final Map<String, dynamic> message =
          Map<String, dynamic>.from(item as Map<String, dynamic>);

      // HC5: author was a serialised JSON string stored in the DB.
      if (message['author'] is String) {
        message['author'] = jsonDecode(message['author'].toString());
      }
      // HC6: author is flat columns — reconstruct the object expected by flutter_chat_types.
      else if (message.containsKey('authorId')) {
        message['author'] = <String, dynamic>{
          'id': message['authorId'],
          'firstName': message['authorFirstName'],
          'imageUrl': message['authorImageUrl'],
          'type': 'user',
        };
        message.remove('authorId');
        message.remove('authorFirstName');
        message.remove('authorImageUrl');
      }

      message['showStatus'] = true;

      return message;
    }).toList();
  }

  List<types.Message> loadMessages(List<dynamic> messageList) {
    final mList = preprocessMessages(messageList);
    final msgs = mList.map(types.Message.fromJson).toList();

    final updatedMsgs = msgs
        .map((msg) => msg.copyWith(status: types.Status.sent))
        .toList();

    // // if (visibility > .1) {
    // final chatsCounts = getMapIntPref(MapPrefsEnum.unusedChatCounts);
    // //print('Load messages chat message length = ${updatedMsgs.length}');

    // chatsCounts[publicEventId] = updatedMsgs.length;

    // // it's fine to call this async method unawaited
    // setMapIntPref(MapPrefsEnum.unusedChatCounts, chatsCounts);
    // //  }

    return updatedMsgs;
  }
}
