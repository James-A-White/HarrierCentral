// // ignore_for_file: sort_child_properties_last

// import 'package:file_picker/file_picker.dart';
// import 'package:image/image.dart' as image;

// import 'package:http/http.dart' as http;

// import 'package:hcportal/imports.dart';
// import 'package:hcportal/models/promotions/promotions_model.dart';

// class PromotionPage extends StatefulWidget {
//   const PromotionPage(this.argsMap, {super.key});

//   final Map<String, dynamic> argsMap;
//   @override
//   PromotionPageState createState() => PromotionPageState();
// }

// class PromotionPageState extends State<PromotionPage> with TickerProviderStateMixin {
//   PromotionsModel _promotion = PromotionsModel.empty();

//   List<bool> _checkboxValues = <bool>[];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(
//       length: 3,
//       vsync: this,
//     );
//     _tabController!.addListener(() {
//       setState(() {});
//     });
//     _promotion = widget.argsMap['promotionModel']! as PromotionsModel;

//     List<int> lint = _promotion.promoOverlayTiming.split(',').map(int.parse).toList();

//     _checkboxValues = List<bool>.generate(20, (index) {
//       if ((index == 0) || (lint.contains(index))) {
//         return true;
//       }
//       return false;
//     });
//   }

//   // AzurePlace? _azurePlaceSearchResults;
//   // bool _autoNumberRuns = true;
//   final bool _isAddMode = false;
//   bool _isProcessing = false;
//   // bool _limitParticipation = false;
//   // bool _useCustomPricing = false;
//   // bool _useExtImage = false;
//   // bool _useExtLatLon = false;
//   // bool _useExtLocation = false;
//   // bool _useExtrasPricing = false;
//   // bool _useExtRunDetails = false;
//   // bool _uploadingPhoto = false;
//   // double _scaleStart = 1.0;
//   final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
//   // final List<int> _tagIdList = <int>[];
//   // geo_map.MapController? _mapController;
//   // //geo_map.MapTransformer? _transformer;
//   // int _absoluteRunNumber = 0;
//   // int _inboundIntegrationId = 0;
//   // int _searchDisplayIndex = 0;
//   // Offset? _dragStart;

//   // String? _uploadedImage;

//   String? _uploadedImage;
//   bool _uploadingPhoto = false;

//   TabController? _tabController;

//   // final TextStyle _runTagsTextStyle = const TextStyle(
//   //   fontFamily: 'AvenirNextBold',
//   //   color: Colors.white,
//   //   fontWeight: FontWeight.bold,
//   //   fontSize: 16.0,
//   // );
//   // final TextStyle _labelStyle = const TextStyle(
//   //   fontSize: 18.0,
//   // );
//   // final TextStyle _contentStyle = const TextStyle(
//   //   fontSize: 16.0,
//   // );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Promotions'),
//         leading: GestureDetector(
//           onTap: () {
//              Get.back();
//           },
//           child: const Icon(MaterialCommunityIcons.arrow_left, color: Colors.black),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8.0),
//           //color: _backgroundColor == null ? Colors.transparent : HexColor(_backgroundColor!),
//           color: Colors.white,
//           border: Border.all(
//             color: Colors.blue.shade800,
//             width: 2.0, //                   <--- border width here
//           ),
//         ),
//         margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
//         padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
//         child: Column(
//           children: <Widget>[
//             Expanded(
//               child: FormBuilder(
//                 key: _formKey,
//                 autovalidateMode: AutovalidateMode.onUserInteraction,
//                 child: Column(
//                   children: <Widget>[
//                     Container(
//                       color: Colors.blue.shade600,
//                       padding: const EdgeInsets.only(top: 10.0),
//                       child: TabBar(
//                         controller: _tabController,
//                         labelColor: Colors.redAccent,
//                         unselectedLabelColor: Colors.white,
//                         indicatorSize: TabBarIndicatorSize.label,
//                         indicator: const BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)), color: Colors.white),
//                         tabs: <Tab>[
//                           _myTabWidget('Basic info'),
//                           _myTabWidget('Images'),
//                           _myTabWidget('Empty'),
//                           // _myTabWidget('Image'),
//                           // _myTabWidget('Miscellaneous'),
//                           // _myTabWidget('Run tags'),
//                           // _myTabWidget('Payment'),
//                           // _myTabWidget('Other'),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: IndexedStack(
//                         alignment: AlignmentDirectional.topCenter,
//                         sizing: StackFit.expand,
//                         index: _tabController?.index ?? 0,
//                         children: <Widget>[
//                           _tabBasicInfo(),
//                           _tabEventImage(),
//                           _tabEmpty(),
//                           // _tabLocationInfo(),
//                           // _tabEventImage(),
//                           // _tabMiscInfo(),
//                           // _tabEventTags(),
//                           // _tabPayment(),
//                           // _tabOtherInfo(),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const Divider(
//               color: Colors.grey,
//               thickness: 1.0,
//               height: 1.0,
//             ),
//             const SizedBox(height: 15.0),
//             ElevatedButton(
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all<Color>(_isProcessing ? Colors.grey.shade500 : Colors.red.shade900),
//                 foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
//               ),
//               onPressed: () async {
//                 _formKey.currentState?.save();
//                 if (_formKey.currentState?.validate() ?? false) {
//                   setState(() {
//                     _isProcessing = true;
//                   });
//                   final Map<String, dynamic> changes = <String, dynamic>{};

