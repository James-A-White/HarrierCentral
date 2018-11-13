import 'dart:core';
import 'package:flutter/material.dart';

class MainNavigation {

  List<Widget> children = <Widget>[];
  int currentIndex = 0;

  MainNavigation(
    {
        this.children,
        this.currentIndex
    });

  // @override
  // toString() => "$kennelName";

}