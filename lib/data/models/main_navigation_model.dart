import 'dart:core';
import 'package:flutter/material.dart';

enum EnumAppPages {
  settings,
  futureRuns,
  kennelList,
  runCounts,
  qrCodePage,
  friends,
  fab
}

class MainNavigation {
  MainNavigation({this.children, this.currentMainAppView, this.appBarTitle});

  List<Widget> children = <Widget>[];
  EnumAppPages currentMainAppView = EnumAppPages.futureRuns;
  String appBarTitle = 'Home page';

  // @override
  // toString() => "$kennelName";

}
