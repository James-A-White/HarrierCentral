//import 'package:hcportal/admin_pages/promotions/promotions_list_page.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hcportal/imports.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// void getParams() {
//   final Uri uri = Uri.dataFromString(window.location.href);
//   final Map<String, String> params = uri.queryParameters;
//   final String? runId = params['runId'];
//   //final String? destiny = params['destiny'];
//   print('runId=' + (runId ?? '');
//   //print(destiny ?? '');
// }

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('Handling a background message: ${message.messageId}');
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.openBox<dynamic>('HCPortal');

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    GetMaterialApp(
      //debugShowCheckedModeBanner: false,
      title: 'Harrier Central Admin Portal',
      // theme: ThemeData(primarySwatch: Colors.blue),
      // home: MyApp(),

      navigatorKey: navigatorKey,
      home: const AdminPortalApp(),
      scrollBehavior: MyCustomScrollBehavior(),

      theme: ThemeData(
        primaryColor: Colors.grey.shade700,
        primaryColorDark: Colors.grey.shade900,
        primaryColorLight: Colors.grey.shade400,
        bottomAppBarTheme: BottomAppBarThemeData(color: Colors.grey.shade700),
        highlightColor: Colors.yellow,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(color: Colors.white),
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          //     style: TextButton.styleFrom(
          //   backgroundColor: Colors.red.shade900,
          //   primary
          //   textStyle: const TextStyle(color: Colors.white),
          // )
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all<Color>(Colors.red.shade900),
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        scaffoldBackgroundColor: Colors.brown.shade50,
      ),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        FormBuilderLocalizations.delegate,
      ],
    ),
  );
}
