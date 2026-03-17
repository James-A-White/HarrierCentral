import 'package:hcportal/imports.dart';

/// Renders children in a Row or Column based on [isRow].
/// When in Row mode, applies flex and left padding from the provided lists.
class RowColumn extends StatelessWidget {
  const RowColumn({
    required this.isRow,
    required this.children,
    this.rowFlexValues = const [],
    this.rowLeftPaddingValues = const [],
    super.key,
  });

  final bool isRow;
  final List<Widget> children;
  final List<int> rowFlexValues;
  final List<double> rowLeftPaddingValues;

  @override
  Widget build(BuildContext context) {
    if (!isRow) return Column(children: children);

    return Row(
      children: [
        for (int i = 0; i < children.length; i++)
          Flexible(
            flex: i < rowFlexValues.length ? rowFlexValues[i] : 1,
            child: Padding(
              padding: EdgeInsets.only(
                left: i < rowLeftPaddingValues.length
                    ? rowLeftPaddingValues[i]
                    : 0.0,
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}
