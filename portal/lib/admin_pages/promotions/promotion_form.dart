// import 'package:hcportal/imports.dart';

// class PromotionForm extends GetView<PromotionController> {
//   const PromotionForm({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final PromotionController c = Get.put(PromotionController());

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
//                       children: _promoFormWidgets(c, true, context),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: _promoFormWidgets(c, false, context),
//                     ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _promoFormWidgets(PromotionController c, bool horizontal, BuildContext context) {
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
//                 'Promotion Details',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 200.0,
//               child: TextFormField(
//                 controller: c.promoNameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Promo name',
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
//                 keyboardType: TextInputType.number,
//                 controller: c.promoDisplayTimeInMs,
//                 decoration: const InputDecoration(
//                   labelText: 'Display time (in ms)',
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)),
//                 ),
//               ),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             // ElevatedButton(
//             //   onPressed: c.onConnectToSession,
//             //   child: const Text('Connect to Session'),
//             // ),
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
//               height: 10,
//               width: 10,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.black,
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
//                 '',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: 200.0,
//               child: TextFormField(
//                 onTap: () async {
//                   DateTime? picked = await showDatePicker(
//                       context: context,
//                       initialDate: c.promoStartDate, //get today's date
//                       firstDate: DateTime.now().add(const Duration(days: -1)), // - not to allow to choose before today.
//                       lastDate: DateTime(2050));
//                   //FocusScope.of(context).requestFocus(FocusNode());
//                   // final DateTime? picked = await showDatePicker(
//                   //   context: context,
//                   //   initialDate: c.promoStartDate,
//                   //   firstDate: DateTime(2023, 1, 1),
//                   //   lastDate: DateTime(2030, 12, 31),
//                   // );
//                   if (picked != null && picked != c.promoStartDate) {
//                     c.promoStartDate = picked;
//                     c.startDateController.text = picked.toString();
//                   }
//                 },
//                 //initialValue: c.promoStartDate.toString(),
//                 controller: c.startDateController,
//                 decoration: const InputDecoration(
//                   labelText: 'Start date',
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
//                 onTap: () async {
//                   DateTime? picked = await showDatePicker(
//                       context: context,
//                       initialDate: c.promoEndDate, //get today's date
//                       firstDate: DateTime.now().add(const Duration(days: -1)), // - not to allow to choose before today.
//                       lastDate: DateTime(2050));
//                   //FocusScope.of(context).requestFocus(FocusNode());
//                   // final DateTime? picked = await showDatePicker(
//                   //   context: context,
//                   //   initialDate: c.promoStartDate,
//                   //   firstDate: DateTime(2023, 1, 1),
//                   //   lastDate: DateTime(2030, 12, 31),
//                   // );
//                   if (picked != null && picked != c.promoEndDate) {
//                     c.promoEndDate = picked;
//                     c.endDateController.text = picked.toString();
//                   }
//                 },
//                 //initialValue: c.promoEndDate.toString(),
//                 controller: c.endDateController,
//                 decoration: const InputDecoration(
//                   labelText: 'End date',
//                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );

//     return widgets;
//   }
// }
