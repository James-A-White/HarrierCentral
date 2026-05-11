import 'package:harrier_central/imports.dart';

class GetPointLabelController extends GetxController {
  GetPointLabelController({this.initialValue});

  final String? initialValue;
  final RxString currentText = ''.obs;
  late final TextEditingController textController;
  late final FocusNode focusNode;

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController(text: initialValue ?? '');
    currentText.value = textController.text;
    focusNode = FocusNode();
  }

  void onChanged(String value) {
    currentText.value = value;
  }

  String get trimmed => currentText.value.trim();

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}

class GetPointLabelPopup extends StatelessWidget {
  const GetPointLabelPopup({
    super.key,
    this.title = 'Add Point Label',
    this.hintText = 'Point Label',
    this.confirmButtonText = 'Save Label',
    this.iconData = FontAwesome.money,
    this.initialValue,
    this.controllerTag,
  });

  final String title;
  final String hintText;
  final String confirmButtonText;
  final IconData iconData;
  final String? initialValue;
  final String? controllerTag;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GetPointLabelController>(
      init: GetPointLabelController(initialValue: initialValue),
      tag: controllerTag,
      builder: (controller) {
        return AlertDialog(
          title: Text(title, style: ts_alertDialogTitle),
          content: TextField(
            onChanged: controller.onChanged,
            autofocus: true,
            focusNode: controller.focusNode,
            controller: controller.textController,
            keyboardType: TextInputType.text,
            style: ts_alertDialogBody,
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(iconData, color: Colors.white),
              hintText: hintText,
              hintStyle: ts_hint,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                shape: button_shape,
                backgroundColor: hc_blue,
              ),
              child: Text('Cancel', style: ts_button),
              onPressed: () async {
                Navigator.of(context).pop(<String, String>{'label': ''});
                await Get.delete<GetPointLabelController>(tag: controllerTag);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                shape: button_shape,
                backgroundColor: hc_blue,
              ),
              child: Text(confirmButtonText, style: ts_button),
              onPressed: () async {
                Navigator.of(
                  context,
                ).pop(<String, String>{'label': controller.trimmed});
                await Get.delete<GetPointLabelController>(tag: controllerTag);
              },
            ),

            // ),
          ],
        );
      },
    );
  }
}
