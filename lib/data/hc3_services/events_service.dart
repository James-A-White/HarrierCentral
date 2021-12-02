// @dart=2.11
import 'package:harrier_central/imports.dart';

part 'events_service.g.dart';

@JsonSerializable(fieldRename: FieldRename.none)
class EventModel implements BaseModel {
  EventModel(
      {this.eventId,
      this.eventStartDatetime,
      this.kennelId,
      this.isVisible,
      this.isCountedRun,
      this.isPromotedEvent,
      this.eventGeographicScope,
      this.eventInboundIntegrationId,
      this.eventNumber,
      this.eventName,
      this.hcLatitude,
      this.hcLongitude,
      this.fbLatitude,
      this.fbLongitude,
      this.eventPriceForMembers,
      this.eventPriceForNonMembers,
      this.eventFacebookId,
      this.absoluteEventNumber,
      this.canEditRunAttendence,
      this.eventImage,
      this.eventDescription,
      this.eventUrl,
      this.locationOneLineDesc,
      this.locationPostCode,
      this.locationCity,
      this.locationStreet,
      this.locationCountry,
      this.locationRegion,
      this.locationSubRegion,
      this.hares,
      this.eventPaymentScheme,
      this.eventPaymentUrl,
      this.eventPaymentUrlExpires,
      this.unconfirmedBankXferCount,
      this.eventPriceForExtras,
      this.extrasDescription,
      this.doTrackHashCash,
      this.tags1,
      this.tags2,
      this.tags3,
      this.useFbLatLon,
      this.useFbLocation,
      this.useFbRunDetails,
      this.useFbImage,
      this.removed,
      this.updatedAt});

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  final String eventId;
  final DateTime eventStartDatetime;
  final String kennelId;
  final int isVisible;
  final int isCountedRun;
  final int isPromotedEvent;
  final int eventGeographicScope;
  final int eventInboundIntegrationId;
  final int eventNumber;
  final String eventName;
  final num hcLatitude;
  final num hcLongitude;
  final num fbLatitude;
  final num fbLongitude;
  final num eventPriceForMembers;
  final num eventPriceForNonMembers;
  final String eventFacebookId;
  final num absoluteEventNumber;
  final num canEditRunAttendence;
  String eventImage;
  final String eventDescription;
  final String eventUrl;
  final String locationOneLineDesc;
  final String locationPostCode;
  final String locationCity;
  final String locationStreet;
  final String locationCountry;
  final String locationRegion;
  final String locationSubRegion;
  String hares;
  final String eventPaymentScheme;
  final String eventPaymentUrl;
  final DateTime eventPaymentUrlExpires;
  final int unconfirmedBankXferCount;
  final num eventPriceForExtras;
  final String extrasDescription;
  final int doTrackHashCash;
  final int tags1;
  final int tags2;
  final int tags3;
  final int useFbLocation;
  final int useFbLatLon;
  final int useFbRunDetails;
  final int useFbImage;

  final int removed;
  final DateTime updatedAt;
}

class EventsTableHelper extends BaseTableHelper with BaseFields {
  EventsTableHelper() {
    remoteDbId = 'eventId';
    humanReadableTableName = 'Events';
  }

  @override
  String getTableName(dynamic appDomainType) {
    String tableName;
    switch (appDomainType) {
      // case AppDomainType.event:
      //   break;
      // case AppDomainType.kennel:
      //   break;
      // case AppDomainType.user:
      //   tableName = 'narrowEvents';
      //   break;
      default:
        tableName = 'narrowEvents';
    }
    return tableName;
  }

