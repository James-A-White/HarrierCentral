import 'package:harrier_central/imports_null_safe.dart';

class PaymentTerminalConfigPage extends StatefulWidget {
  //final FutureRunScopedModel futureRunsModel;

  const PaymentTerminalConfigPage({Key? key}) : super(key: key);

  @override
  PaymentTerminalConfigPageState createState() => PaymentTerminalConfigPageState();
}

class PaymentTerminalConfigPageState extends State<PaymentTerminalConfigPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        title: const Text(
          'Payment Terminal Config',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: const <Widget>[
            Positioned(
                top: 10,
                left: 20,
                right: 20,
                //width: MediaQuery.of(context).size.width,
                child: PaymentTerminalConfigContent()),
          ],
        ),
      ),
    );
  }
}

class PaymentTerminalConfigContent extends StatefulWidget {
  const PaymentTerminalConfigContent({Key? key}) : super(key: key);

  @override
  PaymentTerminalConfigContentState createState() => PaymentTerminalConfigContentState();
}

class PaymentTerminalConfigContentState extends State<PaymentTerminalConfigContent> {
  final TextEditingController _accountKeyTextController = TextEditingController();

  final GlobalKey<FormState> _paymentTerminalFormKey = GlobalKey<FormState>();
  final bool _autoValidate = false;

  @override
  void initState() {
    _accountKeyTextController.text = getStringPref(StringPrefsEnum.paymentTerminalAccountKey) ?? '';

    super.initState();
  }

  // @override
  // void initState() {
  //   setStringPref(StringPrefsEnum.paymentTerminalAccountKey, 'eac2e79c-4704-4a3b-8d88-1fdb25d92909');
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: G0<DeviceInfo>().deviceWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            // padding: const EdgeInsets.all(10.0),
            // margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 20),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(10.0),
              //margin: const EdgeInsets.only(bottom: 45),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Form(
                key: _paymentTerminalFormKey,
                autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: _paymentTerminalFormUi(),
              ),
            ),

            //     //autovalidate: _autoValidate,
            //     TextField(
            //   autocorrect: false,
            //   //initialValue: _shortDescription,
            //   decoration: const InputDecoration.collapsed(hintText: 'Email body'),
            //   keyboardType: TextInputType.multiline,
            //   maxLines: null,
            //   minLines: 2,
            //   controller: _accountKeyTextController,

            //   onChanged: (String value) {
            //     setStringPref(StringPrefsEnum.paymentTerminalAccountKey, value);
            //   },

            //   // validator: (String arg) {
            //   //   if (arg.length < 4)
            //   //     return 'Description must be more than 3 charaters';
            //   //   else
            //   //     return null;
            //   // },
            //   // onSaved: (String val) {
            //   //   _shortDescription = val;
            //   // },
            // ),
          ),

          const FancyDivider(
            topMargin: 50.0,
            bottomMargin: 30.0,
            key: Key('4445103966'),
            innerColor: Colors.white,
          ),

          // TextField(
          //   controller: _accountKeyTextController,
          //   onChanged: (String value) {
          //     setStringPref(StringPrefsEnum.paymentTerminalAccountKey, value);
          //   },
          // ),
          ElevatedButton(
            child: Text('Test Login', style: headingStyle),
            onPressed: () async {
              final String affiliateKey = getStringPref(StringPrefsEnum.paymentTerminalAccountKey) ?? '';
              await Sumup.init(affiliateKey);
              await Sumup.login();
            },
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            child: Text('Open Settings', style: headingStyle),
            onPressed: () async {
              final bool isLoggedIn = await Sumup.isLoggedIn ?? false;
              if (isLoggedIn) {
                await Sumup.openSettings();
              }
            },
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            child: Text('Test SumUp transaction', style: headingStyle),
            onPressed: () async {
              final String affiliateKey = getStringPref(StringPrefsEnum.paymentTerminalAccountKey) ?? '';
              await Sumup.init(affiliateKey);

              bool isLoggedIn = await Sumup.isLoggedIn ?? false;
              if (!isLoggedIn) {
                await Sumup.login();
              }

              isLoggedIn = await Sumup.isLoggedIn ?? true;
              if (isLoggedIn) {
                await _doTransaction();
              }
            },
          ),
          // const SizedBox(height: 20.0),
          // ElevatedButton(
          //   child: Text('Wake up terminal', style: headingStyle),
          //   onPressed: () async {
          //     Sumup.isLoggedIn.then((bool isLoggedIn) async {
          //       if (isLoggedIn) {
          //         final SumupPluginResponse resp3 = await Sumup.wakeUpTerminal();
          //         int xxx = 0;
          //       }
          //     });
          //   },
          // ),
        ],
      ),
    );
  }

  void _updatePaymentTerminalInfo() {
    if (_paymentTerminalFormKey.currentState?.validate() ?? false) {
//    If all data are correct then save data to out variables
      _paymentTerminalFormKey.currentState!.save();
    }
  }

  Widget _paymentTerminalFormUi() {
    return Column(
      children: <Widget>[
        TextFormField(
          autocorrect: false,
          controller: _accountKeyTextController,
          //initialValue: getStringPref(StringPrefsEnum.paymentTerminalAccountKey) ?? '',
          decoration: const InputDecoration(labelText: 'Payment account key'),
          keyboardType: TextInputType.text,
          validator: (String? arg) {
            if ((arg ?? '').isEmpty) {
              return 'Payment account cannot be empty';
            } else {
              return null;
            }
          },
          onSaved: (String? val) {
            setStringPref(StringPrefsEnum.paymentTerminalAccountKey, val);
          },
        ),
        const SizedBox(height: 10.0),
        ElevatedButton(
          child: Text('Save account info', style: headingStyle),
          onPressed: () async {
            _updatePaymentTerminalInfo();
          },
        ),
      ],
    );
  }

  Future<void> _doTransaction() async {
    final SumupPayment payment = SumupPayment(
      title: 'Test payment 2',
      total: 1.0,
      currency: 'EUR',
      foreignTransactionId: 'Foreign trans Id',
      saleItemsCount: 0,
      skipSuccessScreen: true,
      tip: .0,
    );

    final SumupPaymentRequest request = SumupPaymentRequest(payment);

    await Sumup.checkout(request);
  }
}
