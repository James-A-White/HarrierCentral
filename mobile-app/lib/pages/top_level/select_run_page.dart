import 'package:harrier_central/imports.dart';

class SelectRunController extends GetxController {
  SelectRunController({required this.runList, required this.initialSelected}) {
    selected = Map.fromEntries(
      initialSelected.entries.map((e) => MapEntry(e.key, e.value.obs)),
    );
  }

  final List<AreWeAtRunModel> runList;
  late final Map<String, RxBool> selected;
  final Map<String, bool> initialSelected;

  void toggleSelection(AreWeAtRunModel item, bool isSelected) {
    selected[item.eventId]?.value = isSelected;
    initialSelected[item.eventId] = isSelected;
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
                'Tick any runs you would like to check in to. Unticked runs will be marked as not attending.',
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
                      backgroundColor: Colors.grey.shade600,
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('Cancel', style: ts_button),
                    ),
                  ),
                  const SizedBox(width: 30.0),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: button_shape,
                      backgroundColor: Colors.green.shade800,
                    ),
                    onPressed: () => Navigator.of(context).pop(controller.initialSelected),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('Save', style: ts_button),
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
