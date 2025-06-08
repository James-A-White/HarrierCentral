import 'package:harrier_central/imports.dart';

class AddVisitorVirginPopup extends StatefulWidget {
  const AddVisitorVirginPopup({super.key});

  @override
  AddVisitorVirginPopupState createState() => AddVisitorVirginPopupState();
}

class AddVisitorVirginPopupState extends State<AddVisitorVirginPopup> {
  final FocusNode myFocusNodeFirstName = FocusNode();

  TextEditingController nameTextController = TextEditingController();
  TextEditingController emailTextController = TextEditingController();
  TextEditingController phoneTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextScaleFactorClamper(
      textScaleFactor: G0<DeviceInfo>().textClamp25,
      child: AlertDialog(
        title: Text('Add Visitor or Virgin', style: ts_alertDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              autofocus: true,
              focusNode: myFocusNodeFirstName,
              controller: nameTextController,
              keyboardType: TextInputType.text,
              style: ts_alertDialogBody,
              decoration: InputDecoration(
                //border: InputBorder.none,
                icon: const Icon(
                  MaterialCommunityIcons.run,
                  color: Colors.black,
                ),
                hintText: 'Just Julie',
                hintStyle: ts_hint,
              ),
            ),
            TextField(
              autofocus: true,
              //focusNode: myFocusNodeFirstName,
              controller: emailTextController,
              keyboardType: TextInputType.emailAddress,
              style: ts_titleMediumBlack,
              decoration: InputDecoration(
                //border: InputBorder.none,
                icon: const Icon(
                  MaterialCommunityIcons.email,
                  color: Colors.black,
                ),
                hintText: '(email - optional)',
                hintStyle: ts_hint,
              ),
            ),
            TextField(
              autofocus: true,
              //focusNode: myFocusNodeFirstName,
              controller: phoneTextController,
              keyboardType: TextInputType.phone,
              style: ts_titleMediumBlack,
              decoration: InputDecoration(
                //border: InputBorder.none,
                icon: const Icon(Entypo.old_phone, color: Colors.black),
                hintText: '(phone # - optional)',
                hintStyle: ts_hint,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          SizedBox(
            height: 55,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: button_shape,
                backgroundColor: hc_red,
              ),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
                //textScaleFactor: G0<DeviceInfo>().textClamp15,
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(<String, String>{'type': 'cancel', 'amount': ''});
              },
            ),
          ),

          SizedBox(
            height: 55.0,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: button_shape,
                backgroundColor: hc_blue,
              ),
              child: const Text(
                'Add\r\nVisitor',
                textAlign: TextAlign.center,
                //textScaleFactor: G0<DeviceInfo>().textClamp15,
              ),
              onPressed: () {
                Navigator.of(context).pop(<String, String>{
                  'type': enumAnonymousVisitor.value.toString(),
                  'name': nameTextController.text,
                  'email': emailTextController.text,
                  'phone': phoneTextController.text,
                });
              },
            ),
          ),

          SizedBox(
            height: 55.0,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: button_shape,
                backgroundColor: hc_blue,
              ),
              child: const Text(
                'Add\r\nVirgin',
                textAlign: TextAlign.center,
                //textScaleFactor: G0<DeviceInfo>().textClamp15,
              ),
              onPressed: () {
                Navigator.of(context).pop(<String, String>{
                  'type': enumVirgin.value.toString(),
                  'name': nameTextController.text,
                  'email': emailTextController.text,
                  'phone': phoneTextController.text,
                });
              },
            ),
          ),
          // ),
        ],
      ),
    );
  }
}