//                   //     _updateChangedFieldCheckbox(changes, 'use_external_data_for_basic_info', 'useFbRunDetails', _rdm.useFbRunDetails);
//                   //     _updateChangedFieldCheckbox(changes, 'use_external_data_for_run_location', 'useFbLocation', _rdm.useFbLocation);
//                   //     _updateChangedFieldCheckbox(changes, 'use_external_data_for_run_latlong', 'useFbLatLon', _rdm.useFbLatLon);
//                   //     _updateChangedFieldCheckbox(changes, 'use_external_data_for_event_image', 'useFbImage', _rdm.useFbImage);

//                   _updateChangedField(changes, 'promo_name', 'promoName', _promotion.promoName);

//                   _updateChangedField(changes, 'promo_start_date', 'promoStartDate', _promotion.promoStartDate);

//                   _updateChangedField(changes, 'promo_end_date', 'promoEndDate', _promotion.promoEndDate);

//                   List<String> timingList = List<String>.generate(20, (index) {
//                     if (_checkboxValues[index] && index != 0) {
//                       return index.toString();
//                     }
//                     return '';
//                   });

//                   timingList.removeWhere((item) => item == '');
//                   if (timingList.join(',') != _promotion.promoOverlayTiming) {
//                     changes['promoOverlayTiming'] = timingList.join(',');
//                   }

//                   //     _updateChangedFieldCheckbox(changes, 'is_visible', 'isVisible', _rdm.isVisible);
//                   //     _updateChangedFieldCheckbox(changes, 'is_counted', 'isCountedRun', _rdm.isCountedRun);
//                   //     _updateChangedFieldCheckbox(changes, 'is_promoted', 'isPromotedEvent', _rdm.isPromotedEvent);

//                   //     if (_isAddMode || (_formKey.currentState?.fields['auto_number']!.value != (_rdm.absoluteEventNumber == null))) {
//                   //       if (_formKey.currentState?.fields['auto_number']!.value ?? true) {
//                   //         changes['absoluteEventNumber'] = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //       } else {
//                   //         changes['absoluteEventNumber'] = _formKey.currentState?.fields['absolute_run_number']!.value;
//                   //       }
//                   //     }

//                   if (_uploadedImage != null) {
//                     changes['promoImage'] = _uploadedImage;
//                   }

//                   //     _updateChangedFieldString(changes, 'hares', 'hares', _rdm.hares);

//                   //     if (_isAddMode || (SPECIAL_EVENT_STRINGS[_formKey.currentState?.fields['geographic_scope']!.value] != _rdm.eventGeographicScope)) {
//                   //       changes['eventGeographicScope'] = SPECIAL_EVENT_STRINGS[_formKey.currentState?.fields['geographic_scope']!.value];
//                   //     }

//                   //     final int? dissHrdoKey = HASH_RUNS_DOT_ORG_SETTINGS.keys
//                   //         .firstWhere((int? k) => HASH_RUNS_DOT_ORG_SETTINGS[k] == _formKey.currentState?.fields['publish_on_hashruns']!.value, orElse: () => null);

//                   //     if (dissHrdoKey != null) {
//                   //       if (_isAddMode || (dissHrdoKey != _rdm.evtDisseminateHashRunsDotOrg)) {
//                   //         changes['evtDisseminateHashRunsDotOrg'] = dissHrdoKey;
//                   //       }
//                   //     }

//                   //     final int? runAudienceKey =
//                   //         RUN_AUDIENCE.keys.firstWhere((int? k) => RUN_AUDIENCE[k] == _formKey.currentState?.fields['run_audience']!.value, orElse: () => null);

//                   //     if (runAudienceKey != null) {
//                   //       if (_isAddMode || (runAudienceKey != _rdm.evtDisseminationAudience)) {
//                   //         changes['evtDisseminationAudience'] = runAudienceKey;
//                   //       }
//                   //     }

//                   //     if (_isAddMode || (SPECIAL_EVENT_STRINGS[_formKey.currentState?.fields['allow_web_link']!.value] != _rdm.eventGeographicScope)) {
//                   //       changes['evtDisseminateAllowWebLinks'] = YES_NO_INHERIT[_formKey.currentState?.fields['allow_web_link']!.value];
//                   //     }

