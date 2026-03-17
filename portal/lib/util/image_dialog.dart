import 'package:hcportal/imports.dart';

class ImageDialog extends StatelessWidget {
  const ImageDialog({
    required this.userPhoto, super.key,
  });

  final String userPhoto;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
            image: DecorationImage(
          image: NetworkImage(userPhoto),
          fit: BoxFit.cover,
        ),),
      ),
    );
  }
}
