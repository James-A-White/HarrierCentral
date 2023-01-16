// // @dart=2.11
// import 'package:harrier_central/imports.dart';

// part 'kennel_credits_service.g.dart';

// @JsonSerializable(fieldRename: FieldRename.none)
// class KennelCreditsModel implements BaseModel {
//   KennelCreditsModel({
//     this.kennelCreditId,
//     this.userId,
//     this.kennelId,
//     this.currentBalance,
//     this.balanceAsOfEventId,
//     this.updatedAt,
//     this.removed,
//   });

//   factory KennelCreditsModel.fromJson(Map<String, dynamic> json) => _$KennelCreditsModelFromJson(json);

//   Map<String, dynamic> toJson() => _$KennelCreditsModelToJson(this);

//   final String kennelCreditId;
//   final String userId;
//   final String kennelId;
//   final num currentBalance;
//   final String balanceAsOfEventId;
//   final DateTime updatedAt;
//   final int removed;
// }

// class KennelCreditsTableHelper extends BaseTableHelper with BaseFields {
//   KennelCreditsTableHelper() {
//     remoteDbId = 'kennelCreditId';
//     humanReadableTableName = 'Kennels';
//     pageSize = 250;
//   }

//   // @override
//   // String tableName = 'kennelCredits';

//   @override
//   String getTableName(dynamic appDomainType) {
//     String tableName;
//     switch (appDomainType) {
//       // case AppDomainType.event:
//       //   break;
//       // case AppDomainType.kennel:
//       //   break;
//       // case AppDomainType.user:
//       //   tableName = 'hashers';
//       //   break;
//       default:
//         tableName = 'kennelCredits';
//     }
//     return tableName;
//   }

//   final String colKennelCreditId = 'kennelCreditId';
//   final String colUserId = 'userId';
//   final String colKennelId = 'kennelId';
//   final String colCurrentBalance = 'currentBalance';
//   final String colBalanceAsOfEventId = 'balanceAsOfEventId';

//   @override
//   Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
//     final String tableName = getTableName(appDomainType);
//     await db.execute('''
//           CREATE TABLE $tableName (
//             $colId INTEGER PRIMARY KEY,

//             $colKennelCreditId TEXT,
//             $colUserId TEXT,
//             $colKennelId TEXT,
//             $colCurrentBalance NUM,
//             $colBalanceAsOfEventId TEXT,

//             $colRemoved NUM,
//             $colUpdatedAt TEXT,
//             $colUpdatedAtValue INT NULL
//           )
//           ''');
//   }

//   @override
//   Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
//     await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
//     await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
//   }

//   // @override
//   // Map<String, dynamic> toMap(dynamic item) {
//   //   final Map<String, dynamic> map = _$KennelCreditsModelToJson(item);
//   //   return map;
//   // }

//   @override
//   Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
//     return KennelCreditsModel.fromJson(inputMap).toJson();
//   }

//   @override
//   KennelCreditsModel fromMap(Map<String, dynamic> map) {
//     return KennelCreditsModel.fromJson(map);
//   }
// }
