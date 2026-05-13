import 'package:harrier_central/imports.dart';

class SelectRunController extends GetxController {
  SelectRunController({required this.runList, required this.initialSelected}) {
    // Convert incoming Map<String, bool> to Map<String, RxBool>
    selected = Map.fromEntries(
      initialSelected.entries.map((e) => MapEntry(e.key, e.value.obs)),
    );
  }

  final List<AreWeAtRunModel> runList;
  late final Map<String, RxBool> selected;
  final Map<String, bool> initialSelected;

  final RxBool showCheckinButton = false.obs;

  void toggleSelection(AreWeAtRunModel item, bool isSelected) {
    // set the state for the UI
    selected[item.eventId]?.value = isSelected;
    // set the state that will be passed back to the caller
    initialSelected[item.eventId] = isSelected;

    showCheckinButton.value = selected.values.any((value) => value.value);
  }
}

class SelectRunPage extends StatelessWidget {
  const SelectRunPage({
    super.key,
    required this.runList,
    required this.selected,
  });

  final List<AreWeAtRunModel> runList;
  final Map<String, bool> selected;

  @override
  Widget build(BuildContext context) {
    // TODO(S6): ensure Get.delete<SelectRunController>() is called when this page closes.
    final controller = Get.put(
      SelectRunController(runList: runList, initialSelected: selected),
    );

    return AppScaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: themeAppBarBackground,
        iconTheme: const IconThemeData(color: Colors.white, size: 28.0),
        title: Text('Select run', style: ts_appBarTitle),
      ),
      body: Container(
        decoration: Backgrounds.defaultHcBackgroundLight(),
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Text(
                'Would you like to check in to any of the below runs?',
                style: ts_titleLargeBlack.copyWith(height: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color.fromARGB(70, 0, 0, 0),
                    offset: Offset(0.0, 10.0),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: button_shape,
                      textStyle: TextStyle(color: Colors.grey.shade700),
                      backgroundColor: hc_red,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('Don\'t check in', style: ts_button),
                    ),
                  ),
                  const SizedBox(width: 30.0),
                  Obx(
                    () => TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.disabled)) {
                              return Colors.grey.shade700;
                            }
                            return Colors.green.shade800;
                          },
                        ),
                      ),
                      onPressed: controller.showCheckinButton.value
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text('Check in', style: ts_button),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 50),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: runList.length,
                itemBuilder: (context, index) {
                  final run = runList[index];
                  //final isSelected = selected[run.eventId] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: <Widget>[
                        KennelLogo(
                          kennelId: run.kennelId,
                          kennelLogoUrl: run.kennelLogo,
                          kennelShortName: run.kennelShortName,
                          logoHeight: 45.0,
                        ),
                        Expanded(
                          child: Obx(
                            () => CheckboxListTile(
                              value:
                                  controller.selected[run.eventId]?.value ??
                                  false,
                              title: Text(run.eventName),
                              onChanged: (bool? value) {
                                controller.toggleSelection(run, value ?? false);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
