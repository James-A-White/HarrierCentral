import 'package:harrier_central/imports.dart';

part 'approve_login_model.freezed.dart';
part 'approve_login_model.g.dart';

@freezed
abstract class ApproveLoginModel with _$ApproveLoginModel implements BaseModel {
  factory ApproveLoginModel({
    String? apiVersion,
    int? approvalCode,
    String? loginMessage,
    String? loginMessageTitle,
    int? serverStatusCode,
    DateTime? messageEndDate,
    int? messageDisplayType,
    String? iosDownloadLink,
    String? androidDownloadLink,
    String? imageRootUrl,
    int? isBetaTester,
    String? email,
    String? homeKennelId,
    DateTime? thirdPartyForceTokenRefresh,
    String? splashSequenceRootName,
    int? splashSequenceType,
    String? betaFeaturesEnabled,
    int? hasherPreferences,
  }) = _ApproveLoginModel;

  factory ApproveLoginModel.fromJson(Map<String, dynamic> json) =>
      _$ApproveLoginModelFromJson(json);

  @override
  factory ApproveLoginModel.fromMap(Map<String, dynamic> map) {
    return ApproveLoginModel.fromJson(map);
  }
}

// import 'package:harrier_central/imports.dart';

//       {this.apiVersion,

//     ApproveLoginModel item;

//     final dynamic jResult = json.decode(jsonResult);

//           // isRsvped: jsonItem['isRsvped'],
//           apiVersion: jsonItem['apiVersion'],
//           approvalCode: jsonItem['approvalCode'],
//           serverStatusCode: jsonItem['serverStatusCode'],
//           loginMessage: jsonItem['loginMessage'],
//           loginMessageTitle: jsonItem['loginMessageTitle'],
//           messageEndDate: DateTime.parse(jsonItem['serverStatusEndDate'] ?? '2000-01-01 19:00:00'),
//           messageDisplayType: jsonItem['messageDisplayType'],
//           iosDownloadLink: jsonItem['iosDownloadLink'],
//           androidDownloadLink: jsonItem['androidDownloadLink'],
//           imageRootUrl: jsonItem['imageRootUrl'],
//           isBetaTester: jsonItem['isBetaTester'],
//           email: jsonItem['email'],
//           homeKennelId: jsonItem['homeKennelId'],

//         items.add(item);
//       },
//     );
