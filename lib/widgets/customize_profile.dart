import 'package:harrier_central/imports.dart';
// import 'package:intl/intl.dart';

class CustomizeProfile extends StatefulWidget {
  const CustomizeProfile({
    Key? key,
    required this.originalProfilePhoto,
    required this.originalDisplayName,
    this.customKennelPhoto,
    this.customKennelHashName,
  }) : super(key: key);

  final String originalProfilePhoto;
  final String originalDisplayName;
  final String? customKennelPhoto;
  final String? customKennelHashName;

  @override
  CustomizeProfileState createState() => CustomizeProfileState();
}

class CustomizeProfileState extends State<CustomizeProfile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.deepOrange.shade900,
        child: Column(
          children: [
            Text(widget.originalDisplayName, style: titleStyle),
            Text(widget.originalProfilePhoto, style: titleStyle),
            Text(widget.customKennelHashName ?? '', style: titleStyle),
            Text(widget.customKennelPhoto ?? '', style: titleStyle),
          ],
        ));
  }
}
