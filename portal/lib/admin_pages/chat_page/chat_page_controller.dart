// ignore_for_file: require_trailing_commas

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:hcportal/imports.dart';

class ChatSheetController extends GetxController {
  ChatSheetController({
    required this.publicEventId,
    required this.messageTitle,
  }) {
    // Initialize controllers with initial data if available
  }
  String publicEventId;
  String messageTitle;

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

  RxList<types.Message> messages = <types.Message>[].obs;

  late StreamSubscription<RemoteMessage> _fcmSubscription;

  @override
  void onClose() {
    unawaited(_fcmSubscription.cancel());
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    publicEventId = normalizeUuid(publicEventId);

    final publicHasherId = box.get(HIVE_HASHER_ID) as String;
    final hashName = box.get(HIVE_DISPLAY_NAME) as String? ??
        box.get(HIVE_HASH_NAME) as String;
    final photo = box.get(HIVE_HASHER_PHOTO) as String? ?? '';

    user = types.User(
      id: publicHasherId.toUpperCase(),
      firstName: hashName,
      imageUrl: photo,
    );

    unawaited(onInitAsync());
  }

  Future<void> onInitAsync() async {
    // Any asynchronous initialization can go here

    var result = await _getEventMessages(publicEventId);
    if (result != null) {
      final outerItem = jsonDecode(result) as List<dynamic>;
      messages.value = await loadMessages(outerItem[0] as List<dynamic>);
    }

    _fcmSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final incomingEventId = message.data['PublicEventId'] as String?;
      if (incomingEventId != null &&
          publicEventId == incomingEventId.asUuid) {
        final msgUser = types.User(
          id: message.data['UserId'].toString().toUpperCase(),
          firstName: message.data['UserDisplayName'] as String,
          imageUrl: message.data['UserPhoto'] as String?,
        );

        final textMessage = types.TextMessage(
          author: msgUser,
          roomId: message.data['PublicEventId'].toString().toUpperCase(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: message.data['MessageId'].toString().toUpperCase(),
          text: message.data['Message'] as String,
          status: types.Status.sent,
          showStatus: true,
        );

        final index = messages.indexWhere((element) =>
            element.id.toUpperCase() ==
            message.data['MessageId'].toString().toUpperCase());

        if (index == -1) {
          addMessage(textMessage);
        } else {
          final updatedMessage = (messages[index] as types.TextMessage)
              .copyWith(status: types.Status.sent);

          messages[index] = updatedMessage;
          update();
        }
      }
    });
  }

  Future<String?> _getEventMessages(String publicEventId) async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getEventMessages',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getEventMessages',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 9 [getEventMessages] called — FAILED'
        : 'SP 9 [getEventMessages] called — success');
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
  }

  Future<void> handleAttachmentPressed() async {
    await Get.bottomSheet<void>(
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
              TextButton(
                onPressed: () async {
                  Get.back<void>(); // Close the bottom sheet
                  await handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
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
    );
  }

  Future<void> handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
        //type: FileType.any,
        );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        //roomId: ,
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      addMessage(message);
    }
  }

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
        //roomId: ,
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
          final index =
              messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          messages[index] = updatedMessage;

          // final client = http.Client();
          // final request = await client.get(Uri.parse(message.uri));
          // final bytes = request.bodyBytes;
          //final documentsDir = (await getApplicationDocumentsDirectory()).path;
          //localPath = '$documentsDir/${message.name}';

          // if (!File(localPath).existsSync()) {
          //   final file = File(localPath);
          //   await file.writeAsBytes(bytes);
          // }
        } finally {
          final index =
              messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (messages[index] as types.FileMessage).copyWith(
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
    final uuid = const Uuid().v4();
    final textMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: uuid,
      roomId: publicEventId,
      text: message.text,
    );

    addMessage(textMessage);

    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_sendEventMessage',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'sendEventMessage',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicEventId': publicEventId,
      'messageId': uuid,
      'messageContent': textMessage.text,
      'messageReleasabilityFlags': 63,
      'messageTitle': messageTitle,
    };

    final sendResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(sendResult.startsWith(ERROR_PREFIX)
        ? 'SP 17 [sendEventMessage] called — FAILED'
        : 'SP 17 [sendEventMessage] called — success');
  }

  List<Map<String, dynamic>> preprocessMessages(List<dynamic> messageList) {
    return messageList.map((item) {
      final message = item as Map<String, dynamic>;

      // Decode the author field if it is a string
      if (message['author'] is String) {
        message['author'] = jsonDecode(message['author'].toString());
      }

      message['showStatus'] = true;
      //message['status'] = types.Status.sent;

      return message;
    }).toList();
  }

  Future<List<types.Message>> loadMessages(List<dynamic> messageList) async {
    final mList = preprocessMessages(messageList);
    final msgs = mList.map(types.Message.fromJson).toList();

    final updatedMsgs =
        msgs.map((msg) => msg.copyWith(status: types.Status.sent)).toList();

    final chatsCounts =
        (box.get(HIVE_CHATS_COUNT) as Map?)?.cast<String, int>() ?? {};

    chatsCounts[publicEventId] = updatedMsgs.length;

    // it's fine to call this async method unawaited
    await box.put(HIVE_CHATS_COUNT, chatsCounts);

    return updatedMsgs;
  }
}
