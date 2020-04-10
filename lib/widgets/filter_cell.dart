import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CheckinFiltersCell extends StatelessWidget {
  const CheckinFiltersCell({
    @required this.counter,
    @required this.index,
    @required this.label,
    @required this.onTap,
    @required this.filterValues,
    this.color,
    this.icon,
    this.useTriState = true,
  });

  final IconData icon;
  final Color color;
  final Function onTap;
  final num counter;
  final String label;
  final int index;
  final bool useTriState;
  final List<int> filterValues;

  @override
  Widget build(BuildContext context) {
    //final String total = (creditAmount ?? 0) <= 0 ? '' : CoreUtilities.getFormattedMoney(creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    const TextStyle textStyle = TextStyle(color: Colors.black, fontSize: 24.0, fontFamily: 'AvenirNextCondensedDemiBold');
    return Container(
      width: 50,
      child: Column(
        children: <Widget>[
          Text(
            counter < 0 ? '' : (counter ?? 0).toString(),
            style: textStyle,
          ),
          IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              if (index >= 0) {
                filterValues[index]++;
                if (filterValues[index] > 1) {
                  filterValues[index] = useTriState ? -1 : 0;
                }
              }
              onTap();
            },
            icon: Icon(icon != null ? icon : filterValues[index] == -1 ? FontAwesome.times_circle : filterValues[index] == 0 ? FontAwesome.circle_thin : FontAwesome.check_circle,
                size: 35, color: color != null ? color : filterValues[index] == -1 ? Colors.red : filterValues[index] == 0 ? Colors.grey[350] : Colors.green),
          ),
          Container(
            child: AutoSizeText(
              label,
              style: textStyle,
              maxLines: 1,
              minFontSize: 2.0,
            ),
            height: 20,
          ),
        ],
      ),
    );
  }
}
