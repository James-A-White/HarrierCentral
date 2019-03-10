

// import 'package:flutter/material.dart';

// import 'package:harrier_central/data_models/main_navigation_model.dart';
// import 'package:harrier_central/pages/facebook_login.dart';
// import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
// import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
// import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';
// import 'package:harrier_central/services/kennel_scoped_model.dart';
// import 'package:harrier_central/widgets/placeholder_widget.dart';

// import 'package:scoped_model/scoped_model.dart';


// class MainNavigationScopedModel extends Model {

//   final MainNavigation _mainNavigation = MainNavigation();

//   GlobalKey<ScaffoldState> mainAppScaffoldKey = GlobalKey<ScaffoldState>();

//   final KennelScopedModel kennelModel = KennelScopedModel();

//   void init() {
//     if (_mainNavigation?.children == null) {
//       kennelModel.getKennelsFromBackend(1, true);
//       //futureRunsModel.getFutureRunsFromBackend(1, true);

//       _mainNavigation.children = <Widget>[
//         const PlaceholderWidget(Colors.red),
//         FutureRunsListPage(),
//         KennelsListPage(kennelModel: kennelModel),
//         const PlaceholderWidget(Colors.purple),
//         UserQrCodePage(),
//         const PlaceholderWidget(Colors.teal),
//         const PlaceholderWidget(Colors.blue),
//         const PlaceholderWidget(Colors.red),
//         FbLoginPage()
//       ];
//     }

//     _mainNavigation.currentMainAppView = EnumAppPages.futureRuns;
//        // Preferences.getIntPref(IntPrefsEnum.mainViewCurrentTab);
//   }

//   set currentMainView(EnumAppPages ci) {
//     if (_mainNavigation?.children == null) {
//       init();
//     }

//     if ((ci.index > 0) && (_mainNavigation.currentMainAppView != ci)) {
//       _mainNavigation.currentMainAppView = ci;
//       notifyListeners();
//     }
//   }

//   EnumAppPages get currentMainView {
//     return _mainNavigation.currentMainAppView;
//   }

//   set appBarTitle(String title) {
//     if (_mainNavigation.appBarTitle != title) {
//       _mainNavigation.appBarTitle = title;
//       notifyListeners();
//     }
//   }

//   String get appBarTitle {
//     return _mainNavigation.appBarTitle ?? 'Main Page';
//   }

//   MainNavigation get homePage => _mainNavigation;
// }