//                   //     // if (_isAddMode || (SPECIAL_EVENT_STRINGS[_formKey.currentState?.fields['geographic_scope']!.value] != _rdm.eventGeographicScope)) {
//                   //     //   changes['eventGeographicScope'] = SPECIAL_EVENT_STRINGS[_formKey.currentState?.fields['geographic_scope']!.value];
//                   //     // }

//                   //     int? runAttendence = CAN_EDIT_RUN_ATTENDENCE_STRINGS[_formKey.currentState?.fields['run_attendence']!.value];
//                   //     if (runAttendence == 2) {
//                   //       runAttendence = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //     }
//                   //     if (_isAddMode || (runAttendence != _rdm.canEditRunAttendence)) {
//                   //       changes['canEditRunAttendence'] = runAttendence;
//                   //     }

//                   //     if (_formKey.currentState?.fields['auto_import'] != null) {
//                   //       if (_formKey.currentState?.fields['auto_import']!.value != (_rdm.integrationEnabled != 0)) {
//                   //         changes['integrationEnabled'] = _formKey.currentState?.fields['auto_import']!.value ? 1 : 0;
//                   //       }
//                   //     } else {
//                   //       if (_isAddMode || (_rdm.integrationEnabled != 0)) {
//                   //         changes['integrationEnabled'] = 0;
//                   //       }
//                   //     }

//                   //     if (!(_formKey.currentState?.fields['use_external_data_for_run_location']?.value ?? false)) {
//                   //       _updateChangedFieldString(changes, 'street', 'locationStreet', _rdm.locationStreet);
//                   //       _updateChangedFieldString(changes, 'postcode', 'locationPostCode', _rdm.locationPostCode);
//                   //       _updateChangedFieldString(changes, 'city', 'locationCity', _rdm.locationCity);
//                   //       // _updateChangedFieldString(changes, 'sub_region',
//                   //       //     'locationSubRegion', _rdm.locationSubRegion);
//                   //       _updateChangedFieldString(changes, 'region', 'locationRegion', _rdm.locationRegion);
//                   //       _updateChangedFieldString(changes, 'country', 'locationCountry', _rdm.locationCountry);
//                   //     }

//                   //     if ((_formKey.currentState?.fields['lat']?.value != null) && (_formKey.currentState?.fields['lon']?.value != null)) {
//                   //       if (_isAddMode || (!(_formKey.currentState?.fields['use_external_data_for_run_latlong']?.value ?? false))) {
//                   //         _updateChangedFieldDoubleWithInvalidValue(changes, 'lat', 'latitude', _rdm.hcLatitude, '-99.0');
//                   //         _updateChangedFieldDoubleWithInvalidValue(changes, 'lon', 'longitude', _rdm.hcLongitude, '-999.0');
//                   //       }
//                   //     }

//                   //     final List<int> flags = _formKey.currentState?.fields['run_tags_theme']!.value +
//                   //         _formKey.currentState?.fields['run_tags_restrictions']!.value +
//                   //         _formKey.currentState?.fields['run_tags_what_to_bring']!.value +
//                   //         _formKey.currentState?.fields['run_tags_run_type']!.value +
//                   //         _formKey.currentState?.fields['run_tags_terrain']!.value +
//                   //         _formKey.currentState?.fields['run_tags_hares']!.value +
//                   //         _formKey.currentState?.fields['run_tags_other']!.value;

//                   //     int tags1 = 0;
//                   //     int tags2 = 0;
//                   //     int tags3 = 0;

//                   //     for (int i = 0; i < flags.length; i++) {
//                   //       final int flag = flags[i];
//                   //       if (flag ~/ 4294967296 == 1) {
//                   //         tags1 += flag & 0x7fffffff;
//                   //       } else if (flag ~/ 4294967296 == 2) {
//                   //         tags2 += flag & 0x7fffffff;
//                   //       } else if (flag ~/ 4294967296 == 4) {
//                   //         tags3 += flag & 0x7fffffff;
//                   //       }
//                   //     }

//                   //     if (_isAddMode || (tags1 != _rdm.tags1)) {
//                   //       changes['tags1'] = tags1;
//                   //     }

//                   //     if (_isAddMode || (tags2 != _rdm.tags2)) {
//                   //       changes['tags2'] = tags2;
//                   //     }

//                   //     if (_isAddMode || (tags3 != _rdm.tags3)) {
//                   //       changes['tags3'] = tags3;
//                   //     }

//                   //     // no add mode check needed here because this is a nullable field
//                   //     if (_formKey.currentState?.fields['save_run_tags_as_kennel_default']!.value ?? false) {
//                   //       changes['saveTagsAsKennelDefault'] = 1;
//                   //     }

//                   //     // no add mode check needed here because this is a nullable field
//                   //     if (_formKey.currentState?.fields['run_end_date']!.value != _rdm.eventEndDatetime) {
//                   //       changes['endDatetime'] = (_formKey.currentState?.fields['run_end_date']!.value as DateTime).toIso8601String();
//                   //     }

