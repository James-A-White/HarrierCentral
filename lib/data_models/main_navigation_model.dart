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

  List<Widget> children = <Widget>[];
  EnumAppPages currentMainAppView = EnumAppPages.futureRuns;
  String appBarTitle = 'Home page';

  MainNavigation(
    {
        this.children,
        this.currentMainAppView,
        this.appBarTitle
    });

  // @override
  // toString() => "$kennelName";

}