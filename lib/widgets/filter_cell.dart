import 'package:harrier_central/imports.dart';

class CheckinFiltersCell extends StatelessWidget {
  const CheckinFiltersCell({
    Key? key,
    required this.counter,
    required this.index,
    required this.label,
    required this.onTap,
    required this.filterValues,
    this.color,
    this.icon,
    this.useTriState = true,
  }) : super(key: key);

  final IconData? icon;
  final Color? color;
  final Function onTap;
  final num counter;
  final String label;
  final int index;
  final bool useTriState;
  final List<int> filterValues;

  @override
  Widget build(BuildContext context) {
    //final String total = (creditAmount ?? 0) <= 0 ? '' : IveCoreUtilities.getFormattedMoney(creditAmount ?? 0, digitsAfterDecimal, currencySymbol);

    const TextStyle textStyle = TextStyle(color: Colors.black, fontSize: 24.0, fontFamily: 'AvenirNextCondensedDemiBold');
    return SizedBox(
      width: 50,
      child: Column(
        children: <Widget>[
          Text(
            counter < 0 ? '' : (counter).toString(),
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
            icon: Icon(
                (icon ?? filterValues[index]) == -1
                    ? FontAwesome.times_circle
                    : filterValues[index] == 0
                        ? FontAwesome.circle_thin
                        : FontAwesome.check_circle,
                size: 35,
                color: (color ?? filterValues[index]) == -1
                    ? Colors.red
                    : filterValues[index] == 0
                        ? Colors.grey[350]
                        : Colors.green),
          ),
          SizedBox(
            height: 20,
            child: AutoSizeText(
              label,
              style: textStyle,
              maxLines: 1,
              minFontSize: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