//                   //     // no add mode check needed here because this is a nullable field
//                   //     if (_formKey.currentState?.fields['limit_participation']?.value ?? false) {
//                   //       _updateChangedNumericField(changes, 'limit_participation', _rdm.minimumParticipantsRequired, 'minimum_participation', 'minimumParticipantsRequired',
//                   //           valueToUpdateDbToNull: SET_DB_NUMERIC_FIELD_TO_NULL);

//                   //       _updateChangedNumericField(changes, 'limit_participation', _rdm.maximumParticipantsAllowed, 'maximum_participation', 'maximumParticipantsAllowed',
//                   //           valueToUpdateDbToNull: SET_DB_NUMERIC_FIELD_TO_NULL);
//                   //     } else {
//                   //       if (_rdm.maximumParticipantsAllowed != null) {
//                   //         changes['maximumParticipantsAllowed'] = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //       }

//                   //       if (_rdm.minimumParticipantsRequired != null) {
//                   //         changes['minimumParticipantsRequired'] = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //       }
//                   //     }

//                   //     // no add mode check needed here because this is a nullable field
//                   //     if (_formKey.currentState?.fields['use_custom_prices']?.value ?? false) {
//                   //       _updateChangedNumericField(changes, 'use_custom_prices', _rdm.eventPriceForMembers, 'member_price', 'eventPriceForMembers',
//                   //           valueToUpdateDbToNull: SET_DB_NUMERIC_FIELD_TO_NULL);

//                   //       _updateChangedNumericField(changes, 'use_custom_prices', _rdm.eventPriceForNonMembers, 'non_member_price', 'eventPriceForNonMembers',
//                   //           valueToUpdateDbToNull: SET_DB_NUMERIC_FIELD_TO_NULL);
//                   //     } else {
//                   //       if (_rdm.eventPriceForMembers != null) {
//                   //         changes['eventPriceForMembers'] = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //       }

//                   //       if (_rdm.eventPriceForNonMembers != null) {
//                   //         changes['eventPriceForNonMembers'] = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //       }
//                   //     }

//                   //     // no add mode check needed here because this is a nullable field
//                   //     if (_formKey.currentState?.fields['use_extras_prices']?.value ?? false) {
//                   //       _updateChangedNumericField(changes, 'use_extras_prices', _rdm.eventPriceForExtras, 'extras_price', 'eventPriceForExtras',
//                   //           valueToUpdateDbToNull: SET_DB_NUMERIC_FIELD_TO_NULL);

//                   //       _updateChangedStringFieldWithCheckbox(changes, 'use_extras_prices', _rdm.extrasDescription, 'extras_description', 'extrasDescription',
//                   //           valueToUpdateDbToNull: SET_DB_STRING_FIELD_TO_NULL);

//                   //       if (_formKey.currentState?.fields['extras_rsvp_required']!.value != (_rdm.extrasRsvpRequired != 0)) {
//                   //         changes['extrasRsvpRequired'] = _formKey.currentState?.fields['extras_rsvp_required']!.value ? 1 : 0;
//                   //       }
//                   //     } else {
//                   //       if (_rdm.eventPriceForExtras != null) {
//                   //         changes['eventPriceForExtras'] = SET_DB_NUMERIC_FIELD_TO_NULL;
//                   //       }

//                   //       if (_rdm.extrasDescription != null) {
//                   //         changes['extrasDescription'] = SET_DB_STRING_FIELD_TO_NULL;
//                   //       }

//                   //       if (_rdm.extrasRsvpRequired != 0) {
//                   //         changes['extrasRsvpRequired'] = 0;
//                   //       }
//                   //     }

//                   if (changes.isNotEmpty) {
//                     final String hasherId = box.get(HIVE_HASHER_ID) as String;

//                     final String accessToken = Utilities.generateToken(hasherId, 'hcportal_addEditPromo');

//                     final dynamic bodyJson = <String, dynamic>{'publicHasherId': hasherId, 'accessToken': accessToken, 'promoId': _promotion.promotionId};

//                     // if ((_rdm.publicEventId != null) && (_rdm.publicEventId!.length > 10)) {
//                     //   bodyJson.addAll(<String, dynamic>{'publicEventId': _rdm.publicEventId});
//                     // }

//                     bodyJson.addAll(changes);

//                     final String body = jsonEncode(bodyJson);
//                     final String jsonResult = await ServiceCommon.sendHttpPost('hcportal_add_edit_promo', body);
//                     final dynamic updateResult = jsonDecode(jsonResult);

//                     final String? resultForDisplay = updateResult[0][0]['result'];

//                     await IveCoreUtilities.showAlert(
//                       navigatorKey.currentContext!,
//                       'Success',
//                       resultForDisplay ?? 'Changes were saved.',
//                       'Done',
//                     );

//                     setState(() {
//                       _isProcessing = false;
//                     });

