import 'package:harrier_central/imports.dart';

class SongsTableHelper extends BaseTableHelper<AppDomainType> with BaseFields {
  SongsTableHelper() {
    remoteDbId = 'songId';
    humanReadableTableName = 'Songs';
    pageSize = SyncUserDataService.pageSize_songsTable;
    tableFlag = EnumDataTables.songs.flag;
  }

  @override
  String getTableName(AppDomainType appDomainType) {
    String tableName;
    switch (appDomainType) {
      case AppDomainType.user:
        tableName = EnumDataTables.songs.commonTableName;
        break;
      default:
        throw Exception(
          'EnumDataTables.${EnumDataTables.songs.name} does not have a table associated with it.',
        );
    }
    return tableName;
  }

  final String colSongId = 'songId';
  final String colSongName = 'songName';
  final String colTuneOf = 'tuneOf';
  final String colBawdyRating = 'bawdyRating';
  final String colNotes = 'notes';
  final String colActions = 'actions';
  final String colVariants = 'variants';
  final String colImageUrl = 'imageUrl';
  final String colAudioUrl = 'audioUrl';
  final String colAutoAddToKennel = 'autoAddToKennel';
  final String colRank = 'rank';
  final String colAddedByKennelId = 'addedByKennelId';
  final String colAddedByUserId = 'addedByUserId';
  final String colLyrics = 'lyrics';
  final String colTags = 'tags';

  @override
  Future<dynamic> createTable(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colSongId TEXT NOT NULL,
            $colSongName TEXT NOT NULL,
            $colTuneOf TEXT,
            $colBawdyRating INT NOT NULL,
            $colNotes TEXT,
            $colActions TEXT,
            $colVariants TEXT,
            $colImageUrl TEXT,
            $colAudioUrl TEXT,
            $colAutoAddToKennel INT NOT NULL,
            $colRank INT NOT NULL,
            $colAddedByKennelId TEXT,
            $colAddedByUserId TEXT,
            $colLyrics TEXT NOT NULL,
            $colTags TEXT,
            $colRemoved INT NOT NULL,
            $colUpdatedAt TEXT NOT NULL,
            $colUpdatedAtValue INT NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(
    Database db,
    int version,
    dynamic appDomainType,
  ) async {
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);',
    );
    await db.execute(
      'CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);',
    );
  }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    return SongsModel.fromJson(inputMap).toJson();
  }

  @override
  SongsModel fromMap(Map<String, dynamic> map) {
    return SongsModel.fromJson(map);
  }
}
