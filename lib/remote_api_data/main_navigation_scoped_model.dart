import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';
import 'package:harrier_central/widgets/placeholder_widget.dart';
import 'package:harrier_central/util/preferences.dart';
import 'package:harrier_central/remote_api_data/kennel_scoped_model.dart';
import 'package:harrier_central/remote_api_data/future_run_scoped_model.dart';

import 'package:scoped_model/scoped_model.dart';

enum EnumAppPages {
  notUsed,
  notUsed2,
  futureRuns,
  kennelList,
  notUsed3,
  notUsed4,
  notUsed5,
  notUsed6,
  notUsed7,
  facebookLogin
}

class MainNavigationScopedModel extends Model {

  final MainNavigation _mainNavigation = MainNavigation();

  GlobalKey<ScaffoldState> mainAppScaffoldKey = GlobalKey<ScaffoldState>();

  final KennelScopedModel kennelModel = KennelScopedModel();
  final FutureRunScopedModel futureRunsModel = FutureRunScopedModel();
  //final Futurerun

  //String mainPageTitle = 'Home Page';

  void init() {
    if (_mainNavigation?.children == null) {
      kennelModel.getKennelsFromBackend(1, true);
      futureRunsModel.getFutureRunsFromBackend(1, true);

      _mainNavigation.children = <Widget>[
        const PlaceholderWidget(Colors.red),
        FutureRunsListPage(futureRunsModel: futureRunsModel),
        KennelsListPage(kennelModel: kennelModel),
        const PlaceholderWidget(Colors.purple),
        UserQrCodePage(),
        const PlaceholderWidget(Colors.teal),
        const PlaceholderWidget(Colors.blue),
        const PlaceholderWidget(Colors.red),
        FbLoginPage()
      ];
    }

    _mainNavigation.currentIndex = 3;
       // Preferences.getIntPref(IntPrefsEnum.mainViewCurrentTab);
  }

  set currentIndex(int ci) {
    if (_mainNavigation?.children == null) {
      init();
    }

    if ((ci > 0) && (_mainNavigation.currentIndex != ci)) {
      _mainNavigation.currentIndex = ci;
      notifyListeners();
    }
  }

  int get currentIndex {
    return _mainNavigation.currentIndex;
  }

  set appBarTitle(String title) {
    if (_mainNavigation.appBarTitle != title) {
      _mainNavigation.appBarTitle = title;
      notifyListeners();
    }
  }

  String get appBarTitle {
    return _mainNavigation.appBarTitle ?? 'Main Page';
  }

  MainNavigation get homePage => _mainNavigation;
}