//                     Navigator.of(
//                       navigatorKey.currentContext!,
//                       rootNavigator: true,
//                     ).pop(
//                       navigatorKey.currentContext!,
//                     );
//                   } else {
//                     await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'No changes', 'No changes were made on the form so nothing was saved to the database.', 'OK');
//                     setState(() {
//                       _isProcessing = false;
//                     });
//                   }
//                 } else {
//                   setState(() {
//                     _isProcessing = false;
//                   });
//                 }
//               },
//               child: const Text('Save changes', style: TextStyle(fontSize: 18.0)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _tabBasicInfo() {
//     return const PromotionForm();
//     //return Container(color: Colors.pink);
//     // return Column(
//     //   crossAxisAlignment: CrossAxisAlignment.start,
//     //   children: <Widget>[
//     //     _categoryLabelWidget('Basic run information'),
//     //     FormBuilderTextField(
//     //       name: 'promo_name',
//     //       enabled: true,
//     //       validator: (String? value) {
//     //         if ((value == null) || (value.isEmpty)) {
//     //           return 'Please provide a name for this promotion';
//     //         }
//     //         return null;
//     //       },
//     //       decoration: InputDecoration(labelText: 'Promotion name', hintText: 'Name', fillColor: Colors.yellow.shade100, filled: true, labelStyle: _labelStyle),
//     //       style: _contentStyle,
//     //       initialValue: _promotion.promoName,
//     //     ),
//     //     const SizedBox(height: 10.0),

//     //     Row(children: <Widget>[
//     //       Expanded(
//     //         child: FormBuilderDateTimePicker(
//     //           enabled: true,
//     //           name: 'promo_start_date',

//     //           validator: (DateTime? value) {
//     //             if (value == null) {
//     //               return 'Please specify a promo end date and time';
//     //             }

//     //             return null;
//     //           },
//     //           inputType: InputType.both,
//     //           decoration: InputDecoration(labelText: 'Promo start time', fillColor: Colors.yellow.shade100, filled: true, labelStyle: _labelStyle),
//     //           style: _contentStyle,
//     //           //initialDate: DateTime.now(),
//     //           //initialTime: const TimeOfDay(hour: 8, minute: 0),
//     //           initialValue: _promotion.promoStartDate,
//     //           format: DateFormat('EEE, M/d/y h:mm a'),
//     //           // enabled: true,
//     //         ),
//     //       ),
//     //       const SizedBox(
//     //         width: 10.0,
//     //       ),
//     //       Expanded(
//     //         child: FormBuilderDateTimePicker(
//     //           enabled: true,
//     //           name: 'promo_end_date',

//     //           validator: (DateTime? value) {
//     //             if (value == null) {
//     //               return 'Please specify a promo end date and time';
//     //             }

//     //             return null;
//     //           },
//     //           inputType: InputType.both,
//     //           decoration: InputDecoration(labelText: 'Promo end time', fillColor: Colors.yellow.shade100, filled: true, labelStyle: _labelStyle),
//     //           style: _contentStyle,
//     //           //initialDate: DateTime.now(),
//     //           //initialTime: const TimeOfDay(hour: 8, minute: 0),
//     //           initialValue: _promotion.promoEndDate,
//     //           format: DateFormat('EEE, M/d/y h:mm a'),
//     //           // enabled: true,
//     //         ),
//     //       ),
//     //     ]),