  final String colEventId = 'eventId';
  final String colEventStartDatetime = 'eventStartDatetime';
  final String colKennelId = 'kennelId';
  final String colIsVisible = 'isVisible';
  final String colIsCountedRun = 'isCountedRun';
  final String colIsPromotedEvent = 'isPromotedEvent';
  final String colEventGeographicScope = 'eventGeographicScope';
  final String colEventInboundIntegrationId = 'eventInboundIntegrationId';
  final String colEventNumber = 'eventNumber';
  final String colEventName = 'eventName';
  final String colHcLatitude = 'hcLatitude';
  final String colHcLongitude = 'hcLongitude';
  final String colFbLatitude = 'fbLatitude';
  final String colFbLongitude = 'fbLongitude';
  final String colEventPriceForMembers = 'eventPriceForMembers';
  final String colEventPriceForNonMembers = 'eventPriceForNonMembers';
  final String colEventFacebookId = 'eventFacebookId';
  final String colAbsoluteEventNumber = 'absoluteEventNumber';
  final String colCanEditRunAttendence = 'canEditRunAttendence';
  final String colEventImage = 'eventImage';
  final String colEventDescription = 'eventDescription';
  final String colEventUrl = 'eventUrl';
  final String colLocationOneLineDesc = 'locationOneLineDesc';
  final String colLocationPostCode = 'locationPostCode';
  final String colLocationCity = 'locationCity';
  final String colLocationStreet = 'locationStreet';
  final String colLocationCountry = 'locationCountry';
  final String colLocationRegion = 'locationRegion';
  final String colLocationSubRegion = 'locationSubRegion';
  final String colHares = 'hares';
  final String colEventPaymentScheme = 'eventPaymentScheme';
  final String colEventPaymentUrl = 'eventPaymentUrl';
  final String colEventPaymentUrlExpires = 'eventPaymentUrlExpires';
  final String colUnconfirmedBankXferCount = 'unconfirmedBankXferCount';
  final String colEventPriceForExtras = 'eventPriceForExtras';
  final String colExtrasDescription = 'extrasDescription';
  final String colDoTrackHashCash = 'doTrackHashCash';
  final String colTags1 = 'tags1';
  final String colTags2 = 'tags2';
  final String colTags3 = 'tags3';

  final String colUseFbLocation = 'useFbLocation';
  final String colUseFbLatLon = 'useFbLatLon';
  final String colUseFbRunDetails = 'useFbRunDetails';
  final String colUseFbImage = 'useFbImage';

  @override
  Future<dynamic> createTable(Database db, int version, dynamic appDomainType) async {
    final String tableName = getTableName(appDomainType);
    await db.execute('''
          CREATE TABLE $tableName (
            $colId INTEGER PRIMARY KEY,

            $colEventId TEXT NOT NULL,
            $colEventStartDatetime TEXT,
            $colKennelId TEXT NOT NULL,
            $colIsVisible INT,
            $colIsCountedRun INT,
            $colIsPromotedEvent INT,
            $colEventGeographicScope INT,
            $colEventInboundIntegrationId INT,
            $colEventNumber INT,
            $colEventName TEXT,
            $colHcLatitude NUM,
            $colHcLongitude NUM,
            $colFbLatitude NUM,
            $colFbLongitude NUM,
            $colEventPriceForMembers NUM,
            $colEventPriceForNonMembers NUM,
            $colEventFacebookId TEXT,
            $colAbsoluteEventNumber NUM,
            $colCanEditRunAttendence NUM,
            $colEventImage TEXT,
            $colEventDescription TEXT,
            $colEventUrl TEXT,
            $colLocationOneLineDesc TEXT,
            $colLocationPostCode TEXT,
            $colLocationCity TEXT,
            $colLocationStreet TEXT,
            $colLocationCountry TEXT,
            $colLocationRegion TEXT,
            $colLocationSubRegion TEXT,
            $colHares TEXT,
            $colEventPaymentScheme TEXT,
            $colEventPaymentUrl TEXT,
            $colEventPaymentUrlExpires TEXT,
            $colUnconfirmedBankXferCount INT,
            $colEventPriceForExtras NUM,
            $colExtrasDescription TEXT,
            $colDoTrackHashCash INT,
            $colTags1 INT,
            $colTags2 INT,
            $colTags3 INT,
            $colUseFbLatLon INT,
            $colUseFbLocation INT,
            $colUseFbRunDetails INT,
            $colUseFbImage INT,

            $colRemoved NUM,
            $colUpdatedAt TEXT,
            $colUpdatedAtValue NUM NULL
          )
          ''');
  }

