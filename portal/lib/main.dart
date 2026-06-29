//import 'package:hcportal/admin_pages/promotions/promotions_list_page.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hcportal/imports.dart';
import 'package:timezone/data/latest.dart' as tzdata;

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

  // Load the IANA timezone database so we can show zone abbreviations
  // (e.g. EST/EDT) derived from a city's IANA name.
  tzdata.initializeTimeZones();

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
        // Portal button system (see lib/util/styles.dart). Bare buttons now get
        // the consistent look by default; TextButtons are FLAT (no red fill —
        // the old textButtonTheme made every Cancel look like a primary button).
        elevatedButtonTheme:
            ElevatedButtonThemeData(style: hcPrimaryButtonStyle),
        textButtonTheme: TextButtonThemeData(style: hcTextButtonStyle),
        outlinedButtonTheme:
            OutlinedButtonThemeData(style: hcOutlinedButtonStyle),
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        scaffoldBackgroundColor: Colors.brown.shade50,
      ),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        FormBuilderLocalizations.delegate,
      ],
    ),
  );
}
