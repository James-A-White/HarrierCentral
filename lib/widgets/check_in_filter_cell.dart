import 'package:harrier_central/imports.dart';
import 'package:get/get.dart';

class CheckinFiltersCell extends StatelessWidget {
  const CheckinFiltersCell({
    super.key,
    required this.counter,
    required this.index,
    required this.label,
    required this.onTap,
    required this.filterValues,
    this.color,
    this.icon,
    this.useTriState = true,
  });

  final IconData? icon;
  final Color? color;
  final Function onTap;
  final num counter;
  final String label;
  final int index;
  final bool useTriState;
  final List<RxInt> filterValues;

  @override
  Widget build(BuildContext context) {
    //final String total = (creditAmount ?? 0) <= 0 ? '' : IveCoreUtilities.getFormattedMoney(creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    return SizedBox(
      width: 50,
      child: Column(
        children: <Widget>[
          Text(
            counter < 0 ? '' : (counter).toString(),
            style: ts_titleLargeCondensedBlack,
          ),
          Obx(
            () => IconButton(
              padding: const EdgeInsets.all(0),
              onPressed: () {
                if (index >= 0) {
                  filterValues[index].value++;
                  if (filterValues[index].value > 1) {
                    filterValues[index].value = useTriState ? -1 : 0;
                  }
                }
                onTap();
              },
              icon: Icon(
                (icon ?? filterValues[index].value) == -1
                    ? FontAwesome.times_circle
                    : filterValues[index].value == 0
                    ? FontAwesome.circle_thin
                    : FontAwesome.check_circle,
                size: 35,
                color:
                    (color ?? filterValues[index].value) == -1
                        ? hc_red
                        : filterValues[index].value == 0
                        ? Colors.grey[350]
                        : Colors.green,
              ),
            ),
          ),
          SizedBox(
            height: 20,
            child: AutoSizeText(
              label,
              style: ts_titleLargeCondensedBlack,
              maxLines: 1,
              minFontSize: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
