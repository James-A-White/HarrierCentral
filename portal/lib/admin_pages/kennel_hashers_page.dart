import 'package:hcportal/imports.dart';
import 'package:hcportal/models/new_hasher/new_hasher_model.dart';

enum EKennelGridOptions {
  allFields,
  membership,
  nonAppHashers,
  runCounts,
  notificationAndEmail,
  photos,
  hashCredit,
  addNewMembers,
}

class KennelHashersController extends GetxController {
  KennelHashersController(this.kennel);

  final HasherKennelsModel kennel;

  TrinaGridStateManager? stateManager;
  bool isMinorUpdate = false;
  bool isMajorUpdate = false;
  String descriptionText = '';
  String tableHeadingText = '';

  static const double photoRowHeight = 300;
  static const double standardRowHeight = 30;

  final List<TrinaColumn> columns = <TrinaColumn>[];
  Key gridKey = UniqueKey();

  EKennelGridOptions columnsType = EKennelGridOptions.membership;

  final List<TrinaColumn> columnsAll = <TrinaColumn>[
    TrinaColumn(
      title: 'Hasher ID',
      field: 'publicHasherId',
      type: TrinaColumnType.text(),
      hide: true,
    ),
    TrinaColumn(
      title: 'Kennel ID',
      field: 'kennelId',
      type: TrinaColumnType.text(),
      hide: true,
    ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Hash Name',
      field: 'hashName',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'First Name',
      field: 'firstName',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'Last Name',
      field: 'lastName',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: 'Photo',
      field: 'photo',
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Invite Code',
      field: 'inviteCode',
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Is Home Kennel',
      field: 'isHomeKennel',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Is Following',
      field: 'isFollowing',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No', 'Auto']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Is Member',
      field: 'isMember',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Status',
      field: 'status',
      type: TrinaColumnType.select(<dynamic>['Member', 'Following', 'None']),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Notifications',
      field: 'notifications',
      type: TrinaColumnType.select(<dynamic>['Auto', 'On', 'Off']),
    ),
    TrinaColumn(
      title: 'Email Alerts',
      field: 'emailAlerts',
      type: TrinaColumnType.select(<dynamic>['Auto', 'On', 'Off']),
    ),
    TrinaColumn(
      title: 'Historic Haring Counts',
      field: 'historicHaring',
      type: TrinaColumnType.number(),
    ),
    TrinaColumn(
      title: 'Historic Total Runs',
      field: 'historicTotalRuns',
      type: TrinaColumnType.number(),
    ),
    TrinaColumn(
      title: 'Haring in HC',
      field: 'trackedHaringInHc',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Pack runs in HC',
      field: 'trackedPackRunsInHc',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Total Haring',
      field: 'overallTotalHaring',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Total Runs',
      field: 'overallTotalRuns',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Historic Data is Estimated',
      field: 'historicCountsAreEstimates',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
    ),
    TrinaColumn(
      title: 'Date of Last Run',
      field: 'dateOfLastRun',
      type: TrinaColumnType.date(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Membership Expiration Date',
      field: 'membershipExpirationDate',
      type: TrinaColumnType.date(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Hash Credit',
      field: 'hashCredit',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Last Login Date',
      field: 'lastLoginDateTime',
      type: TrinaColumnType.date(),
      enableEditingMode: false,
    ),
  ];

  final List<TrinaColumn> columnsNotificationAndEmail = <TrinaColumn>[
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    TrinaColumn(
      title: 'Notifications',
      field: 'notifications',
      type: TrinaColumnType.select(<dynamic>['Auto', 'On', 'Off']),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Email Alerts',
      field: 'emailAlerts',
      type: TrinaColumnType.select(<dynamic>['Auto', 'On', 'Off']),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaColumn> columnsMembership = <TrinaColumn>[
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    TrinaColumn(
      title: 'Status',
      field: 'status',
      type: TrinaColumnType.select(<dynamic>['Member', 'Following']),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Last login to app',
      field: 'lastLoginDateTime',
      type: TrinaColumnType.date(),
      //sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Last run',
      field: 'dateOfLastRun',
      type: TrinaColumnType.date(),
      //sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      width: 300,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    // TrinaColumn(
    //   title: 'Is Following',
    //   field: 'isFollowing',
    //   type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
    //   enableEditingMode: false,
    //   // renderer: (TrinaColumnRendererContext rendererContext) {
    //   //   return Text(
    //   //     rendererContext.cell.value.toString(),
    //   //     style: TextStyle(
    //   //       fontFamily: 'AvenirNextBold',
    //   //       color: Colors.blue.shade700,
    //   //       fontWeight: FontWeight.bold,
    //   //     ),
    //   //   );
    //   // },
    // ),
  ];

  final List<TrinaColumn> columnsPhoto = <TrinaColumn>[
    // TrinaColumn(
    //   title: 'Hasher ID',
    //   field: 'publicHasherId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    // TrinaColumn(
    //   title: 'Kennel ID',
    //   field: 'kennelId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 400,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        );
      },
    ),
    // TrinaColumn(
    //   title: 'Hash Name',
    //   field: 'hashName',
    //   type: TrinaColumnType.text(),
    // ),
    TrinaColumn(
      title: 'Photo',
      field: 'photo',
      minWidth: KennelHashersController.photoRowHeight,
      width: KennelHashersController.photoRowHeight,
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
  ];

  final List<TrinaColumn> columnsHashCredit = <TrinaColumn>[
    // TrinaColumn(
    //   title: 'Hasher ID',
    //   field: 'publicHasherId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    // TrinaColumn(
    //   title: 'Kennel ID',
    //   field: 'kennelId',
    //   type: TrinaColumnType.text(),
    //   hide: true,
    // ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),

    TrinaColumn(
      title: 'Hash Credit',
      field: 'hashCredit',
      type: TrinaColumnType.number(),
      enableEditingMode: false,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          ((rendererContext.cell.value as num).toStringAsFixed(2)),
          style: const TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Discount',
      field: 'discountAmount',
      type: TrinaColumnType.number(format: '#######.00'),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          (rendererContext.cell.value as num).toStringAsFixed(2),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Discount %',
      field: 'discountPercent',
      type: TrinaColumnType.number(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          (rendererContext.cell.value as num).toStringAsFixed(0),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Discount description',
      field: 'discountDescription',
      type: TrinaColumnType.text(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value as String,
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaColumn> columnsRunCounts = <TrinaColumn>[
    // TrinaColumn(
    //   title: 'Hasher ID',
    //   field: 'publicHasherId',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    //   hide: true,
    // ),
    // TrinaColumn(
    //   title: 'Kennel ID',
    //   field: 'kennelId',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    //   hide: true,
    // ),
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    // TrinaColumn(
    //   title: 'Hash Name',
    //   field: 'hashName',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'First Name',
    //   field: 'firstName',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'Last Name',
    //   field: 'lastName',
    //   type: TrinaColumnType.text(),
    //   enableEditingMode: false,
    // ),

    TrinaColumn(
      title: 'Previous total runs',
      field: 'historicTotalRuns',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),

    TrinaColumn(
      title: 'Overall total runs',
      field: 'overallTotalRuns',
      type: TrinaColumnType.number(),
      width: 150,
      enableEditingMode: false,
    ),
    TrinaColumn(
      title: 'Previous haring',
      field: 'historicHaring',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Overall haring',
      field: 'overallTotalHaring',
      type: TrinaColumnType.number(),
      width: 150,
      enableEditingMode: false,
    ),

    // Uncomment for testing

    // TrinaColumn(
    //   title: 'Pack runs in HC',
    //   field: 'trackedPackRunsInHc',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'Haring in HC',
    //   field: 'trackedHaringInHc',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),
    // TrinaColumn(
    //   title: 'Total in HC',
    //   field: 'trackedTotalRunsInHc',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),

    // TrinaColumn(
    //   title: 'Previous pack runs',
    //   field: 'historicPackRuns',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    // ),

    // TrinaColumn(
    //   title: 'Overall pack runs',
    //   field: 'overallTotalPackRuns',
    //   type: TrinaColumnType.number(),
    //   width: 150.0,
    //   enableEditingMode: false,
    // ),

    TrinaColumn(
      title: 'Previous are estimates',
      field: 'historicCountsAreEstimates',
      type: TrinaColumnType.select(<dynamic>['Yes', 'No']),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaColumn> columnsNameAndEmail = <TrinaColumn>[
    TrinaColumn(
      title: 'Display Name',
      field: 'displayName',
      type: TrinaColumnType.text(),
      sort: TrinaColumnSort.ascending,
      enableEditingMode: false,
      width: 300,
    ),
    TrinaColumn(
      title: 'Hash Name',
      field: 'hashName',
      type: TrinaColumnType.text(),
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'First Name',
      field: 'firstName',
      type: TrinaColumnType.text(),
      width: 140,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Last Name',
      field: 'lastName',
      type: TrinaColumnType.text(),
      width: 140,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      width: 250,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Invite Code',
      field: 'inviteCode',
      type: TrinaColumnType.text(),
      enableEditingMode: false,
    ),
  ];

  final List<TrinaColumn> columnsAddHasher = <TrinaColumn>[
    TrinaColumn(
      title: 'Hash Name',
      field: 'hashName',
      type: TrinaColumnType.text(),
      width: 250,
    ),
    TrinaColumn(
      title: 'First Name',
      field: 'firstName',
      type: TrinaColumnType.text(),
      width: 180,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Last Name',
      field: 'lastName',
      type: TrinaColumnType.text(),
      width: 180,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Email',
      field: 'eMail',
      type: TrinaColumnType.text(),
      width: 300,
      renderer: (TrinaColumnRendererContext rendererContext) {
        final cellValue = rendererContext.cell.value.toString();
        var emailValid = true;
        if (cellValue.isNotEmpty) {
          emailValid = EmailValidator.validate(cellValue);
        }
        return Row(
          children: <Widget>[
            if (!emailValid) ...<Widget>[
              const Icon(
                FontAwesome.warning,
                size: 20,
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              cellValue,
              style: TextStyle(
                fontFamily: 'AvenirNextBold',
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    ),
    TrinaColumn(
      title: 'Run count',
      field: 'historicTotalRuns',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
    TrinaColumn(
      title: 'Haring count',
      field: 'historicHaring',
      type: TrinaColumnType.number(),
      width: 150,
      renderer: (TrinaColumnRendererContext rendererContext) {
        return Text(
          rendererContext.cell.value.toString(),
          style: TextStyle(
            fontFamily: 'AvenirNextBold',
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  ];

  final List<TrinaRow<dynamic>> rows = <TrinaRow<dynamic>>[];

  final List<KennelHashersModel> hashers = <KennelHashersModel>[];
  final List<NewHasherModel> newHashers = <NewHasherModel>[];

  @override
  void onInit() {
    super.onInit();
    unawaited(_init());
  }

  Future<void> _init() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (kennel.canManageMembers) {
      await setColumnsType(EKennelGridOptions.membership);
    } else if (kennel.canManageHashCash) {
      await setColumnsType(EKennelGridOptions.hashCredit);
    } else {
      final error = ArgumentError(
        'Membership screen should only be accessible by users that have Manage Members or Manage Hash Cash permissions.',
      );
      throw (error);
    }
  }

  Future<void> getRowData() async {
    final accessToken = Utilities.generateToken(
      box.get(HIVE_HASHER_ID) as String,
      'hcportal_getKennelHashers',
      paramString: kennel.publicKennelId,
    );

    final body = <String, String>{
      'queryType': 'getKennelHashers',
      'publicHasherId': box.get(HIVE_HASHER_ID) as String,
      'accessToken': accessToken,
      'publicKennelId': kennel.publicKennelId,
    };

    final jsonString = await ServiceCommon.sendHttpPostToAzureFunctionApi(body);
    hashers.clear();
    rows.clear();
    newHashers.clear();
    if (jsonString.length > 10) {
      final decodedJson = json.decode(jsonString) as List<dynamic>;
      final jsonGroup = (decodedJson[0] as List)
          .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
          .toList();
      for (final jsonItem in jsonGroup) {
        final item = KennelHashersModel.fromJson(jsonItem);
        var doAddRow = false;

        if ((columnsType == EKennelGridOptions.nonAppHashers) &&
            item.isHomeKennel.toLowerCase() == 'yes' &&
            item.inviteCode.trim().isNotEmpty) {
          doAddRow = true;
        } else if ((columnsType == EKennelGridOptions.allFields) ||
            (columnsType == EKennelGridOptions.runCounts) ||
            (columnsType == EKennelGridOptions.membership)) {
          doAddRow = true;
        } else if ((columnsType == EKennelGridOptions.photos) &&
            (item.photo.contains('http'))) {
          doAddRow = true;
        } else if (((columnsType == EKennelGridOptions.hashCredit) ||
                (columnsType == EKennelGridOptions.notificationAndEmail)) &&
            item.isMember.toLowerCase() == 'yes') {
          doAddRow = true;
        }

        if (doAddRow) {
          hashers.add(item);
        }
      }

      updateTrinaRows();
    }

    var i = 0;

    do {
      if (stateManager != null) {
        stateManager!.notifyListeners();
        break;
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      i++;
    } while (i < 100);

    update();
  }

  void updateTrinaRows() {
    rows.clear();

    for (var i = 0; i < hashers.length; i++) {
      final item = hashers[i];
      final pr = TrinaRow<dynamic>(
        cells: <String, TrinaCell>{
          'publicHasherId': TrinaCell(value: item.publicHasherId),
          'publicKennelId': TrinaCell(value: item.publicKennelId),
          'hashName': TrinaCell(value: item.hashName ?? ''),
          'displayName': TrinaCell(value: (item.displayName?.capitalize ?? '')),
          'firstName': TrinaCell(value: item.firstName ?? ''),
          'lastName': TrinaCell(value: item.lastName ?? ''),
          'eMail': TrinaCell(value: item.eMail),
          'photo': TrinaCell(value: item.photo),
          'inviteCode': TrinaCell(value: item.inviteCode),
          'isHomeKennel': TrinaCell(value: item.isHomeKennel),
          'isFollowing': TrinaCell(value: item.isFollowing),
          'isMember': TrinaCell(value: item.isMember),
          'status': TrinaCell(value: item.status),
          'notifications': TrinaCell(value: item.notifications),
          'emailAlerts': TrinaCell(value: item.emailAlerts),
          'historicHaring': TrinaCell(value: item.historicHaring),
          'historicTotalRuns': TrinaCell(value: item.historicTotalRuns),
          'hcHaringCount': TrinaCell(value: item.hcHaringCount),
          'hcTotalRunCount': TrinaCell(value: item.hcTotalRunCount),
          'overallTotalHaring':
              TrinaCell(value: item.historicHaring + item.hcHaringCount),
          'overallTotalRuns':
              TrinaCell(value: item.historicTotalRuns + item.hcTotalRunCount),
          'historicCountsAreEstimates':
              TrinaCell(value: item.historicCountsAreEstimates),
          'dateOfLastRun': TrinaCell(value: item.dateOfLastRun ?? ''),
          'membershipExpirationDate':
              TrinaCell(value: item.membershipExpirationDate),
          'hashCredit': TrinaCell(value: item.hashCredit),
          'kennelCredit': TrinaCell(value: item.kennelCredit),
          'discountPercent': TrinaCell(value: item.discountPercent),
          'discountAmount': TrinaCell(value: item.discountAmount),
          'discountDescription':
              TrinaCell(value: item.discountDescription ?? ''),
          'lastLoginDateTime': TrinaCell(value: item.lastLoginDateTime ?? ''),
        },
      );

      // print(i.toString() +
      //     ' # ' +
      //     item.trackedPackRunsInHc.toString() +
      //     ' # ' +
      //     item.trackedHaringInHc.toString() +
      //     ' # ' +
      //     item.historicTotalRuns.toString() +
      //     ' # ' +
      //     item.historicHaring.toString() +
      //     ' # ' +
      //     item.overallTotalRuns.toString() +
      //     ' # ' +
      //     item.overallTotalHaring.toString());

      rows.add(pr);
    }
  }

  Future<void> prepareGridForAddingNewMembers() async {
    // fill in any empty records to make sure
    // we have a "full deck" to play with
    while (newHashers.length < 100) {
      final n = NewHasherModel(
        firstName: '',
        lastName: '',
        hashName: '',
        eMail: '',
      );

      newHashers.add(n);
    }

    TrinaRow<dynamic> pr;
    for (var i = 0; i < 100; i++) {
      pr = TrinaRow(
        cells: <String, TrinaCell>{
          'publicHasherId': TrinaCell(),
          'publicKennelId': TrinaCell(),
          'hashName': TrinaCell(value: newHashers[i].hashName),
          'firstName': TrinaCell(value: newHashers[i].firstName),
          'lastName': TrinaCell(value: newHashers[i].lastName),
          'eMail': TrinaCell(value: newHashers[i].eMail),
          'historicHaring': TrinaCell(value: newHashers[i].historicHaring),
          'historicTotalRuns':
              TrinaCell(value: newHashers[i].historicTotalRuns),
        },
      );

      rows.add(pr);
    }

    var i = 0;

    do {
      if (stateManager != null) {
        stateManager!.notifyListeners();
        break;
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      i++;
    } while (i < 100);

    update();
  }

  Future<void> setColumnsType(EKennelGridOptions columnsType) async {
    gridKey = UniqueKey();
    this.columnsType = columnsType;
    rows.clear();
    columns.clear();
    switch (columnsType) {
      case EKennelGridOptions.allFields:
        columns.addAll(columnsAll);
        descriptionText = 'The full monty!';
        tableHeadingText = 'All fields';
      case EKennelGridOptions.hashCredit:
        columns.addAll(columnsHashCredit);
        descriptionText =
            'This view allows you to see and edit payment related information for Kennel members. Discounts can be applied as either absolute amounts or percentages';
        tableHeadingText = 'Payment';
      case EKennelGridOptions.nonAppHashers:
        columns.addAll(columnsNameAndEmail);
        descriptionText =
            'You can edit names and email addresses and also see invite codes for Hashers that you have entered into the system. As a security measure, as soon as a Hasher has installed the app, you will no longer be able to update this information as they will be able to do this directly through their own app.';
        tableHeadingText = 'Names and Email Address';
      case EKennelGridOptions.notificationAndEmail:
        columns.addAll(columnsNotificationAndEmail);
        descriptionText =
            'You can view and edit the notification and email settings for members of your Kennel.';
        tableHeadingText = 'Notification and Email Preferences';
      case EKennelGridOptions.membership:
        columns.addAll(columnsMembership);
        descriptionText =
            'You can view people following your Kennel as well as Kennel members. You can change the membership status of Hashers, but only they can change whether or not they are following your Kennel.';
        tableHeadingText = 'Membership and Following Status';
      case EKennelGridOptions.photos:
        columns.addAll(columnsPhoto);
        descriptionText = 'Smile for the camera!';
        tableHeadingText = 'Profile Photos';
        columns[1].renderer = (TrinaColumnRendererContext context) {
          if (hashers[context.rowIdx].photo.contains('http')) {
            return Image.network(
              hashers[context.rowIdx].photo,
              height: 200,
              width: 200,
            );
          } else {
            return Container();
          }
        };
      case EKennelGridOptions.runCounts:
        descriptionText =
            "This view allows you to set the number of times a Hasher has run before using Harrier Central (previous runs). The app will add this number to it's automatically generated run count information. You can indicate whether these previous run counts are based on actual data or are estimates. You can also sort the grid by clicking on the column header. To copy and paste, select a cell and then hold the shift key down while selecting another cell to define a cell range to copy.";
        tableHeadingText = 'Run Counts';
        columns.addAll(columnsRunCounts);
      case EKennelGridOptions.addNewMembers:
        descriptionText =
            "This view makes it easy to add new Hashers to Harrier Central. Once created, these new accounts will be visible on the 'name and email' view";
        tableHeadingText = 'Add New Kennel Members';
        columns.addAll(columnsAddHasher);
        columns[0].renderer = (TrinaColumnRendererContext context) {
          return Row(
            children: <Widget>[
              Icon(
                newHashers[context.rowIdx].addHasherStatus ==
                        BULK_IMPORT_RESPONSE_ERROR
                    ? MaterialCommunityIcons.close_box
                    : FontAwesome.check_square,
                size: 20,
                color: newHashers[context.rowIdx].addHasherStatus == null
                    ? Colors.white
                    : newHashers[context.rowIdx].addHasherStatus ==
                            BULK_IMPORT_RESPONSE_NO_CHANGE
                        ? Colors.grey.shade300
                        : newHashers[context.rowIdx].addHasherStatus ==
                                BULK_IMPORT_RESPONSE_NEW_MEMBER
                            ? Colors.blue.shade700
                            : newHashers[context.rowIdx].addHasherStatus ==
                                    BULK_IMPORT_RESPONSE_NEW_HC_USER
                                ? Colors.green
                                : newHashers[context.rowIdx].addHasherStatus ==
                                        BULK_IMPORT_RESPONSE_UPDATE_RUN_COUNTS
                                    ? Colors.purple.shade500
                                    : Colors.red.shade900,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                ((context.cell.value as String?) ?? '').isNotEmpty
                    ? (context.cell.value as String? ?? '')
                    : (newHashers[context.rowIdx].hashName ?? ''),
                style: TextStyle(
                  fontFamily: 'AvenirNextBold',
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

          // if ((context.rowIdx != null) && (_hashers.length > context.rowIdx )) {
          //   return Image.network(_hashers[context.rowIdx].photo, height: 200.0, width: 200.0);
          // } else {
          //   return Container();
          // }
        };
    }

    if (columnsType == EKennelGridOptions.addNewMembers) {
      await prepareGridForAddingNewMembers();
    } else {
      await getRowData();
    }
  }

  Future<void> onGridChanged(TrinaGridOnChangedEvent event) async {
    // this trick to embed the setState in a Delay eliminates problems when the widget tree is rebuilding
    Future.delayed(Duration.zero, () {
      isMinorUpdate = true;
      update();
    });

    if (columnsType != EKennelGridOptions.addNewMembers) {
      final publicHasherIdCell =
          event.row.cells['publicHasherId'];
      final publicKennelIdCell =
          event.row.cells['publicKennelId'];

      final hasherBeingEditedPublicId =
          publicHasherIdCell?.value?.toString() ?? '';
      final publicKennelId =
          publicKennelIdCell?.value?.toString() ?? '';
      final field = event.column.field;
      final newValue = event.value.toString();

      final accessToken = Utilities.generateToken(
        box.get(HIVE_HASHER_ID) as String,
        'hcportal_updateKennelHasher',
        paramString: hasherBeingEditedPublicId,
      );

      if ((field == 'firstName') ||
          (field == 'lastName') ||
          (field == 'hashName') ||
          (field == 'eMail') ||
          (field == 'status') ||
          (field == 'emailAlerts') ||
          (field == 'notifications') ||
          (field == 'historicTotalRuns') ||
          (field == 'discountAmount') ||
          (field == 'discountPercent') ||
          (field == 'discountDescription') ||
          (field == 'historicCountsAreEstimates') ||
          (field == 'historicHaring')) {
        final body = <String, String>{
          'queryType': 'updateKennelHasher',
          'publicHasherId': box.get(HIVE_HASHER_ID) as String,
          'accessToken': accessToken,
          'hasherBeingEditedPublicId':
              hasherBeingEditedPublicId,
          'publicKennelId': publicKennelId,
          field: newValue,
        };

        final jsonResult = await ServiceCommon
            .sendHttpPostToAzureFunctionApi(body);
        //print('result=' + jsonResult);
        if (jsonResult.length > 10) {
          final jsonItems =
              json.decode(jsonResult) as List<dynamic>;
          if (jsonItems.isNotEmpty) {
            final item = ((jsonItems[0]) as List<dynamic>)[0]
                as Map<String, dynamic>;
            if (item['hkmId'] != null) {
              final historicalTotalRunCount =
                  item['HistoricalTotalRunCount'] as int;
              final historicalHaringCount =
                  item['HistoricalHaringCount'] as int;
              final hcTotalRunCount =
                  item['HcTotalRunCount'] as int;
              final hcHaringCount =
                  item['HcHaringCount'] as int;

              hashers[event.rowIdx] =
                  hashers[event.rowIdx].copyWith(
                historicHaring: historicalHaringCount,
                historicTotalRuns: historicalTotalRunCount,
                hcHaringCount: hcHaringCount,
                hcTotalRunCount: hcTotalRunCount,
              );

              updateTrinaRows();
              gridKey = UniqueKey();
              update();
            }
          }
        }
      }
    }

    // this trick to embed the setState in a Delay eliminates problems when the widget tree is rebuilding
    Future.delayed(Duration.zero, () {
      isMinorUpdate = false;
      update();
    });
  }

  void onGridLoaded(TrinaGridOnLoadedEvent event) {
    stateManager = event.stateManager;
  }

  Future<void> saveBulkHashers() async {
    stateManager!
        .setCurrentCell(rows[98].cells['firstName'], 0);
    stateManager!
        .setCurrentCell(rows[99].cells['firstName'], 0);
    stateManager!.gridFocusNode.unfocus(
      disposition:
          UnfocusDisposition.previouslyFocusedChild,
    );
    isMajorUpdate = true;
    update();

    await Future<void>.delayed(const Duration(seconds: 2));

    final newHasherList = <NewHasherModel?>[];
    for (var i = 0; i < 100; i++) {
      final pr = rows[i];
      final firstName =
          pr.cells['firstName']?.value?.toString() ?? '';
      final lastName =
          pr.cells['lastName']?.value?.toString() ?? '';
      var hashName =
          pr.cells['hashName']?.value?.toString() ?? '';
      final email =
          pr.cells['eMail']?.value?.toString() ?? '';
      final historicTotalRuns =
          (pr.cells['historicTotalRuns']?.value ?? 0)
              as int;
      final historicHaring =
          (pr.cells['historicHaring']?.value ?? 0) as int;

      //print('first name = ' + firstName + ', row = ' + i.toString());
      //print('email = ' + email + ', row = ' + i.toString());
      if ((firstName.isEmpty) || (email.isEmpty)) {
        continue;
      }

      if (hashName.isEmpty) {
        hashName = 'Just $firstName';
      }

      final nh = NewHasherModel(
        firstName: firstName,
        lastName: lastName,
        hashName: hashName,
        eMail: email,
        publicKennelId: kennel.publicKennelId,
        historicTotalRuns: historicTotalRuns,
        historicHaring: historicHaring,
      );
      // make sure duplicate emails are not sent to the server
      if (newHasherList.firstWhere(
            (NewHasherModel? element) =>
                element?.eMail == email,
            orElse: () => null,
          ) ==
          null) {
        newHasherList.add(nh);
      }
    }

    if (newHasherList.isNotEmpty) {
      final newHasherJson = jsonEncode(newHasherList);
      //print(newHasherJson);

      final accessToken = Utilities.generateToken(
        box.get(HIVE_HASHER_ID) as String,
        'hcportal_bulkAddHashers',
        paramString: kennel.publicKennelId,
      );

      final body = <String, String>{
        'queryType': 'bulkAddHashers',
        'publicHasherId': box.get(HIVE_HASHER_ID) as String,
        'accessToken': accessToken,
        'publicKennelId': kennel.publicKennelId,
        'newHasherJson': newHasherJson,
      };
      //print(body);
      final jsonString = await ServiceCommon
          .sendHttpPostToAzureFunctionApi(body);

      newHashers.clear();

      final decodedJson =
          json.decode(jsonString) as List<dynamic>;
      final jsonGroup = (decodedJson[0] as List)
          .map<Map<String, dynamic>>(
            (e) => e as Map<String, dynamic>,
          )
          .toList();
      for (final item in jsonGroup) {
        final hasher = NewHasherModel.fromJson(
          item,
        );
        newHashers.add(hasher);
      }

      await prepareGridForAddingNewMembers();
    }
    isMajorUpdate = false;
    update();
  }
}

class KennelHashersPage extends StatelessWidget {
  const KennelHashersPage(this.kennel, {super.key});

  final HasherKennelsModel kennel;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KennelHashersController>(
      init: KennelHashersController(kennel),
      builder: (c) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Kennel Members and Followers for ${c.kennel.kennelName}',
          ),
          leading: GestureDetector(
            onTap: () {
              Get.back<void>();
            },
            child: const Icon(
              MaterialCommunityIcons.arrow_left,
              color: Colors.black,
            ),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // SizedBox(
              //     height: 20,
              //     width: 200,
              //     child: Text(
              //       (c.isMinorUpdate || c.isMajorUpdate) ? 'Updating' : '',
              //       textAlign: TextAlign.left,
              //     )),
              OverflowBar(
                alignment: MainAxisAlignment.start,
                spacing: 10,
                overflowSpacing: 10,
                children: <Widget>[
                  // ElevatedButton(
                  //   child: const Text('All fields'),
                  //   onPressed: () async {
                  //     await c.setColumnsType(EKennelGridOptions.allFields);
                  //   },
                  // ),

                  if (c.kennel.canManageMembers) ...[
                    ElevatedButton(
                      style: c.columnsType != EKennelGridOptions.addNewMembers
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color.fromARGB(
                                      255,
                                      120,
                                      0,
                                      0,
                                    ); // Hover color
                                  }
                                  return Colors.red.shade900; // Default color
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            )
                          : ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.blue.shade900,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            ),
                      onPressed: () async {
                        await c.setColumnsType(EKennelGridOptions.addNewMembers);
                      },
                      child: const Text(
                        'Add new Hashers',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: c.columnsType != EKennelGridOptions.nonAppHashers
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color.fromARGB(
                                      255,
                                      120,
                                      0,
                                      0,
                                    ); // Hover color
                                  }
                                  return Colors.red.shade900; // Default color
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            )
                          : ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.blue.shade900,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            ),
                      onPressed: () async {
                        await c.setColumnsType(EKennelGridOptions.nonAppHashers);
                      },
                      child: const Text(
                        'Non-app Hashers',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: c.columnsType != EKennelGridOptions.membership
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color.fromARGB(
                                      255,
                                      120,
                                      0,
                                      0,
                                    ); // Hover color
                                  }
                                  return Colors.red.shade900; // Default color
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            )
                          : ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.blue.shade900,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            ),
                      onPressed: () async {
                        await c.setColumnsType(EKennelGridOptions.membership);
                      },
                      child: const Text(
                        'Membership',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: c.columnsType != EKennelGridOptions.runCounts
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color.fromARGB(
                                      255,
                                      120,
                                      0,
                                      0,
                                    ); // Hover color
                                  }
                                  return Colors.red.shade900; // Default color
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            )
                          : ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.blue.shade900,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            ),
                      onPressed: () async {
                        await c.setColumnsType(EKennelGridOptions.runCounts);
                      },
                      child: const Text(
                        'Run counts',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: c.columnsType !=
                              EKennelGridOptions.notificationAndEmail
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color.fromARGB(
                                      255,
                                      120,
                                      0,
                                      0,
                                    ); // Hover color
                                  }
                                  return Colors.red.shade900; // Default color
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            )
                          : ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.blue.shade900,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            ),
                      onPressed: () async {
                        await c.setColumnsType(
                          EKennelGridOptions.notificationAndEmail,
                        );
                      },
                      child: const Text(
                        'Notifications & Email',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: c.columnsType != EKennelGridOptions.photos
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color.fromARGB(
                                      255,
                                      120,
                                      0,
                                      0,
                                    ); // Hover color
                                  }
                                  return Colors.red.shade900; // Default color
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            )
                          : ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.blue.shade900,
                              ),
                              foregroundColor:
                                  WidgetStateProperty.all<Color>(Colors.white),
                            ),
                      onPressed: () async {
                        await c.setColumnsType(EKennelGridOptions.photos);
                      },
                      child: const Text(
                        'Photos',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  ElevatedButton(
                    style: c.columnsType != EKennelGridOptions.hashCredit
                        ? ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return const Color.fromARGB(
                                    255,
                                    120,
                                    0,
                                    0,
                                  ); // Hover color
                                }
                                return Colors.red.shade900; // Default color
                              },
                            ),
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                          )
                        : ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(
                              Colors.blue.shade900,
                            ),
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.white),
                          ),
                    onPressed: () async {
                      await c.setColumnsType(EKennelGridOptions.hashCredit);
                    },
                    child: const Text(
                      'Payment Info',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  c.descriptionText,
                  style: const TextStyle(
                    fontFamily: 'AvenirNext',
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                color: Colors.blue.shade900,
                width: 10000,
                height: 40,
                child: Center(
                  child: Text(
                    c.tableHeadingText +
                        ((c.isMinorUpdate || c.isMajorUpdate) ? ' (Updating)' : ''),
                    style: const TextStyle(
                      fontFamily: 'AvenirNextBold',
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    TrinaGrid(
                      configuration: TrinaGridConfiguration(
                        style: TrinaGridStyleConfig(
                          rowHeight: c.columnsType == EKennelGridOptions.photos
                              ? KennelHashersController.photoRowHeight
                              : KennelHashersController.standardRowHeight,
                        ),
                      ),
                      key: c.gridKey,
                      columns: c.columns,
                      rows: c.rows,
                      onChanged: (event) async { await c.onGridChanged(event); },
                      onLoaded: (event) { c.onGridLoaded(event); },
                    ),
                    if (c.isMajorUpdate) ...<Widget>[
                      Container(
                        color: Colors.white70,
                        height: 10000,
                        width: 10000,
                      ),
                      Center(child: SpinKitCircle(color: Colors.red.shade900)),
                    ],
                  ],
                ),
              ),
              if (c.columnsType == EKennelGridOptions.addNewMembers) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                        // in order to make sure the value of the current cell
                        // being edited is committed, we have to change the
                        // current cell and also put in a little delay to
                        // give the grid a chance to "catch up".
                        // This is a bit of a hack and we need to find
                        // a better way to handle this.
                        onPressed: () async { await c.saveBulkHashers(); },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
