import 'package:harrier_central/imports.dart';
import 'package:harrier_central/firebase_options.dart';

class NotificationService extends GetxService with WidgetsBindingObserver {
  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  Future<NotificationService> init() async {
    WidgetsBinding.instance.addObserver(this);

    if (getStringPref(StringPrefsEnum.bootType) == BOOT_TYPE_UPGRADE_1_2) {
      return this;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (Firebase.apps.isNotEmpty) {
      _messaging = FirebaseMessaging.instance;

      if (!(getBoolPref(BoolPrefsEnum.notificationPreferencesRequested) ??
          false)) {
        await requestPermission();
      }

      await _setupInitialMessage();
      _setupFirebaseListeners();
      _ensureFcmListener();
    }

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
    if (kDebugMode) {
      print("App resumed – refreshing FCM listener");
    }
    _ensureFcmListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshFcmListenerOnResume();
    }
  }

  Future<void> requestPermission() async {
    if (Firebase.apps.isNotEmpty) {
      _messaging ??= FirebaseMessaging.instance;

      if (_messaging != null) {
        NotificationSettings settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        String? apnsToken = await _messaging!.getAPNSToken();
        String? fcmToken;

        if (apnsToken != null) {
          apnsToken = apnsToken.trim();
          await setStringPref(StringPrefsEnum.apnsToken, apnsToken);

          fcmToken = await _messaging!.getToken();

          if (fcmToken != null && fcmToken.isNotEmpty) {
            await setStringPref(StringPrefsEnum.fcmToken, fcmToken);
          }
        }

        final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
        final String deviceSecret =
            getStringPref(StringPrefsEnum.deviceSecret) ?? '';
        final String userId = getStringPref(StringPrefsEnum.userId) ?? '';

        if ((deviceId.isNotEmpty) &&
            (deviceSecret.isNotEmpty) &&
            (userId.isNotEmpty)) {
          final String accessToken = Utilities.generateToken(
            userId,
            'hcapp_setFcmTokens',
            paramString: deviceSecret,
          );

          Map<String, String> params = (<String, String>{
            'queryType': 'setFcmTokens',
            'deviceId': deviceId,
            'accessToken': accessToken,
          });

          if (apnsToken != null) {
            params.addAll({'apnsToken': apnsToken});
          }

          if (fcmToken != null) {
            params.addAll({'fcmToken': fcmToken});
          }

          final String body = jsonEncode(params);

          try {
            await ServiceCommon.sendHttpPostV2(body);
            await setBoolPref(BoolPrefsEnum.fcmTokenSavedToServer, true);
          } catch (e) {
            if (kDebugMode) {
              print('Connection error: ${e.toString()}');
            }
          }
        }

        setBoolPref(BoolPrefsEnum.notificationPreferencesRequested, true);

        if (kDebugMode) {
          print(
            'Notification permission status: ${settings.authorizationStatus}',
          );
        }
      } else {
        setBoolPref(BoolPrefsEnum.notificationPreferencesRequested, false);
        if (kDebugMode) {
          print(
            'Firebase not initialized, cannot request notification permission.',
          );
        }
      }
    }
  }

  Future<void> _setupInitialMessage() async {
    if (_messaging != null) {
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
        if (kDebugMode) {
          print('Initial message received: ${initialMessage.data}');
        }
      }
    }
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
      if (kDebugMode) {
        print('Initial message received: ${message.data}');
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print("Foreground message received: ${message.data}");
    }
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
      if (kDebugMode) {
        print(
          "FutureRunListPageController not found, cannot process notification click.",
        );
      }
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

          if (kDebugMode) {
            print('Handling chat message: ${message.data}');
          }
        } catch (e) {
          if (kDebugMode) {
            print("ChatController not found: $e");
          }
        }
        break;

      default:
        if (kDebugMode) {
          print("Unhandled message type: $messageType");
        }
    }
  }

  @override
  void onClose() {
    _fcmSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
