import 'package:harrier_central/imports.dart';

class NotificationService extends GetxService with WidgetsBindingObserver {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  Future<NotificationService> init() async {
    WidgetsBinding.instance.addObserver(this);

    await _requestPermission();
    await _setupInitialMessage();
    _setupFirebaseListeners();
    _ensureFcmListener();

    return this;
  }

  void _ensureFcmListener() {
    _fcmSubscription
        ?.cancel(); // Cancel any existing listener to prevent duplicates

    _fcmSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
  }

  void refreshFcmListenerOnResume() {
    print("App resumed – refreshing FCM listener");
    _ensureFcmListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshFcmListenerOnResume();
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    setBoolPref(BoolPrefsEnum.notificationPreferencesRequested, true);

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
      print('Initial message received: ${initialMessage.data}');
    }
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
      print('Initial message received: ${message.data}');
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print("Foreground message received: ${message.data}");
    _dispatchMessageToControllers(message);
  }

  void _handleNotificationClick(RemoteMessage message) {
    //pop all the way back to the main page
    Get.until((route) => route.settings.name == '/main');

    if (Get.isRegistered<FutureRunListPageController>()) {
      Get.find<FutureRunListPageController>().processNotificationClickOnResume(
        message,
      );
    } else {
      print(
        "FutureRunListPageController not found, cannot process notification click.",
      );
    }
  }

  void _dispatchMessageToControllers(RemoteMessage message) {
    MessageType messageType = MessageType.fromId(
      int.tryParse(message.data['MessageType']) ?? 0,
    );

    switch (messageType) {
      case MessageType.chat:
        try {
          if (Get.isRegistered<FutureRunListPageController>()) {
            Get.find<FutureRunListPageController>().notificationReceived(
              message,
            );
          }

          if (Get.isRegistered<ChatPageController>()) {
            Get.find<ChatPageController>().notificationReceived(message);
          }

          print('Handling chat message: ${message.data}');
        } catch (e) {
          print("ChatController not found: $e");
        }
        break;

      default:
        print("Unhandled message type: $messageType");
    }
  }

  @override
  void onClose() {
    _fcmSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