  @override
  Future<void> createIndexes(Database db, int version, dynamic appDomainType) async {
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_id ON ${getTableName(appDomainType)}($remoteDbId);');
    await db.execute('CREATE INDEX idx_${getTableName(appDomainType)}_update_at_value ON ${getTableName(appDomainType)}($colUpdatedAtValue);');
  }

  // @override
  // Map<String, dynamic> toMap(dynamic item) {
  //   final Map<String, dynamic> map = _$EventModelToJson(item);
  //   return map;
  // }

  @override
  Map<String, dynamic> normalizeMap(Map<String, dynamic> inputMap) {
    final Map<String, dynamic> outputMap = _$EventModelToJson(EventModel.fromJson(inputMap));

    // NOTE: Event images can either be full URLs or they can be partial URLs in the case
    // when events have been uploaded directly to the DB using the HcWeb application.
    // For partial URLs we need to append the root URL. The Root URL is stored in the
    // Server settings table and copied into the string prefs on app startup.
    if ((outputMap['eventImage'] != null) && (outputMap['eventImage'].isNotEmpty) && (!outputMap['eventImage'].startsWith('http'))) {
      final String s = getStringPref(StringPrefsEnum.imageRootUrl) ?? BASE_HCWEB_UPLOAD_URL;
      if ((s != null) && (s.isNotEmpty)) {
        outputMap['eventImage'] = s + outputMap['eventImage'];
      }
    }

    return outputMap;
  }

  @override
  EventModel fromMap(Map<String, dynamic> map) {
    final EventModel item = EventModel.fromJson(map);

    // NOTE: Event images can either be full URLs or they can be partial URLs in the case
    // when events have been uploaded directly to the DB using the HcWeb application.
    // For partial URLs we need to append the root URL. The Root URL is stored in the
    // Server settings table and copied into the string prefs on app startup.
    if ((item.eventImage != null) && (item.eventImage.isNotEmpty) && (!item.eventImage.startsWith('http'))) {
      final String s = getStringPref(StringPrefsEnum.imageRootUrl) ?? BASE_HCWEB_UPLOAD_URL;
      if ((s != null) && (s.isNotEmpty)) {
        item.eventImage = s + item.eventImage;
      }
    }

    return item;
  }
}

class EventsService extends BaseService {
  Future<String> addEditEvent({
    String eventId,
    bool isVisible,
    bool isCountedRun,
    bool isPromotedEvent,
    int eventGeographicScope,
    int usersCanEditRunAttendence,
    int absoluteEventNumber,
    String kennelId,
    String eventName,
    DateTime eventStartDatetime,
    num lat,
    num lon,
    int useFbLatLon,
    int useFbRunDetails,
    int useFbImage,
    int useFbLocation,
    String eventDescription,
    num eventPriceForMembers,
    num eventPriceForNonMembers,
    num eventPriceForExtras,
    String extrasDescription,
    String locationOneLineDesc,
    String eventImageUrl,
    String hares,
  }) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return '';
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = IveCoreUtilities.generateToken(userId, 'addEditEvent');

    final num _eventsLastUpdated = await getLastUpdatedTime(
      G0<Database>(),
      G0<TableModel>().eventsTableHelper,
      G0<TableModel>().eventsTableHelper.getTableName(AppDomainType.user),
      G0<TableModel>().eventsTableHelper.colUpdatedAtValue,
    );
    final DateTime eventUpdatedAfter = _eventsLastUpdated == null ? DateTime(2000, 1, 1) : DateTime.fromMillisecondsSinceEpoch(_eventsLastUpdated + 1000);

    final Map<String, String> bodyMap = <String, String>{'userId': userId, 'accessToken': accessToken, 'narrowEventsUpdatedAfter': eventUpdatedAfter.toString()};
    if (isVisible != null) {
      bodyMap.addAll(<String, String>{'isVisible': isVisible ? '1' : '0'});
    }

    if (isCountedRun != null) {
      bodyMap.addAll(<String, String>{'isCountedRun': isCountedRun ? '1' : '0'});
    }

    if (isPromotedEvent != null) {
      bodyMap.addAll(<String, String>{'isPromotedEvent': isPromotedEvent ? '1' : '0'});
    }