//     //     // if (_inboundIntegrationId != 0) ...<Widget>[
//     //     //   FormBuilderRadioGroup<bool>(
//     //     //     name: 'use_external_data_for_basic_info',
//     //     //     // selectedColor: Colors.green.shade800,
//     //     //     // backgroundColor: Colors.grey.shade500,
//     //     //     wrapSpacing: 35.0,
//     //     //     onChanged: (bool? useExternalData) {
//     //     //       _useExtRunDetails = useExternalData ?? false;
//     //     //       setState(() {
//     //     //         if (useExternalData ?? false) {
//     //     //           _formKey.currentState?.fields['run_name']?.didChange(_rdm.extEventName);
//     //     //           _formKey.currentState?.fields['run_description']?.didChange(_rdm.extEventDescription);
//     //     //           _formKey.currentState?.fields['place']?.didChange(_rdm.extLocationOneLineDesc);
//     //     //           _formKey.currentState?.fields['run_start_date']?.didChange(_rdm.extEventStartDatetime);
//     //     //         } else {
//     //     //           _formKey.currentState?.fields['run_name']?.didChange(_rdm.eventName);
//     //     //           _formKey.currentState?.fields['run_description']?.didChange(_rdm.eventDescription);
//     //     //           _formKey.currentState?.fields['place']?.didChange(_rdm.locationOneLineDesc);
//     //     //           _formKey.currentState?.fields['run_start_date']?.didChange(_rdm.eventStartDatetime);
//     //     //         }
//     //     //       });
//     //     //     },
//     //     //     //runSpacing: 10.0,
//     //     //     initialValue: _useExtRunDetails,
//     //     //     options: <FormBuilderChipOption<bool>>[
//     //     //       FormBuilderChipOption<bool>(
//     //     //           value: true,
//     //     //           child: Text('Use basic run data from ${INBOUND_DATA_SOURCES[_inboundIntegrationId]} (read-only)', style: _runTagsTextStyle.copyWith(color: Colors.black))),
//     //     //       FormBuilderChipOption<bool>(
//     //     //           value: false, child: Text('Use basic run data from Harrier Central database (editable)', style: _runTagsTextStyle.copyWith(color: Colors.black))),
//     //     //     ],
//     //     //   ),
//     //     //   if (!_useExtRunDetails) ...<Widget>[
//     //     //     Padding(
//     //     //       padding: const EdgeInsets.symmetric(vertical: 8.0),
//     //     //       child: ElevatedButton(
//     //     //         style: ButtonStyle(
//     //     //           backgroundColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
//     //     //           foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
//     //     //         ),
//     //     //         onPressed: () async {
//     //     //           setState(() {
//     //     //             _formKey.currentState?.fields['run_name']!.didChange(_rdm.extEventName);
//     //     //             _formKey.currentState?.fields['run_start_date']!.didChange(_rdm.extEventStartDatetime);
//     //     //             _formKey.currentState?.fields['run_description']!.didChange(_rdm.extEventDescription);
//     //     //             _formKey.currentState?.fields['place']!.didChange(_rdm.extLocationOneLineDesc);
//     //     //           });
//     //     //         },
//     //     //         child: Text('Copy info from ${INBOUND_DATA_SOURCES[_inboundIntegrationId]}', style: const TextStyle(fontSize: 18.0)),
//     //     //       ),
//     //     //     ),
//     //     //   ],
//     //     // ],
//     //     // Row(
//     //     //   children: <Widget>[
//     //     //     Expanded(
//     //     //       flex: 3,
//     //     //       child: FormBuilderTextField(
//     //     //         name: 'run_name',
//     //     //         validator: (String? value) {
//     //     //           if (((value == null) || (value.isEmpty)) && !_useExtRunDetails) {
//     //     //             return 'Please provide a run name';
//     //     //           }
//     //     //           return null;
//     //     //         },
//     //     //         initialValue: _useExtRunDetails ? _rdm.extEventName : _rdm.eventName,
//     //     //         enabled: !_useExtRunDetails,
//     //     //         decoration: InputDecoration(
//     //     //             labelText: 'Run name',
//     //     //             hintText: 'Run name',
//     //     //             fillColor: _useExtRunDetails ? Colors.grey.shade200 : Colors.yellow.shade100,
//     //     //             filled: true,
//     //     //             labelStyle: _labelStyle),
//     //     //         style: _contentStyle,
//     //     //       ),
//     //     //     ),
//     //     //     const SizedBox(width: 30.0),
//     //     //     Expanded(
//     //     //       flex: 1,
//     //     //       child: FormBuilderDateTimePicker(
//     //     //         enabled: !_useExtRunDetails,
//     //     //         name: 'run_start_date',

//     //     //         validator: (DateTime? value) {
//     //     //           if (!_useExtRunDetails) {
//     //     //             if (value == null) {
//     //     //               return 'Please specify a run start date and time';
//     //     //             }
//     //     //             if (value.difference(DateTime.now()).inDays < 0) {
//     //     //               return 'Please specify a run start date and time in the future';
//     //     //             }
//     //     //           }
//     //     //           return null;
//     //     //         },
//     //     //         inputType: InputType.both,
//     //     //         decoration: InputDecoration(
//     //     //             labelText: 'Run start time', fillColor: _useExtRunDetails ? Colors.grey.shade200 : Colors.yellow.shade100, filled: true, labelStyle: _labelStyle),
//     //     //         style: _contentStyle,
//     //     //         //initialDate: DateTime.now(),
//     //     //         //initialTime: const TimeOfDay(hour: 8, minute: 0),
//     //     //         initialValue: (_rdm.useFbRunDetails == 0) ? _rdm.eventStartDatetime : _rdm.extEventStartDatetime,
//     //     //         format: DateFormat('EEE, M/d/y h:mm a'),
//     //     //         // enabled: true,
//     //     //       ),
//     //     //     ),
//     //     //   ],
//     //     // ),
//     //     // const SizedBox(height: 15.0),
//     //     // FormBuilderTextField(
//     //     //   name: 'place',
//     //     //   enabled: !_useExtRunDetails,
//     //     //   validator: (String? value) {
//     //     //     if (((value == null) || (value.isEmpty)) && !_useExtRunDetails) {
//     //     //       return 'Please provide a place or location description';
//     //     //     }
//     //     //     return null;
//     //     //   },
//     //     //   decoration: InputDecoration(
//     //     //       labelText: 'Place description',
//     //     //       hintText: 'Place',
//     //     //       fillColor: _useExtRunDetails ? Colors.grey.shade200 : Colors.yellow.shade100,
//     //     //       filled: true,
//     //     //       labelStyle: _labelStyle),
//     //     //   style: _contentStyle,
//     //     //   initialValue: (_rdm.useFbRunDetails == 0) ? _rdm.locationOneLineDesc : _rdm.extLocationOneLineDesc,
//     //     // ),
//     //     // const SizedBox(height: 15.0),
//     //     // Expanded(
//     //     //   child: FormBuilderTextField(
//     //     //     name: 'run_description',
//     //     //     readOnly: _useExtRunDetails,
//     //     //     minLines: 23,
//     //     //     maxLines: 23,
//     //     //     validator: (String? value) {
//     //     //       if (((value == null) || (value.isEmpty)) && !_useExtRunDetails) {
//     //     //         return 'Please provide an event description';
//     //     //       }
//     //     //       return null;
//     //     //     },
//     //     //     decoration: InputDecoration(
//     //     //         labelText: 'Run description',
//     //     //         hintText: 'Run description',
//     //     //         fillColor: _useExtRunDetails ? Colors.grey.shade200 : Colors.yellow.shade100,
//     //     //         filled: true,
//     //     //         labelStyle: _labelStyle,
//     //     //         alignLabelWithHint: true),
//     //     //     style: _contentStyle,
//     //     //     initialValue: (_rdm.useFbRunDetails == 0) ? _rdm.eventDescription : _rdm.extEventDescription,
//     //     //   ),
//     //     // ),
//     //   ],
//     // );
//   }

