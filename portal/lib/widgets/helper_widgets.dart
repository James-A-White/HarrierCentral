import 'package:hcportal/imports.dart';

class HelperWidgets {
  Widget chipsWidget(
    String widgetName,
    RxList<int> values,
    RxMap<String, int> group,
    dynamic formController,
  ) {
    return Obx(
      () => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: group.entries.map((MapEntry<String, dynamic> entry) {
          final isSelected = values.contains(entry.value);
          return FilterChip(
            label: Text(entry.key, style: bodyStyleBlack),
            selected: isSelected,
            selectedColor: Colors.green.shade100,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? Colors.green : Colors.grey,
                width: isSelected ? 1 : 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (bool selected) {
              if (selected) {
                if (!values.contains(entry.value)) {
                  values.add(entry.value as int);
                }
              } else {
                if (values.contains(entry.value)) {
                  values.remove(entry.value);
                }
              }
              // ignore: avoid_dynamic_calls
              formController.updateSelectedChips(
                values,
                group.values.toList(),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget categoryLabelWidget(
    String label, {
    double bottomMargin = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(
            top: 20,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'AvenirNextBold',
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Divider(thickness: 3, color: Colors.deepOrange.shade100),
        SizedBox(height: bottomMargin),
      ],
    );
  }
}
