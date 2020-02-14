import 'package:harrier_central/data/hc3_services/events_service.dart';
import 'package:harrier_central/util/enums.dart';
import 'package:harrier_central/pages/top_level/kennel_list_page.dart';

import 'package:harrier_central/data/hc3_services/cities_service.dart';
import 'package:harrier_central/data/hc3_services/countries_service.dart';
import 'package:harrier_central/data/hc3_services/regions_service.dart';
import 'package:harrier_central/data/hc3_services/receipts_service.dart';
import 'package:harrier_central/data/hc3_services/payments_service.dart';
import 'package:harrier_central/data/hc3_services/hashers_service.dart';
import 'package:harrier_central/data/hc3_services/kennel_credits_service.dart';
import 'package:harrier_central/data/hc3_services/kennels_service.dart';
import 'package:harrier_central/data/hc3_services/hasher_event_map_service.dart';
import 'package:harrier_central/data/hc3_services/base_service.dart';

List<KennelListAggregate> globalKennelMainPageList;
EnumConnectionStatus<int> globalConnectionStatus;

num deviceWidthScaleFactor;
num deviceHeightScaleFactor;
num deviceMaxScaleFactor;
num deviceMinScaleFactor;

num deviceWidth;

bool hasLocationPermissions = false;

CitiesTableHelper citiesTableHelper;
CountriesTableHelper countriesTableHelper;
RegionsTableHelper regionsTableHelper;
ReceiptsTableHelper receiptsTableHelper;
PaymentsTableHelper paymentsTableHelper;
HashersTableHelper hashersTableHelper;
KennelCreditsTableHelper kennelCreditsTableHelper;
KennelsTableHelper kennelsTableHelper;
EventsTableHelper eventsTableHelper;
HasherEventMapTableHelper hasherEventMapTableHelper;

BaseService baseService;
HashersService hashersService;
PaymentsService paymentsService;
EventsService eventsService;
HasherEventMapService hasherEventMapService;

void initializeGlobals() {
  citiesTableHelper = CitiesTableHelper();
  countriesTableHelper = CountriesTableHelper();
  regionsTableHelper = RegionsTableHelper();
  receiptsTableHelper = ReceiptsTableHelper();
  paymentsTableHelper = PaymentsTableHelper();
  hashersTableHelper = HashersTableHelper();
  kennelCreditsTableHelper = KennelCreditsTableHelper();
  kennelsTableHelper = KennelsTableHelper();
  eventsTableHelper = EventsTableHelper();
  hasherEventMapTableHelper = HasherEventMapTableHelper();

  baseService = BaseService();
  hashersService = HashersService();
  paymentsService = PaymentsService();
  eventsService = EventsService();
  hasherEventMapService = HasherEventMapService();
}
