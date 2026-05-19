// class AddVisitorVirginPopup extends StatefulWidget {
//   const AddVisitorVirginPopup();

//   @override
//   _AddVisitorVirginPopupState createState() => _AddVisitorVirginPopupState();
// }

// class _AddVisitorVirginPopupState extends State<AddVisitorVirginPopup> {
//   final FocusNode myFocusNodeFirstName = FocusNode();

//   TextEditingController nameTextController = TextEditingController();
//   TextEditingController emailTextController = TextEditingController();
//   TextEditingController phoneTextController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Visitor or Virgin',
//   style: ts_alertDialogTitle,
// ),
//       content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
//         TextField(
//           autofocus: true,
//           focusNode: myFocusNodeFirstName,
//           controller: nameTextController,
//           keyboardType: TextInputType.text,
//           style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
//           decoration: const InputDecoration(
//             //border: InputBorder.none,
//             icon: Icon(
//               FontAwesome.money,
//               color: Colors.white,
//             ),
//             hintText: 'Just Julie',
//             hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
//           ),
//         ),
//         TextField(
//           autofocus: true,
//           //focusNode: myFocusNodeFirstName,
//           controller: emailTextController,
//           keyboardType: TextInputType.emailAddress,
//           style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
//           decoration: const InputDecoration(
//             //border: InputBorder.none,
//             icon: Icon(
//               FontAwesome.money,
//               color: Colors.white,
//             ),
//             hintText: '(email - optional)',
//             hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
//           ),
//         ),
//         TextField(
//           autofocus: true,
//           //focusNode: myFocusNodeFirstName,
//           controller: phoneTextController,
//           keyboardType: TextInputType.phone,
//           style: const TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0, color: Colors.black),
//           decoration: const InputDecoration(
//             //border: InputBorder.none,
//             icon: Icon(
//               FontAwesome.money,
//               color: Colors.white,
//             ),
//             hintText: '(phone # - optional)',
//             hintStyle: TextStyle(fontFamily: 'WorkSansSemiBold', fontSize: 16.0),
//           ),
//         ),
//       ]),
//       actions: <Widget>[
//                     TextButton(
//           color:hc_red,
//           child: const Text('Cancel'),
//           textColor: Colors.white,
//           onPressed: () {
//             Navigator.of(context).pop(<String, String>{'type': 'cancel', 'amount': ''});
//           },
//         ),

//                     TextButton(
//             color: hc_blue,
//             child: const Text('Add Visitor'),
//             textColor: Colors.white,
//             onPressed: () {
//               Navigator.of(context).pop(<String, String>{
//                 'type': enumAnonymousVisitor.value.toString(),
//                 'name': nameTextController.text,
//                 'email': emailTextController.text,
//                 'phone': phoneTextController.text,
//               });
//             }),

//                     TextButton(

//             color: hc_blue,
//             child: const Text('Add Virgin'),
//             textColor: Colors.white,
//             onPressed: () {
//               Navigator.of(context).pop(<String, String>{
//                 'type': enumVirgin.value.toString(),
//                 'name': nameTextController.text,
//                 'email': emailTextController.text,
//                 'phone': phoneTextController.text,
//               });
//             }),
//         // ),
//       ],
//     );
//   }
// }
