import 'dart:core';
import 'package:flutter/material.dart';

class MainNavigation {

  List<Widget> children = <Widget>[];
  int currentIndex = 0;
  String appBarTitle = 'Home page';

  MainNavigation(
    {
        this.children,
        this.currentIndex,
        this.appBarTitle
    });

  // @override
  // toString() => "$kennelName";

}