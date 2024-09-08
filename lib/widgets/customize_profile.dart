import 'package:harrier_central/imports.dart';
// import 'package:intl/intl.dart';

class CustomizeProfile extends StatefulWidget {
  const CustomizeProfile({
    super.key,
    required this.originalProfilePhoto,
    required this.originalDisplayName,
    this.customKennelPhoto,
    this.customKennelHashName,
  });

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
            Text(widget.originalDisplayName, style: ts_titleLarge),
            Text(widget.originalProfilePhoto, style: ts_titleLarge),
            Text(widget.customKennelHashName ?? '', style: ts_titleLarge),
            Text(widget.customKennelPhoto ?? '', style: ts_titleLarge),
          ],
        ));
  }
}
