import 'package:harrier_central/imports.dart';

// TODO(James): Add an "All" category to AppDomainType for tables that exist across all appDomains
enum AppDomainType { user, event, kennel }
//enum TableType { baseTable, hemUser, hemEventAdmin, hkmUser, hkmEventAdmin, hkmKennelAdmin, paymentsUser, paymentsEvent }

class Tables {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  // static String getTableName(BaseTableHelper tableHelper, {AppDomainType appDomainType}) {
  //   String tableName = tableHelper.tableName;
  //   if (tableType != null) {
  //     switch (tableType) {
  //       case TableType.baseTable:
  //         // don't change the string, keep it as it was initialized above
  //         break;
  //       case TableType.hemEventAdmin:
  //         tableName = hemAdminTable;
  //         break;
  //       case TableType.hemUser:
  //         tableName = hemUserTable;
  //         break;
  //       case TableType.hkmUser:
  //         tableName = hkmUserTable;
  //         break;
  //       case TableType.hkmEventAdmin:
  //         tableName = hkmEventAdminTable;
  //         break;
  //       case TableType.hkmKennelAdmin:
  //         tableName = hkmKennelAdminTable;
  //         break;
  //       case TableType.paymentsEvent:
  //         tableName = eventPaymentsTable;
  //         break;
  //       case TableType.paymentsUser:
  //         tableName = userPaymentsTable;
  //         break;
  //       default:
  //         // this will cause a SQL error and help us debug, should put a debug assert here
  //         assert(false);
  //         tableName = '';
  //         break;
  //     }
  //   }

  //   return tableName;
  // }

  // *****************
  // DB migrations & version