//   int _radioGroupValue = 0;

//   Widget _imageSelector(int i) {
//     return Column(children: <Widget>[
//       Text(i.toString()),
//       Checkbox(
//         value: _checkboxValues[i],
//         onChanged: ((value) {
//           setState(() {
//             _checkboxValues[i] = value ?? false;
//           });
//         }),
//       ),
//       Radio(
//           value: i,
//           groupValue: _radioGroupValue,
//           onChanged: (value) {
//             setState(() {
//               _radioGroupValue = value ?? 0;
//             });
//           })
//     ]);
//   }

//   Widget _tabEventImage() {
//     return Column(
//       children: <Widget>[
//         const SizedBox(height: 30.0),
//         Row(
//           children: List.generate(
//             20,
//             (int index) => _imageSelector(index),
//           ),
//         ),
//         if (_uploadedImage != '<null>') ...<Widget>[
//           const SizedBox(height: 30.0),
//           Expanded(
//             child: _uploadingPhoto
//                 ? const Text(
//                     'Uploading image ...',
//                     style: TextStyle(fontSize: 30.0),
//                     textAlign: TextAlign.center,
//                   )
//                 : Container(
//                     decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
//                     child: Image.network(
//                       (_uploadedImage ?? _promotion.promoImage + (_radioGroupValue == 0 ? '' : '_$_radioGroupValue') + _promotion.promoImageExtension),
//                       scale: 0.2,
//                       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
//                         if (loadingProgress == null) {
//                           return child;
//                         }
//                         return Center(
//                           child: CircularProgressIndicator(
//                             value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//           ),
//         ],
//         const SizedBox(height: 20.0),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             ElevatedButton(
//                 style: ButtonStyle(
//                   backgroundColor: WidgetStateProperty.all<Color>(Colors.red.shade900),
//                   foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
//                 ),
//                 onPressed: () async {
//                   setState(() {
//                     _uploadedImage = '<null>';
//                   });
//                 },
//                 child: const Text('Remove Image', style: TextStyle(fontSize: 18.0))),
//             const SizedBox(width: 40.0),
//             ElevatedButton(
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all<Color>(Colors.red.shade900),
//                 foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
//               ),
//               onPressed: () async {
//                 final FilePickerResult? result = await FilePicker.platform.pickFiles();
//                 if (result == null) {
//                   // request was cancelled, don't take any action
//                 } else if (result.files.first.bytes == null) {
//                   await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'File error', 'There was an unknown error with the file upload. Please try uploading another file.', 'OK');
//                 } else {
//                   if ((result.files.first.bytes?.length ?? 3145728) >= 3145728) {
//                     await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'File too large', 'Please select a file that is smaller than 3MB', 'OK');
//                     result.files.clear();
//                   } else {
//                     setState(() {
//                       _uploadingPhoto = true;
//                     });

//                     final Uint8List fileBytes8 = result.files.first.bytes ?? Uint8List(0);
//                     List<int> fileBytes = List<int>.from(fileBytes8);

//                     final String fileExtension = (result.files.first.extension ?? '').toLowerCase();

//                     bool doProcess = true;

