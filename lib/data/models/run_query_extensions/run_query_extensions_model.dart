import 'package:harrier_central/imports.dart';

import 'package:intl/intl.dart';

part 'run_query_extensions_model.freezed.dart';
part 'run_query_extensions_model.g.dart';

@freezed
class RunQueryExtensionsModel with _$RunQueryExtensionsModel implements BaseModel {
  factory RunQueryExtensionsModel({
    @Default(0) int daysUntilEvent,
    @Default(0) int appAccessFlags,
    @Default(2) int digitsAfterDecimal,
    @Default(r'$^') String currencySymbol,
    @Default(0) int rsvpState,
    @Default(0) int attendenceState,
    @Default(0) int isPaid,
    @Default(0) int isHare,
    @Default(0) int isMember,
    @Default(0) int following,
    @Default(0) int notificationPreference,
    @Default(0) int emailAlertPreference,
    @Default(0) int distanceUnitsPref,
    //int userPrefs,
    @Default('') String searchRunsText,
    double? latitude,
    double? longitude,
    double? distToEvent,
    @Default(0) int isMapAndDistanceValid,
    @Default(3) int runClassification, // 1 if the run is from a Kennel user is following, 2 if the run is close by, 3 if it's another run
  }) = _RunQueryExtensionsModel;

  factory RunQueryExtensionsModel.fromJson(Map<String, dynamic> json) => _$RunQueryExtensionsModelFromJson(json);

  @override
  factory RunQueryExtensionsModel.fromMap(Map<String, dynamic> map) {
    return RunQueryExtensionsModel.fromJson(map);
  }

  factory RunQueryExtensionsModel.fromJsonWithDateSearchText(
    Map<String, dynamic> json,
    DateTime eventStartDateTime,
    double? distanceToEvent, {
    double? meters,
  }) {
    RunQueryExtensionsModel m = _$RunQueryExtensionsModelFromJson(json);

    int runClassification = 4;

    if (meters != null) {
      final int userDistPrefs = (getIntPref(IntPrefsEnum.hasherPreferences) ?? 0) & hasherPref_distanceForAutoDisplay;

      // if the user has set their preferences to miles or
      // the user has set their preferences to "auto" and the
      // distance preference associated with the kennel is miles
      // then convert our range for runs from meters to miles.
      if (((userDistPrefs & hasherPref_distanceMeasuredIn) == 3) || (((userDistPrefs & hasherPref_distanceMeasuredIn) == 0) && (m.distanceUnitsPref == 3))) {
        meters = meters * MILES_TO_METERS / 1000; // this calculation is correct!
      }

      if ((m.rsvpState == 3) || (m.rsvpState == 2)) {
        // if the RSVP state is yes or maybe make it a class 1 run
        runClassification = 1;
      } else if ((distanceToEvent ?? 999999.0) < meters) {
        // if the run is close, it's a class 2 run
        runClassification = 2;
      } else if (m.following == 1) {
        // if user is following a Kennel, it's a class 3 run
        runClassification = 3;
      }
    }

    m = m.copyWith(
        runClassification: runClassification,
        distToEvent: distanceToEvent,
        searchRunsText: m.searchRunsText +
            getSearchDateString(
              eventStartDateTime,
            ));

    return m;
  }

  static String getSearchDateString(DateTime? eventStartDateTime) {
    if (eventStartDateTime == null) {
      return '';
    }

    final DateFormat df = DateFormat("' is' y ' is' EEEE ' is' LLLL d y ' is' LLL d y h:mm aaa HH:mm", 'en_US');
    String days = '';
    String weekend = '';
    String thisDay = '';

    final int deltaDays = eventStartDateTime.millisecondsSinceEpoch ~/ (86400 * 1000) - DateTime.now().millisecondsSinceEpoch ~/ (86400 * 1000);
    if (deltaDays < 0) {
      if (deltaDays == 1) {
        days = ' 1 day ago is yesterday ';
      } else {
        days = ' ${-deltaDays} days ago ';
      }
    } else if (deltaDays > 0) {
      if (deltaDays == 1) {
        days = ' in 1 day is tomorrow ';
      } else {
        days = ' in $deltaDays days ';
      }
    } else {
      days = ' is today ';
    }

    if ((deltaDays > 0) && (deltaDays < 7)) {
      switch (eventStartDateTime.weekday) {
        case DateTime.monday:
          thisDay = ' this Monday ';
          break;
        case DateTime.tuesday:
          thisDay = ' this Tuesday ';
          break;
        case DateTime.wednesday:
          thisDay = ' this Wednesday ';
          break;
        case DateTime.thursday:
          thisDay = ' this Thursday ';
          break;
        case DateTime.friday:
          thisDay = ' this Friday ';
          break;
        case DateTime.saturday:
          thisDay = ' this Saturday ';
          break;
        case DateTime.sunday:
          thisDay = ' this Sunday ';
          break;
      }
    }

    if ((eventStartDateTime.weekday == DateTime.sunday) || (eventStartDateTime.weekday == DateTime.saturday)) {
      weekend = ' is weekend ';
    }

    //final String test = ' ' + df.format(eventStartDateTime) + ' ' + days + weekend + thisDay;
    ////print(test);

    return ' ${df.format(eventStartDateTime)} $days$weekend$thisDay';
  }
}
