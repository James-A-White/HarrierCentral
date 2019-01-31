import 'dart:async';

import 'package:flutter/material.dart';

import 'package:harrier_central/remote_api_data/payment_report_scoped_model.dart';
import 'package:harrier_central/pages/kennel_admin/add_member_page.dart';
import 'package:harrier_central/widgets/payment_report_list_item.dart';
import 'package:harrier_central/data_models/kennel_model.dart';

import 'package:scoped_model/scoped_model.dart';

class PaymentReportPage extends StatelessWidget {
  final String eventId;
  final String currencySymbol;
  final int digitsAfterDecimal;

  PaymentReportPage({Key key, @required this.eventId, @required this.currencySymbol, @required this.digitsAfterDecimal}) : super(key: key);

  final PaymentReportScopedModel paymentReportModel =
      PaymentReportScopedModel();

  @override
  Widget build(BuildContext context) {
    if ((paymentReportModel?.paymentReportsList?.length ?? 0) == 0) {
      paymentReportModel.getPaymentReportsFromBackend(1, true, eventId);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'test',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: ScopedModel<PaymentReportScopedModel>(
          model: paymentReportModel,
          child: PaymentReportsListPageBody(
            eventId: eventId,
            currencySymbol: currencySymbol,
            digitsAfterDecimal: digitsAfterDecimal,
          )),
    );
  }
}

class PaymentReportsListPageBody extends StatelessWidget {
  final String eventId;
  final String currencySymbol;
  final int digitsAfterDecimal;

  PaymentReportsListPageBody({Key key, @required this.eventId, @required this.currencySymbol, @required this.digitsAfterDecimal})
      : super(key: key);

  BuildContext context;
  PaymentReportScopedModel model;

  int pageIndex = 1;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return ScopedModelDescendant<PaymentReportScopedModel>(
      builder:
          (BuildContext context, Widget child, PaymentReportScopedModel model) {
        this.model = model;
        return model.isLoading
            ? _buildCircularProgressIndicator()
            : _buildListView();
      },
    );
  }

  Widget _buildCircularProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<Null> _handleRefresh() async {
    model.getPaymentReportsFromBackend(1, false, eventId);
    model.notifyListeners();

    return null;
  }

  Widget _buildListView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: model.getPaymentReportsListCount() == 0
                ? const Center(child: Text('No transactions available.'))
                : RefreshIndicator(
                    onRefresh: () => _handleRefresh(),
                    displacement: 40.0,
                    child: ListView.separated(
                      separatorBuilder: (context, index) => Divider(height:1.0,
        color: Colors.black45,
      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: model.getPaymentReportsListCount(),
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          height: 40.0,
                          padding: const EdgeInsets.all(0.0),
                          child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: <Widget>[
                                PaymentReportListItem(
                                    paymentReportItem:
                                        model.paymentReportsList[index],
                                        currencySymbol: currencySymbol,
                                        digitsAfterDecimal: digitsAfterDecimal,
                                        ),
                              ]),
                        );
                      },
                    ),
                  ),
          ),
        ),
      //   Container(
      //     width: 150.0,
      //     child: RaisedButton(
      //       child: const Text(
      //         'Add Member',
      //         style: TextStyle(color: Colors.white),
      //       ),
      //       onPressed: () {
      //         Navigator.push<dynamic>(
      //           context,
      //           MaterialPageRoute<dynamic>(
      //             builder: (context) => AddMemberPage(
      //                   kennelId: kennelId,
      //                 ),
      //           ),
      //         );
      //       },
      //     ),
      //   ),
      ],
    );
  }
}