  static List<MigrationsModel> migrationList = <MigrationsModel>[
    // MIGRATION 270
    MigrationsModel(
      dbVersion: 351,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.regions.commonTableName} ADD COLUMN ${tableModel.regionsTableHelper.colRegionAbbreviation} TEXT;
    ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 352,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.cities.commonTableName} ADD COLUMN ${tableModel.citiesTableHelper.colCitySearchTags} TEXT;
      ALTER TABLE ${EnumDataTables.regions.commonTableName} ADD COLUMN ${tableModel.regionsTableHelper.colRegionSearchTags} TEXT;
      ALTER TABLE ${EnumDataTables.countries.commonTableName} ADD COLUMN ${tableModel.countriesTableHelper.colCountrySearchTags} TEXT;
      ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colKennelSearchTags} TEXT;
    ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 365,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      
      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcHaringCount} INT;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcHaringCount} INT;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcHaringCount} INT;

      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;

      ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaring} INT;
      ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} INT;
      ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRuns} INT;
      ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} INT;

      ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaring} INT;
      ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} INT;
      ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRuns} INT;
      ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} INT;

    ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 366,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.events.commonTableName} ADD COLUMN ${tableModel.eventsTableHelper.colEventUrl} TEXT;
      
      ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colIntegrationType} TEXT;
      ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colKennelInboundIntegrationId} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colKennelEventsUrl} TEXT;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 378,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.events.commonTableName} ADD COLUMN ${tableModel.eventsTableHelper.colEventInboundIntegrationId} INT DEFAULT 0 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 379,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelCredit} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelCredit} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelCredit} NUM DEFAULT 0 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 380,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      
      ALTER TABLE ${EnumDataTables.payments.eventTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.payments.commonTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${EnumDataTables.payments.eventTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${EnumDataTables.payments.commonTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${EnumDataTables.payments.eventTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${EnumDataTables.payments.commonTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      
      ALTER TABLE ${EnumDataTables.payments.eventTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colSpecialRunPriceReason} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${EnumDataTables.payments.commonTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colSpecialRunPriceReason} TEXT DEFAULT "" NOT NULL;

      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 381,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colDisseminateAllowWebLinks} INT DEFAULT 0 NOT NULL;

       ALTER TABLE ${EnumDataTables.events.commonTableName} ADD COLUMN ${tableModel.eventsTableHelper.colEvtDisseminateAllowWebLinks} INT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 392,
      migrationText:
          '''
      ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colPublicKennelId} TEXT NOT NULL;

       ALTER TABLE ${EnumDataTables.events.commonTableName} ADD COLUMN ${tableModel.eventsTableHelper.colPublicEventId} TEXT NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 405,
      migrationText: '''
        -- DB structure not changed, but migration required to accommodate for
        -- a change in the values stored in the [updatedAtValue] field
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 416,
      migrationText:
          '''
     ALTER TABLE ${EnumDataTables.payments.commonTableName} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 417,
      migrationText:
          '''

        ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${EnumDataTables.hasherKennelMap.commonTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${EnumDataTables.hasherKennelMap.eventTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${EnumDataTables.hasherKennelMap.kennelTableName} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelHashName} TEXT;
     
      ''',
      appliedAtInt: 0,
    ),

    // force rebuild of database to account for nullable / non-nullable
    // fields being defined properly
    MigrationsModel(
      dbVersion: 430,
      migrationText: '''
        -- DB structure not changed, but migration required to accommodate for
        -- a change in the values stored in the [updatedAtValue] field
      ''',
      appliedAtInt: 0,
    ),

    // force rebuild of database to account for nullable / non-nullable
    // fields being defined properly
    MigrationsModel(
      dbVersion: 440,
      migrationText: '''
        -- Major upgrade to App to support NULL SAFETY along with migration of
        -- the APIs from Azure Mobile Services to Azure Functions. Bumped Database
        -- version by 10 to force a rebuild of the internal data structures upon 
        -- an app upgrade.
      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 450,
      migrationText: '''
        -- Added KennelUniqueShortName field to KennelsModel. No need for migration as
        -- we don't have any active users. Bumping to 450 will cause a reload for our testers
      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 460,
      migrationText: '''
        -- Bump DB Version
      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 470,
      migrationText: '''
        -- Bump DB Version
      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 480,
      migrationText: '''
        -- Bump DB Version
      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 490,
      migrationText: '''
        -- Bump DB Version to test that DB rebuild works correctly in 2.0
      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 491,
      migrationText:
          '''

        DELETE FROM ${EnumDataTables.cities.commonTableName};
        
        DELETE FROM ${EnumDataTables.events.commonTableName};

        DELETE FROM ${EnumDataTables.hasherEventMap.commonTableName};

        DELETE FROM ${EnumDataTables.hasherEventMap.kennelTableName};

        DELETE FROM ${EnumDataTables.hasherEventMap.eventTableName};

        ALTER TABLE ${EnumDataTables.cities.commonTableName} ADD COLUMN ${tableModel.citiesTableHelper.colIanaTimeZone} TEXT NOT NULL DEFAULT 'Europe/London';

        ALTER TABLE ${EnumDataTables.events.commonTableName} ADD COLUMN ${tableModel.eventsTableHelper.colEventStartDatetimeGmt} TEXT NOT NULL;

        ALTER TABLE ${EnumDataTables.hasherEventMap.commonTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colEventStartDatetimeGmt} TEXT NOT NULL;

        ALTER TABLE ${EnumDataTables.hasherEventMap.kennelTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colEventStartDatetimeGmt} TEXT NOT NULL;

        ALTER TABLE ${EnumDataTables.hasherEventMap.eventTableName} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colEventStartDatetimeGmt} TEXT NOT NULL;

      ''',
      appliedAtInt: 0,
    ),
    MigrationsModel(
      dbVersion: 510,
      migrationText: '''
        -- Bump DB Version to test that DB rebuild works correctly in 2.0
      ''',
      appliedAtInt: 0,
    ),

    // MIGRATION 511 — Create songs table for existing installs
    MigrationsModel(
      dbVersion: 511,
      migrationText:
          '''
        CREATE TABLE IF NOT EXISTS ${EnumDataTables.songs.commonTableName} (
          ${tableModel.songsTableHelper.colId} INTEGER PRIMARY KEY,
          ${tableModel.songsTableHelper.colSongId} TEXT NOT NULL,
          ${tableModel.songsTableHelper.colSongName} TEXT NOT NULL,
          ${tableModel.songsTableHelper.colTuneOf} TEXT,
          ${tableModel.songsTableHelper.colBawdyRating} INT NOT NULL,
          ${tableModel.songsTableHelper.colNotes} TEXT,
          ${tableModel.songsTableHelper.colActions} TEXT,
          ${tableModel.songsTableHelper.colVariants} TEXT,
          ${tableModel.songsTableHelper.colImageUrl} TEXT,
          ${tableModel.songsTableHelper.colAudioUrl} TEXT,
          ${tableModel.songsTableHelper.colAutoAddToKennel} INT NOT NULL,
          ${tableModel.songsTableHelper.colRank} INT NOT NULL,
          ${tableModel.songsTableHelper.colAddedByKennelId} TEXT,
          ${tableModel.songsTableHelper.colAddedByUserId} TEXT,
          ${tableModel.songsTableHelper.colLyrics} TEXT NOT NULL,
          ${tableModel.songsTableHelper.colTags} TEXT,
          ${tableModel.songsTableHelper.colRemoved} INT NOT NULL,
          ${tableModel.songsTableHelper.colUpdatedAt} TEXT NOT NULL,
          ${tableModel.songsTableHelper.colUpdatedAtValue} INT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_${EnumDataTables.songs.commonTableName}_id ON ${EnumDataTables.songs.commonTableName}(${tableModel.songsTableHelper.colSongId});
        CREATE INDEX IF NOT EXISTS idx_${EnumDataTables.songs.commonTableName}_update_at_value ON ${EnumDataTables.songs.commonTableName}(${tableModel.songsTableHelper.colUpdatedAtValue});
      ''',
      appliedAtInt: 0,
    ),

    // MIGRATION 521 — Move device reset code to flutter_secure_storage
    // No SQLite schema changes; the secure storage migration happens in
    // app_boot_service._handleDbUpgrade before the DB is touched.
    MigrationsModel(
      dbVersion: 521,
      migrationText: '',
      appliedAtInt: 0,
    ),

    // MIGRATION 522 — Per-kennel trail symbol configuration
    MigrationsModel(
      dbVersion: 522,
      migrationText: '''
        ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colTrailSymbolsConfigJson} TEXT;
      ''',
      appliedAtInt: 0,
    ),

    // MIGRATION 523 — Per-kennel PackTrack trail-type configuration
    MigrationsModel(
      dbVersion: 523,
      migrationText: '''
        ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colTrailTypesConfigJson} TEXT;
      ''',
      appliedAtInt: 0,
    ),

    // MIGRATION 524 — Per-kennel "allow credit payments" setting (default on)
    MigrationsModel(
      dbVersion: 524,
      migrationText: '''
        ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colAllowCredit} INT DEFAULT 1 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    // MIGRATION 525 — Per-kennel permission override JSON (Permissions V2)
    MigrationsModel(
      dbVersion: 525,
      migrationText: '''
        ALTER TABLE ${EnumDataTables.kennels.commonTableName} ADD COLUMN ${tableModel.kennelsTableHelper.colPermissionOverrideJson} TEXT;
      ''',
      appliedAtInt: 0,
    ),

    // MIGRATION 526 — Event cover photo URL (from a Cover-tagged run photo)
    MigrationsModel(
      dbVersion: 526,
      migrationText: '''
        ALTER TABLE ${EnumDataTables.events.commonTableName} ADD COLUMN ${tableModel.eventsTableHelper.colEventCoverPhotoUrl} TEXT;
      ''',
      appliedAtInt: 0,
    ),

  ];

  static Future<void> createTables(
    Database db,
    int version,
    Function informUser,
  ) async {
    for (final dataTable in EnumDataTables.values) {
      final helper = dataTable.helperFrom(tableModel);
      if (dataTable.hasCommonTable) {
        await helper.createTable(db, version, AppDomainType.user);
      }
      if (dataTable.hasEventTable) {
        await helper.createTable(db, version, AppDomainType.event);
      }
      if (dataTable.hasKennelTable) {
        await helper.createTable(db, version, AppDomainType.kennel);
      }
    }

    await NotificationsTableHelper.createTable(db, version);
    await MigrationsTableHelper.createTable(db, version);
  }

  static Future<void> createIndexes(
    Database db,
    int version,
    void Function(String)? informUser,
    String clientAppIdentifier,
  ) async {
    for (final dataTable in EnumDataTables.values) {
      final helper = dataTable.helperFrom(tableModel);
      if (dataTable.hasCommonTable) {
        await helper.createIndexes(db, version, AppDomainType.user);
      }
      if (dataTable.hasEventTable) {
        await helper.createIndexes(db, version, AppDomainType.event);
      }
      if (dataTable.hasKennelTable) {
        await helper.createIndexes(db, version, AppDomainType.kennel);
      }
    }
  }
}
