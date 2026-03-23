import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hcportal/firebase_options.dart';
import 'package:hcportal/imports.dart';

class AdminPortalController extends GetxController {
  final String authCode = const Uuid().v4();

  String firstName = '';
  String lastName = '';
  String hashName = '';
  String displayName = '';
  String photo = '';
  String publicHasherId = '';
  bool isReady = false;

  final List<HasherKennelsModel> allKennels = [];
  final List<HasherKennelsModel> filteredKennels = [];

  bool hasNavigated = false;

  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    unawaited(_init());
  }

  @override
  void onClose() {
    searchFocusNode.dispose();
    searchController.dispose();
    super.onClose();
  }

  void filterKennels(String text) {
    filteredKennels
      ..clear()
      ..addAll(
        allKennels
            .where(
              (element) =>
                  element.kennelName.toLowerCase().contains(text.toLowerCase()),
            )
            .toList(),
      );
    update();
  }

  Future<void> _initHive() async {
    Hive.init('ignored');
    box = await Hive.openBox<dynamic>(HIVE_NAME);
    isReady = true;
    update();
  }

  Future<void> _init() async {
    await _initHive();

    packageInfo.value = await PackageInfo.fromPlatform();

    try {
      var previousBuildNumber = 0;

      if (box.containsKey(HIVE_APP_BUILD)) {
        previousBuildNumber = await box.get(HIVE_APP_BUILD) as int;
      }

      previousBuildNumber =
          int.tryParse(packageInfo.value?.buildNumber ?? '0') ?? 0;

      // Sometimes we change the types of parameters being saved in Hive.
      // When we do this, clear all parameters and force a re-login to
      // reset everything to a stable and known state.
      if (previousBuildNumber <= 554) {
        await box.clear();
      }

      // If the previousBuildNumber and currentBuildNumber differ, the
      // software has been updated since the last run.
      final currentBuildNumber =
          int.tryParse(packageInfo.value?.buildNumber ?? '0') ?? 0;

      if (previousBuildNumber != currentBuildNumber) {
        await box.put(HIVE_APP_BUILD, previousBuildNumber);
        await box.put(HIVE_APP_VERSION, packageInfo.value?.buildNumber ?? '0');
      }

      // uncomment the line below to force login on every run
      //await box.put(HIVE_IS_LOGGED_IN, false);
      if (!box.containsKey(HIVE_IS_LOGGED_IN)) {
        await box.put(HIVE_IS_LOGGED_IN, false);
      }

      if (box.get(HIVE_IS_LOGGED_IN) as bool) {
        firstName = box.get(HIVE_FIRST_NAME) as String;
        lastName = box.get(HIVE_LAST_NAME) as String;
        hashName = box.get(HIVE_HASH_NAME) as String;
        displayName = box.get(HIVE_DISPLAY_NAME) as String? ??
            box.get(HIVE_HASH_NAME) as String;
        photo = box.get(HIVE_HASHER_PHOTO) as String? ?? '';
        publicHasherId = box.get(HIVE_HASHER_ID) as String;

        await _getHasherKennels();
      } else {
        final deviceId = const Uuid().v4();

        final deviceInfoPlugin = DeviceInfoPlugin();
        final webInfo = await deviceInfoPlugin.webBrowserInfo;

        final deviceData = {
          'browserName': webInfo.browserName.toString(),
          'appCodeName': webInfo.appCodeName,
          'appName': webInfo.appName,
          'appVersion': webInfo.appVersion,
          'deviceMemory': webInfo.deviceMemory,
          'language': webInfo.language,
          'languages': webInfo.languages,
          'platform': webInfo.platform,
          'product': webInfo.product,
          'productSub': webInfo.productSub,
          'userAgent': webInfo.userAgent,
          'vendor': webInfo.vendor,
          'vendorSub': webInfo.vendorSub,
          'hardwareConcurrency': webInfo.hardwareConcurrency,
          'maxTouchPoints': webInfo.maxTouchPoints,
        };

        final allInfo = jsonEncode(deviceData);
        await Future<void>.delayed(
          const Duration(seconds: AUTH_POLL_INTERVAL_SECONDS),
        );

        for (var i = 0; i < AUTH_POLL_MAX_ATTEMPTS; i++) {
          // NOTE: This is a randomly generated user ID that matches the one
          // in the database used to generate the access token.
          // DO NOT CHANGE THIS or it will result in an invalid access token error.
          const serviceAccountId = HC_ADMIN_PORTAL_INTERNAL_USER_ID;

          final accessToken = Utilities.generateToken(
            serviceAccountId,
            'hcportal_confirmAuthentication',
            paramString: authCode,
          );

          final body = <String, String?>{
            'queryType': 'confirmAuthentication',
            'deviceId': serviceAccountId,
            'newDeviceId': deviceId,
            'accessToken': accessToken,
            'qrCodeData': authCode,
            'deviceInfo': allInfo,
          };

          final jsonResult =
              await ServiceCommon.sendHttpPostToHC6Api(body);
          debugPrint(jsonResult.startsWith(ERROR_PREFIX)
              ? 'SP 4 [confirmAuthentication] called — FAILED'
              : 'SP 4 [confirmAuthentication] called — success');

          if ((jsonResult.length > 10) &&
              (!jsonResult.contains(ERROR_PREFIX))) {
            final items = ((json.decode(jsonResult) as List<dynamic>)[0]
                as List<dynamic>)[0] as Map<String, dynamic>;

            publicHasherId = items['publicHasherId'] as String;
            if (publicHasherId.isNotEmpty) {
              firstName = items['firstName'] as String;
              lastName = items['lastName'] as String;
              hashName = items['hashName'] as String;
              displayName = items['displayName'] as String;
              photo = items['photo'] as String;
              await box.put(HIVE_FIRST_NAME, firstName);
              await box.put(HIVE_LAST_NAME, lastName);
              await box.put(HIVE_HASH_NAME, hashName);
              await box.put(HIVE_DISPLAY_NAME, displayName);
              await box.put(HIVE_HASHER_PHOTO, photo);
              await box.put(HIVE_HASHER_ID, publicHasherId);
              await box.put(HIVE_DEVICE_ID, deviceId);
              await box.put(
                HIVE_DEVICE_SECRET,
                (items['iconDataBase64'] as String?) ?? '',
              );
              await box.put(HIVE_IS_LOGGED_IN, true);

              update();

              await _getHasherKennels();

              break;
            }
          }
          await Future<void>.delayed(
            const Duration(seconds: AUTH_POLL_INTERVAL_SECONDS),
          );
        }
      }
      unawaited(_initializeNotifications());
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('App init error: $e');
    }
  }

  Future<String?> _fetchAndStoreFcmToken(FirebaseMessaging messaging) async {
    final cachedFcmToken = (box.get(HIVE_FCM_TOKEN) as String?) ?? '';
    final newToken = await messaging.getToken(vapidKey: FIREBASE_VAPID_KEY);
    if (newToken != null && newToken != cachedFcmToken) {
      await box.put(HIVE_FCM_TOKEN, newToken);
      await box.put(HIVE_FCM_TOKEN_CHANGED, true);
      await box.put(HIVE_FCM_TOKEN_DATE, DateTime.now());
    } else {
      await box.put(HIVE_FCM_TOKEN_CHANGED, false);
    }
    return newToken;
  }

  Future<void> _syncFcmTokenToServer(String? fcmToken) async {
    final deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_updateFcmToken',
      paramString: deviceSecret,
    );
    final body = <String, String?>{
      'queryType': 'updateFcmToken',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'fcmToken': fcmToken,
      'buildNumber': packageInfo.value?.buildNumber ?? '0',
      'version': packageInfo.value?.version ?? 'unknown',
    };
    final fcmResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(fcmResult.startsWith(ERROR_PREFIX)
        ? 'SP 19 [updateFcmToken] called — FAILED'
        : 'SP 19 [updateFcmToken] called — success');
  }

  Future<void> _initializeNotifications() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Sync refreshed tokens to the DB mid-session (Firebase can rotate tokens
    // at any time without an app restart).
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await box.put(HIVE_FCM_TOKEN, token);
      await _syncFcmTokenToServer(token);
    });

    String? newFcmToken;

    final messaging = FirebaseMessaging.instance;
    final ns = await messaging.getNotificationSettings();
    if (ns.authorizationStatus == AuthorizationStatus.authorized) {
      newFcmToken = await _fetchAndStoreFcmToken(messaging);
    } else if ((ns.authorizationStatus == AuthorizationStatus.notDetermined) ||
        (ns.authorizationStatus == AuthorizationStatus.provisional)) {
      await CoreUtilities.showAlert(
        'Harrier Central Notifications',
        'Harrier Central will soon contain a trail chat function (expected in the next few weeks) where a chat group is automatically created for each run.\r\n\r\nFor this to work properly, you must enable notifications. You will not receive any pop-up notifications by enabling notifications for Harrier Central.',
        'OK',
        dialogImage: 'images/other/chat_dialog.png',
        width: 700,
        height: 380,
      );

      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        newFcmToken = await _fetchAndStoreFcmToken(messaging);
      } else {
        await box.delete(HIVE_FCM_TOKEN);
        await box.delete(HIVE_FCM_TOKEN_CHANGED);
        await box.delete(HIVE_FCM_TOKEN_DATE);
      }
    } else if (ns.authorizationStatus == AuthorizationStatus.denied) {
      var fcmTokenDeniedCount =
          (box.get(HIVE_FCM_TOKEN_DENIED_COUNT) ?? 0) as int;

      if (fcmTokenDeniedCount % FCM_DENIED_REMINDER_INTERVAL == 0) {
        final userResponse = await CoreUtilities.showAlert(
              'Harrier Central Notifications',
              'Harrier Central will soon contain a trail chat function (expected in the next few weeks) where a chat group is automatically created for each run.\r\n\r\nFor this to work properly, you must enable notifications. You will not receive any pop-up notifications by enabling notifications for Harrier Central.',
              'Allow notifications',
              cancelButtonText: 'Do not allow',
              showCancelButton: true,
              dialogImage: 'images/other/chat_dialog.png',
              width: 700,
              height: 380,
            ) ??
            true;

        if (userResponse) {
          await CoreUtilities.showAlert(
            'Harrier Central Notifications',
            "It looks like you have previously blocked notifications for Harrier Central. Our web app cannot force the browser to ask you again for permission to show notifications.\r\n\r\nYou will have to enable notifications for Harrier Central in your browser's settings.",
            'OK',
            width: 400,
            height: 150,
          );
        }
      }

      fcmTokenDeniedCount++;
      await box.put(HIVE_FCM_TOKEN_DENIED_COUNT, fcmTokenDeniedCount);
    }

    await _syncFcmTokenToServer(newFcmToken);
  }

  Future<void> _getHasherKennels() async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final fcmToken = box.get(HIVE_FCM_TOKEN) as String?;

    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getLandingPageData',
      paramString: deviceSecret,
    );

    final body = <String, String?>{
      'queryType': 'getLandingPageData',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'fcmToken': fcmToken,
    };

    final jsonResult = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonResult.startsWith(ERROR_PREFIX)
        ? 'SP 13 [getLandingPageData] called — FAILED'
        : 'SP 13 [getLandingPageData] called — success');
    if (jsonResult.length > 10) {
      final items = ((json.decode(jsonResult) as List<dynamic>)[0]
          as List<dynamic>)[0] as Map<String, dynamic>;

      if (publicHasherId.isNotEmpty) {
        firstName = items['firstName'] as String;
        lastName = items['lastName'] as String;
        hashName = items['hashName'] as String;
        await box.put(HIVE_FIRST_NAME, firstName);
        await box.put(HIVE_LAST_NAME, lastName);
        await box.put(HIVE_HASH_NAME, hashName);

        final itemList =
            (json.decode(jsonResult) as List<dynamic>)[1] as List<dynamic>;

        for (var i = 0; i < itemList.length; i++) {
          final hkModel = HasherKennelsModel.fromJson(
            itemList[i] as Map<String, dynamic>,
          );
          allKennels.add(hkModel);
        }
      }
    }

    allKennels.sort((HasherKennelsModel a, HasherKennelsModel b) {
      final cmp = (b.appAccessFlags & 0x00000001)
          .compareTo(a.appAccessFlags & 0x00000001);
      if (cmp != 0) {
        return cmp;
      }
      return a.kennelName.compareTo(b.kennelName);
    });

    filteredKennels.addAll(allKennels);
    update();
  }
}
