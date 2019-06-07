// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// import 'package:harrier_central/data/models/lite_event_model.dart';

// import 'package:harrier_central/util/styles.dart';
// // import 'package:harrier_central/widgets/user_details_ui.dart';
// // import 'package:harrier_central/widgets/fancy_divider.dart';

// class EditEventPage extends StatefulWidget {
//   const EditEventPage({Key key, this.eventModel}) : super(key: key);



//   @override
//   EditEventPageState createState() => EditEventPageState();
// }

// class EditEventPageState extends State<EditEventPage> {
//   @override
//   void initState() {
//     super.initState();
//     eventNumberTextController = widget.eventModel.absoluteEventNumber != null
//         ? TextEditingController(
//             text: widget.eventModel.absoluteEventNumber.toString())
//         : TextEditingController();
//     eventNumberDecoration = InputDecoration(
//       hintText: widget.eventModel.eventNumber.toString(),
//       labelText: 'Run number',
//       fillColor: Colors.white,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(25.0),
//         borderSide: const BorderSide(),
//       ),
//     );
//   }

//   final FocusNode eventNumberFocusNode = FocusNode();
//   TextEditingController eventNumberTextController;
//   InputDecoration eventNumberDecoration;

//   Color hexToColor(String code) {
//     return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final AppBar appBar = AppBar(
//       centerTitle: true,
//       backgroundColor: themeAppBarBackground,
//       title: const Text(
//         'Edit run',
//         style: TextStyle(
//           color: Colors.white,
//         ),
//       ),
//     );

//     return Scaffold(
//       appBar: appBar,
//       body: Container(
//         decoration: Backgrounds.defaultHcBackground(),
//         height:
//             MediaQuery.of(context).size.height - appBar.preferredSize.height,
//         child: SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(
//                 //minHeight: viewportConstraints.maxHeight,
//                 ),
//             child: IntrinsicHeight(
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: <Widget>[
//                     // TODO(James): Bring this back eventually
//                     // UserDetailsUi(firstName: firstName, lastName: lastName, email: email, hashName: hashName,),
//                     // const FancyDivider(innerColor: Colors.white),
//                     Container(
//                       height: 250,
//                       width: MediaQuery.of(context).size.width,
//                       child: Stack(
//                         alignment: AlignmentDirectional.center,
//                         children: <Widget>[
//                           Positioned(
//                               top: 10,
//                               bottom: 20,
//                               width: MediaQuery.of(context).size.width,
//                               child: Container(
//                                 padding: const EdgeInsets.all(30.0),
//                                 color: const Color.fromARGB(255, 255, 255, 255),
//                                 child: Container(
//                                   child: Center(
//                                     child: Column(
//                                       children: <Widget> [
//                                         Padding(
//                                           padding: const EdgeInsets.only(
//                                               top: 0.0, bottom: 8.0),
//                                           child: TextFormField(
//                                             controller:
//                                                 eventNumberTextController,
//                                             focusNode: eventNumberFocusNode,
//                                             decoration: eventNumberDecoration,
//                                             // validator: (val) {
//                                             //   if (val.length == 0) {
//                                             //     return "Email cannot be empty";
//                                             //   } else {
//                                             //     return null;
//                                             //   }
//                                             // },
//                                             keyboardType: TextInputType.number,
//                                             style: const TextStyle(
//                                               fontFamily: 'Poppins',
//                                             ),
//                                           ),
//                                         ),
//                                         Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceAround,
//                                             children: <Widget>[
//                                               RaisedButton(
//                                                 onPressed: () {
//                                                   Navigator.of(context).pop(-1);
//                                                 },
//                                                 child: const Text(
//                                                   'Cancel',
//                                                   style: TextStyle(
//                                                       color: Colors.white),
//                                                 ),
//                                               ),
//                                               RaisedButton(
//                                                 onPressed: () {
//                                                   Navigator.of(context).pop(
//                                                       num.tryParse(
//                                                           eventNumberTextController
//                                                               .text));
//                                                 },
//                                                 child: const Text(
//                                                   'OK',
//                                                   style: TextStyle(
//                                                       color: Colors.white),
//                                                 ),
//                                               ),
//                                             ]),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               )),
//                         ],
//                       ),
//                     ),
//                     Container(width: 40, height: 40),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),

//       // Container(
//       //   decoration: Backgrounds.defaultHcBackground(),
//       //   child: Stack(
//       //     alignment: AlignmentDirectional.center,
//       //     children: <Widget>[
//       //       Positioned(
//       //           top: 10,
//       //           bottom: 20,
//       //           width: MediaQuery.of(context).size.width,
//       //           child: QrCodeTab()),
//       //     ],
//       //   ),
//       // ),
//     );
//   }
// }
