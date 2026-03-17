// import 'package:hcportal/imports.dart';
// import 'package:get/get.dart';

// class LoginForm extends GetView<LoginController> {
//   const LoginForm({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final LoginController c = Get.put(LoginController());

//     final num height = MediaQuery.of(context).size.height;
//     final num width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       body: Center(
//         child: SingleChildScrollView(
//           scrollDirection: width < height ? Axis.vertical : Axis.horizontal,
//           child: FocusTraversalGroup(
//             policy: OrderedTraversalPolicy(),
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: width < height
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: _loginWidgets(c, true, context),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: _loginWidgets(c, false, context),
//                     ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _loginWidgets(LoginController c, bool horizontal, BuildContext context) {
//     List<Widget> widgets = <Widget>[];

//     widgets.add(
//       FocusTraversalOrder(
//         order: const NumericFocusOrder(1),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Padding(
//               padding: EdgeInsets.only(bottom: 18.0),
//               child: Text(
//                 'Connect to Existing Session',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 200.0,
//               child: TextFormField(
//                 controller: c.sessionCodeController,
//                 decoration: const InputDecoration(
//                   labelText: 'Enter session code',
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)),
//                 ),
//               ),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             SizedBox(
//               width: 200.0,
//               child: TextFormField(
//                 controller: c.abbreviation1Controller,
//                 decoration: const InputDecoration(
//                   labelText: 'Enter role (6 char max)',
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)),
//                 ),
//               ),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             ElevatedButton(
//               onPressed: c.onConnectToSession,
//               child: const Text('Connect to Session'),
//             ),
//           ],
//         ),
//       ),
//     );

//     widgets.add(
//       Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Stack(
//           alignment: AlignmentDirectional.center,
//           children: <Widget>[
//             horizontal
//                 ? const Divider(
//                     height: 30.0,
//                     thickness: 1.0,
//                     color: Colors.black,
//                   )
//                 : const VerticalDivider(width: 30.0, thickness: 1.0, color: Colors.black),
//             Container(
//               height: 30,
//               width: 30,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.black,
//               ),
//               child: const Padding(
//                 padding: EdgeInsets.only(bottom: 2.0),
//                 child: Center(child: Text('or', style: TextStyle(color: Colors.white))),
//               ),
//             )
//           ],
//         ),
//       ),
//     );

//     widgets.add(
//       FocusTraversalOrder(
//         order: const NumericFocusOrder(2),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Padding(
//               padding: EdgeInsets.only(bottom: 18.0),
//               child: Text(
//                 'Create New Session',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 200.0,
//               child: TextFormField(
//                 controller: c.abbreviation2Controller,
//                 decoration: const InputDecoration(
//                   labelText: 'Enter role (6 char max)',
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)),
//                 ),
//               ),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             ElevatedButton(
//               onPressed: c.onCreateNewSession,
//               child: const Text('Create New Session'),
//             ),
//           ],
//         ),
//       ),
//     );

//     return widgets;
//   }
// }
