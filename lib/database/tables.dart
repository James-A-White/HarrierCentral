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
      migrationText: '''
      ALTER TABLE ${tableModel.regionsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.regionsTableHelper.colRegionAbbreviation} TEXT;
    ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 352,
      migrationText: '''
      ALTER TABLE ${tableModel.citiesTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.citiesTableHelper.colCitySearchTags} TEXT;
      ALTER TABLE ${tableModel.regionsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.regionsTableHelper.colRegionSearchTags} TEXT;
      ALTER TABLE ${tableModel.countriesTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.countriesTableHelper.colCountrySearchTags} TEXT;
      ALTER TABLE ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.kennelsTableHelper.colKennelSearchTags} TEXT;
    ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 365,
      migrationText: '''
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcTotalRunCount} INT;
      
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcHaringCount} INT;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcHaringCount} INT;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHcHaringCount} INT;

      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colHistoricalTotalRunCount} INT;

      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaring} INT;
      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} INT;
      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRuns} INT;
      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} INT;

      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaring} INT;
      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalHaringThisKennel} INT;
      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRuns} INT;
      ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colTotalRunsThisKennel} INT;

    ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 366,
      migrationText: '''
      ALTER TABLE ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.eventsTableHelper.colEventUrl} TEXT;
      
      ALTER TABLE ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.kennelsTableHelper.colIntegrationType} TEXT;
      ALTER TABLE ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.kennelsTableHelper.colKennelInboundIntegrationId} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.kennelsTableHelper.colKennelEventsUrl} TEXT;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 378,
      migrationText: '''
      ALTER TABLE ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.eventsTableHelper.colEventInboundIntegrationId} INT DEFAULT 0 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 379,
      migrationText: '''
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelCredit} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelCredit} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelCredit} NUM DEFAULT 0 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 380,
      migrationText: '''
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountPercent} INT DEFAULT 0 NOT NULL;
      
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountDescription} TEXT DEFAULT "" NOT NULL;
      
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.paymentsTableHelper.colSpecialRunPriceReason} TEXT DEFAULT "" NOT NULL;
      ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.paymentsTableHelper.colSpecialRunPriceReason} TEXT DEFAULT "" NOT NULL;

      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 381,
      migrationText: '''
      ALTER TABLE ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.kennelsTableHelper.colDisseminateAllowWebLinks} INT DEFAULT 0 NOT NULL;

       ALTER TABLE ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.eventsTableHelper.colEvtDisseminateAllowWebLinks} INT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 392,
      migrationText: '''
      ALTER TABLE ${tableModel.kennelsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.kennelsTableHelper.colPublicKennelId} TEXT NOT NULL;

       ALTER TABLE ${tableModel.eventsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.eventsTableHelper.colPublicEventId} TEXT NOT NULL;
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
      migrationText: '''
     ALTER TABLE ${tableModel.paymentsTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.paymentsTableHelper.colDiscountAmount} NUM DEFAULT 0 NOT NULL;
      ''',
      appliedAtInt: 0,
    ),

    MigrationsModel(
      dbVersion: 417,
      migrationText: '''

        ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${tableModel.hasherKennelMapTableHelper.getTableName(AppDomainType.kennel)} ADD COLUMN ${tableModel.hasherKennelMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.user)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelHashName} TEXT;

        ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelUserPhoto} TEXT;

        ALTER TABLE ${tableModel.hasherEventMapTableHelper.getTableName(AppDomainType.event)} ADD COLUMN ${tableModel.hasherEventMapTableHelper.colKennelHashName} TEXT;
     
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
  ];

  static Future<void> createTables(
    Database db,
    int version,
    Function informUser,
  ) async {
    await tableModel.hashersTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.citiesTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.regionsTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.countriesTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.kennelsTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.hasherKennelMapTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.hasherEventMapTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.eventsTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.paymentsTableHelper.createTable(
      db,
      version,
      AppDomainType.user,
    );
    await NotificationsTableHelper.createTable(db, version);
    await MigrationsTableHelper.createTable(db, version);

    // create event admin tables
    await tableModel.hasherEventMapTableHelper.createTable(
      db,
      version,
      AppDomainType.event,
    );
    await tableModel.hasherKennelMapTableHelper.createTable(
      db,
      version,
      AppDomainType.event,
    );
    await tableModel.paymentsTableHelper.createTable(
      db,
      version,
      AppDomainType.event,
    );
    await tableModel.receiptsTableHelper.createTable(
      db,
      version,
      AppDomainType.event,
    );
    //await tableModel.kennelCreditsTableHelper.createTable(db, version, AppDomainType.event);

    // create kennel admin tables
    await tableModel.hasherKennelMapTableHelper.createTable(
      db,
      version,
      AppDomainType.kennel,
    );
    await tableModel.hasherEventMapTableHelper.createTable(
      db,
      version,
      AppDomainType.kennel,
    );
    await tableModel.paymentsTableHelper.createTable(
      db,
      version,
      AppDomainType.kennel,
    );
  }

  static Future<void> createIndexes(
    Database db,
    int version,
    Function informUser,
    String clientAppIdentifier,
  ) async {
    await tableModel.hashersTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.citiesTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.regionsTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.countriesTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.kennelsTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.hasherKennelMapTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.hasherEventMapTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.eventsTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );
    await tableModel.paymentsTableHelper.createIndexes(
      db,
      version,
      AppDomainType.user,
    );

    // create event admin tables
    await tableModel.hasherEventMapTableHelper.createIndexes(
      db,
      version,
      AppDomainType.event,
    );
    await tableModel.hasherKennelMapTableHelper.createIndexes(
      db,
      version,
      AppDomainType.event,
    );
    await tableModel.paymentsTableHelper.createIndexes(
      db,
      version,
      AppDomainType.event,
    );
    await tableModel.receiptsTableHelper.createIndexes(
      db,
      version,
      AppDomainType.event,
    );
    //await tableModel.kennelCreditsTableHelper.createIndexes(db, version, AppDomainType.event);

    // create kennel admin tables
    await tableModel.hasherKennelMapTableHelper.createIndexes(
      db,
      version,
      AppDomainType.kennel,
    );
  }
}