//                     // if it's not a JPG / JPEG, convert it to one
//                     if ((fileExtension != 'jpg') && (fileExtension != 'jpeg') && (fileExtension != 'webp')) {
//                       if ((fileExtension == 'png') ||
//                           (fileExtension == 'tga') ||
//                           (fileExtension == 'gif') ||
//                           (fileExtension == 'bmp') ||
//                           (fileExtension == 'ico') ||
//                           (fileExtension == 'psd') ||
//                           (fileExtension == 'pvr') ||
//                           (fileExtension == 'tif') ||
//                           (fileExtension == 'tiff')) {
//                         try {
//                           final image.Image? img = image.decodeImage(Uint8List.fromList(fileBytes));
//                           if (img != null) {
//                             fileBytes = image.encodeJpg(img);
//                           }
//                         } catch (e) {
//                           doProcess = false;
//                           await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Error processing image',
//                               'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file', 'OK');
//                         }
//                       } else {
//                         doProcess = false;
//                         await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Error processing image',
//                             'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file', 'OK');
//                       }
//                     }

//                     if (doProcess && fileBytes.isNotEmpty) {
//                       final String filename = await _upload(
//                         fileBytes,
//                         _promotion.promotionId,
//                         _radioGroupValue,
//                       );
//                       if (filename.isNotEmpty) {
//                         setState(() {
//                           _uploadedImage = BASE_PROMO_IMAGE_URL + filename;
//                         });
//                       }
//                     }
//                   }
//                 }

//                 setState(() {
//                   _uploadingPhoto = false;
//                 });
//               },
//               child: const Text('Select Image', style: TextStyle(fontSize: 18.0)),
//             ),
//           ],
//         ),
//         // const SizedBox(height: 30.0),
//         // Expanded(
//         //   child: Image.network(_promotion.promoImage + _promotion.promoImageExtension),
//         // ),
//         const SizedBox(height: 20.0),
//       ],
//     );
//   }

//   Widget _tabEmpty() {
//     return Container(color: Colors.pink);
//   }

//   // Widget _categoryLabelWidget(
//   //   String label,
//   // ) {
//   //   return Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: <Widget>[
//   //       Container(
//   //         margin: const EdgeInsets.only(top: 20.0),
//   //         child: Text(
//   //           label,
//   //           style: const TextStyle(
//   //             fontFamily: 'AvenirNextBold',
//   //             color: Colors.deepOrange,
//   //             fontWeight: FontWeight.bold,
//   //             fontSize: 18.0,
//   //           ),
//   //         ),
//   //       ),
//   //       Divider(thickness: 3.0, color: Colors.deepOrange.shade100),
//   //     ],
//   //   );
//   // }

//   Tab _myTabWidget(
//     String label,
//   ) {
//     return Tab(
//       child: Align(
//         alignment: Alignment.center,
//         child: Text(
//           label,
//           style: const TextStyle(
//             fontFamily: 'AvenirNextBold',
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 18.0,
//           ),
//         ),
//       ),
//     );
//   }

//   Future<String> _upload(List<int> imageBytes, String promotionId, int overlayNumber) async {
//     // NOTE: If we run into errors testing this locally, run the following command in the flutter terminal
//     // fluttercors --disable
//     // then when you are done editing, run this command
//     // fluttercors --enable

//     String fileName = 'promoImage_${promotionId}_${overlayNumber == 0 ? '' : overlayNumber}.jpg';

//     final Uri uri = Uri.parse(
//         'https://harriercentral.blob.core.windows.net/promos/$fileName?sv=2021-08-06&st=2022-11-21T20%3A01%3A00Z&se=2030-01-01T20%3A01%3A00Z&sr=c&sp=racwlf&sig=1NnmNUfvBrN3p45o71shY8PgjKDTQuov2zOZouVD8Ac%3D');

//     // final Request request = Request('PUT', uri);

//     // final Map<String, String> headers = <String, String>{
//     //   'content-type': 'image/jpeg',
//     //   'x-ms-blob-type': 'BlockBlob',
//     //   'Access-Control-Allow-Origin': '*',
//     // };

//     // request.headers.addAll(headers);

//     // request.bodyBytes = imageBytes;
//     // final StreamedResponse response = await request.send();

//     final Map<String, String> headers = <String, String>{
//       'content-type': 'image/jpeg',
//       'x-ms-blob-type': 'BlockBlob',
//       'Access-Control-Allow-Origin': '*',
//     };

//     final dynamic response = (await http.put(uri, headers: headers, body: imageBytes));

//     if (((response.statusCode ?? 0) < 200) || ((response.statusCode ?? 0) >= 300)) {
//       await IveCoreUtilities.showAlert(navigatorKey.currentContext!, 'Upload failed', 'The file was unable to be uploaded at this time. Please try again later.', 'OK');
//       fileName = '';
//     }

//     return fileName;
//   }

//   void _updateChangedField(
//     Map<String, dynamic> changes,
//     String formFieldName,
//     String wireFieldName,
//     dynamic cleanValue,
//   ) {
//     if (_isAddMode || (_formKey.currentState?.fields[formFieldName]!.value != cleanValue)) {
//       changes[wireFieldName] = _formKey.currentState?.fields[formFieldName]!.value.toString();
//     }
//   }
// }