    if (eventGeographicScope != null) {
      bodyMap.addAll(<String, String>{'eventGeographicScope': eventGeographicScope.toString()});
    }

    if (usersCanEditRunAttendence != null) {
      bodyMap.addAll(<String, String>{'usersCanEditRunAttendence': usersCanEditRunAttendence.toString()});
    }

    if (eventImageUrl != null) {
      bodyMap.addAll(<String, String>{'coverPhotoUrl': eventImageUrl});
    }

    if (absoluteEventNumber != null) {
      bodyMap.addAll(<String, String>{'absoluteEventNumber': absoluteEventNumber.toString()});
    }

    if (eventId != null) {
      bodyMap.addAll(<String, String>{'eventId': eventId});
    }

    if (kennelId != null) {
      bodyMap.addAll(<String, String>{'kennelId': kennelId});
    }

    if (eventName != null) {
      bodyMap.addAll(<String, String>{'eventName': eventName});
    }

    if (eventStartDatetime != null) {
      bodyMap.addAll(<String, String>{'startDatetime': eventStartDatetime.toString()});
    }

    if (lat != null) {
      bodyMap.addAll(<String, String>{'latitude': lat.toString()});
    }

    if (lon != null) {
      bodyMap.addAll(<String, String>{'longitude': lon.toString()});
    }

    if (useFbLatLon != null) {
      bodyMap.addAll(<String, String>{'useFbLatLon': useFbLatLon.toString()});
    }

    if (useFbRunDetails != null) {
      bodyMap.addAll(<String, String>{'useFbRunDetails': useFbRunDetails.toString()});
    }

    if (useFbImage != null) {
      bodyMap.addAll(<String, String>{'useFbImage': useFbImage.toString()});
    }

    if (useFbLocation != null) {
      bodyMap.addAll(<String, String>{'useFbLocation': useFbLocation.toString()});
    }

    if (eventDescription != null) {
      bodyMap.addAll(<String, String>{'eventDescription': eventDescription});
    }

    if (hares != null) {
      bodyMap.addAll(<String, String>{'hares': hares});
    }

    if (locationOneLineDesc != null) {
      bodyMap.addAll(<String, String>{'locationOneLineDesc': locationOneLineDesc});
    }

    if (eventPriceForMembers != null) {
      bodyMap.addAll(<String, String>{'eventPriceForMembers': eventPriceForMembers.toString()});
    }

    if (eventPriceForNonMembers != null) {
      bodyMap.addAll(<String, String>{'eventPriceForNonMembers': eventPriceForNonMembers.toString()});
    }

    if (eventPriceForExtras != null) {
      bodyMap.addAll(<String, String>{'eventPriceForExtras': eventPriceForExtras.toString()});
    }

    if (extrasDescription != null) {
      bodyMap.addAll(<String, String>{'extrasDescription': extrasDescription});
    }

    final String body = jsonEncode(bodyMap);

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_add_edit_event', body);

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      await G0<TableModel>().syncUserDataService.updateSqlTablesWithResultsFromBackendApiCall(responseBody);
    }

    final dynamic responseJson = jsonDecode(responseBody);

    if (responseJson.length > 0) {
      if (responseJson[0].length > 0) {
        eventId = responseJson[0][0]['eventId'];
      }
    }

    return eventId;
  }

  Future<Map<String, String>> sendRunDetailsByEmail({String eventId, String emailBody = ''}) async {
    final String userId = getStringPref(StringPrefsEnum.userId);
    final String accessToken = IveCoreUtilities.generateToken(userId, 'rptApi_emailRunDetails', paramString: eventId);

    final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken': accessToken, 'eventId': eventId, 'emailBody': emailBody});

    //print(body);

    final Response response = await post(Uri.parse(EMAIL_RUN_DETAILS_TO_PACK_API_URL), headers: <String, String>{'content-type': 'application/json'}, body: body
            // Send authorization headers to your backend
            //headers: {HttpHeaders.authorizationHeader: 'Basic your_api_token_here'},
            )
        .catchError(
      (dynamic error) {
        return Future<Response>.value(null);
      },
    );

    return <String, String>{'result': response.body};
  }
}
