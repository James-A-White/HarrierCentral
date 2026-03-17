import 'package:hcportal/imports.dart';

class RegisterVirginPage extends StatefulWidget {
  const RegisterVirginPage({super.key});

  @override
  RegisterVirginPageState createState() => RegisterVirginPageState();
}

class RegisterVirginPageState extends State<RegisterVirginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harrier Central'),
      ),
      body: Container(color: Colors.purple.shade900),
    );
  }
}
