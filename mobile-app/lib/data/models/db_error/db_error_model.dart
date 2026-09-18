import 'package:harrier_central/imports.dart';

part 'db_error_model.freezed.dart';
part 'db_error_model.g.dart';

@freezed
abstract class DbErrorModel with _$DbErrorModel implements BaseModel {
  factory DbErrorModel({
    String? errorId,
    num? errorType,
    String? errorTitle,
    String? errorUserMessage,
    String? debugMessage,
    String? errorProc,
  }) = _DbErrorModel;

  factory DbErrorModel.fromJson(Map<String, dynamic> json) =>
      _$DbErrorModelFromJson(json);

  @override
  factory DbErrorModel.fromMap(Map<String, dynamic> map) {
    return DbErrorModel.fromJson(map);
  }
}

// import 'package:harrier_central/imports_null_safe.dart';

//     DbErrorModel item;

//     // for queries that return multiple result sets
//     // we need to unpack the inner Error object

//           // isRsvped: jsonItem['isRsvped'],
//           errorId: jsonItem['errorId'].toString(),
//           errorType: jsonItem['errorType'],
//           errorTitle: jsonItem['errorTitle'],
//           errorUserMessage: jsonItem['errorUserMessage'],
//           debugMessage: jsonItem['debugMessage'],
//           errorProc: jsonItem['errorProc'],
//         );

//         items.add(item);
//       },
//     );
