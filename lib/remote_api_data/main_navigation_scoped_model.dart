import 'package:flutter/material.dart';

import 'package:harrier_central/data_models/main_navigation_model.dart';
import 'package:harrier_central/pages/facebook_login.dart';
import 'package:harrier_central/pages/top_level/future_run_list_page.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';
import 'package:harrier_central/pages/top_level/user_qr_code_page.dart';
import 'package:harrier_central/widgets/placeholder_widget.dart';

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

  MainNavigationScopedModel() {
      _mainNavigation.children = <Widget>[
      const PlaceholderWidget(Colors.red),
      FutureRunsListPage(),
      KennelsListPage(),
      const PlaceholderWidget(Colors.purple),
      UserQrCodePage(),
      const PlaceholderWidget(Colors.teal),
      const PlaceholderWidget(Colors.blue),
      const PlaceholderWidget(Colors.red),
      FbLoginPage()
    ];
    _mainNavigation.currentIndex = 3;
  }

  set currentIndex(int ci) {
    if (ci > 0) {
      _mainNavigation.currentIndex = ci;
    }
    notifyListeners();
  }

  int get currentIndex {
    return _mainNavigation.currentIndex;
  }

  MainNavigation get homePage => _mainNavigation;
}
