// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RunListModel implements DiagnosticableTreeMixin {
  String get publicEventId;
  DateTime get eventStartDatetime;
  String get publicKennelId;
  int get isVisible;
  int get isCountedRun;
  int get eventGeographicScope;
  int get eventNumber;
  String get eventName;
  String get kennelShortName;
  String get kennelLogo;
  int get daysUntilEvent;
  String get searchText;
  String get kennelName;
  String get eventCityAndCountry;
  String get resolvableLocation;
  int get eventChatMessageCount;
  String? get locationOneLineDesc;
  String? get hares;
  double? get syncLat;
  double? get syncLong;
  String? get eventImage;
  String? get extEventImage;
  int? get useFbImage;

  /// Create a copy of RunListModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RunListModelCopyWith<RunListModel> get copyWith =>
      _$RunListModelCopyWithImpl<RunListModel>(
          this as RunListModel, _$identity);

  /// Serializes this RunListModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RunListModel'))
      ..add(DiagnosticsProperty('publicEventId', publicEventId))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('isVisible', isVisible))
      ..add(DiagnosticsProperty('isCountedRun', isCountedRun))
      ..add(DiagnosticsProperty('eventGeographicScope', eventGeographicScope))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('daysUntilEvent', daysUntilEvent))
      ..add(DiagnosticsProperty('searchText', searchText))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('eventCityAndCountry', eventCityAndCountry))
      ..add(DiagnosticsProperty('resolvableLocation', resolvableLocation))
      ..add(DiagnosticsProperty('eventChatMessageCount', eventChatMessageCount))
      ..add(DiagnosticsProperty('locationOneLineDesc', locationOneLineDesc))
      ..add(DiagnosticsProperty('hares', hares))
      ..add(DiagnosticsProperty('syncLat', syncLat))
      ..add(DiagnosticsProperty('syncLong', syncLong))
      ..add(DiagnosticsProperty('eventImage', eventImage))
      ..add(DiagnosticsProperty('extEventImage', extEventImage))
      ..add(DiagnosticsProperty('useFbImage', useFbImage));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RunListModel &&
            (identical(other.publicEventId, publicEventId) ||
                other.publicEventId == publicEventId) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isCountedRun, isCountedRun) ||
                other.isCountedRun == isCountedRun) &&
            (identical(other.eventGeographicScope, eventGeographicScope) ||
                other.eventGeographicScope == eventGeographicScope) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.daysUntilEvent, daysUntilEvent) ||
                other.daysUntilEvent == daysUntilEvent) &&
            (identical(other.searchText, searchText) ||
                other.searchText == searchText) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.eventCityAndCountry, eventCityAndCountry) ||
                other.eventCityAndCountry == eventCityAndCountry) &&
            (identical(other.resolvableLocation, resolvableLocation) ||
                other.resolvableLocation == resolvableLocation) &&
            (identical(other.eventChatMessageCount, eventChatMessageCount) ||
                other.eventChatMessageCount == eventChatMessageCount) &&
            (identical(other.locationOneLineDesc, locationOneLineDesc) ||
                other.locationOneLineDesc == locationOneLineDesc) &&
            (identical(other.hares, hares) || other.hares == hares) &&
            (identical(other.syncLat, syncLat) || other.syncLat == syncLat) &&
            (identical(other.syncLong, syncLong) ||
                other.syncLong == syncLong) &&
            (identical(other.eventImage, eventImage) ||
                other.eventImage == eventImage) &&
            (identical(other.extEventImage, extEventImage) ||
                other.extEventImage == extEventImage) &&
            (identical(other.useFbImage, useFbImage) ||
                other.useFbImage == useFbImage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicEventId,
        eventStartDatetime,
        publicKennelId,
        isVisible,
        isCountedRun,
        eventGeographicScope,
        eventNumber,
        eventName,
        kennelShortName,
        kennelLogo,
        daysUntilEvent,
        searchText,
        kennelName,
        eventCityAndCountry,
        resolvableLocation,
        eventChatMessageCount,
        locationOneLineDesc,
        hares,
        syncLat,
        syncLong,
        eventImage,
        extEventImage,
        useFbImage
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunListModel(publicEventId: $publicEventId, eventStartDatetime: $eventStartDatetime, publicKennelId: $publicKennelId, isVisible: $isVisible, isCountedRun: $isCountedRun, eventGeographicScope: $eventGeographicScope, eventNumber: $eventNumber, eventName: $eventName, kennelShortName: $kennelShortName, kennelLogo: $kennelLogo, daysUntilEvent: $daysUntilEvent, searchText: $searchText, kennelName: $kennelName, eventCityAndCountry: $eventCityAndCountry, resolvableLocation: $resolvableLocation, eventChatMessageCount: $eventChatMessageCount, locationOneLineDesc: $locationOneLineDesc, hares: $hares, syncLat: $syncLat, syncLong: $syncLong, eventImage: $eventImage, extEventImage: $extEventImage, useFbImage: $useFbImage)';
  }
}

/// @nodoc
abstract mixin class $RunListModelCopyWith<$Res> {
  factory $RunListModelCopyWith(
          RunListModel value, $Res Function(RunListModel) _then) =
      _$RunListModelCopyWithImpl;
  @useResult
  $Res call(
      {String publicEventId,
      DateTime eventStartDatetime,
      String publicKennelId,
      int isVisible,
      int isCountedRun,
      int eventGeographicScope,
      int eventNumber,
      String eventName,
      String kennelShortName,
      String kennelLogo,
      int daysUntilEvent,
      String searchText,
      String kennelName,
      String eventCityAndCountry,
      String resolvableLocation,
      int eventChatMessageCount,
      String? locationOneLineDesc,
      String? hares,
      double? syncLat,
      double? syncLong,
      String? eventImage,
      String? extEventImage,
      int? useFbImage});
}

/// @nodoc
class _$RunListModelCopyWithImpl<$Res> implements $RunListModelCopyWith<$Res> {
  _$RunListModelCopyWithImpl(this._self, this._then);

  final RunListModel _self;
  final $Res Function(RunListModel) _then;

  /// Create a copy of RunListModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicEventId = null,
    Object? eventStartDatetime = null,
    Object? publicKennelId = null,
    Object? isVisible = null,
    Object? isCountedRun = null,
    Object? eventGeographicScope = null,
    Object? eventNumber = null,
    Object? eventName = null,
    Object? kennelShortName = null,
    Object? kennelLogo = null,
    Object? daysUntilEvent = null,
    Object? searchText = null,
    Object? kennelName = null,
    Object? eventCityAndCountry = null,
    Object? resolvableLocation = null,
    Object? eventChatMessageCount = null,
    Object? locationOneLineDesc = freezed,
    Object? hares = freezed,
    Object? syncLat = freezed,
    Object? syncLong = freezed,
    Object? eventImage = freezed,
    Object? extEventImage = freezed,
    Object? useFbImage = freezed,
  }) {
    return _then(_self.copyWith(
      publicEventId: null == publicEventId
          ? _self.publicEventId
          : publicEventId // ignore: cast_nullable_to_non_nullable
              as String,
      eventStartDatetime: null == eventStartDatetime
          ? _self.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as int,
      isCountedRun: null == isCountedRun
          ? _self.isCountedRun
          : isCountedRun // ignore: cast_nullable_to_non_nullable
              as int,
      eventGeographicScope: null == eventGeographicScope
          ? _self.eventGeographicScope
          : eventGeographicScope // ignore: cast_nullable_to_non_nullable
              as int,
      eventNumber: null == eventNumber
          ? _self.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      daysUntilEvent: null == daysUntilEvent
          ? _self.daysUntilEvent
          : daysUntilEvent // ignore: cast_nullable_to_non_nullable
              as int,
      searchText: null == searchText
          ? _self.searchText
          : searchText // ignore: cast_nullable_to_non_nullable
              as String,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      eventCityAndCountry: null == eventCityAndCountry
          ? _self.eventCityAndCountry
          : eventCityAndCountry // ignore: cast_nullable_to_non_nullable
              as String,
      resolvableLocation: null == resolvableLocation
          ? _self.resolvableLocation
          : resolvableLocation // ignore: cast_nullable_to_non_nullable
              as String,
      eventChatMessageCount: null == eventChatMessageCount
          ? _self.eventChatMessageCount
          : eventChatMessageCount // ignore: cast_nullable_to_non_nullable
              as int,
      locationOneLineDesc: freezed == locationOneLineDesc
          ? _self.locationOneLineDesc
          : locationOneLineDesc // ignore: cast_nullable_to_non_nullable
              as String?,
      hares: freezed == hares
          ? _self.hares
          : hares // ignore: cast_nullable_to_non_nullable
              as String?,
      syncLat: freezed == syncLat
          ? _self.syncLat
          : syncLat // ignore: cast_nullable_to_non_nullable
              as double?,
      syncLong: freezed == syncLong
          ? _self.syncLong
          : syncLong // ignore: cast_nullable_to_non_nullable
              as double?,
      eventImage: freezed == eventImage
          ? _self.eventImage
          : eventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventImage: freezed == extEventImage
          ? _self.extEventImage
          : extEventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      useFbImage: freezed == useFbImage
          ? _self.useFbImage
          : useFbImage // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [RunListModel].
extension RunListModelPatterns on RunListModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RunListModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RunListModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RunListModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunListModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RunListModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunListModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String publicEventId,
            DateTime eventStartDatetime,
            String publicKennelId,
            int isVisible,
            int isCountedRun,
            int eventGeographicScope,
            int eventNumber,
            String eventName,
            String kennelShortName,
            String kennelLogo,
            int daysUntilEvent,
            String searchText,
            String kennelName,
            String eventCityAndCountry,
            String resolvableLocation,
            int eventChatMessageCount,
            String? locationOneLineDesc,
            String? hares,
            double? syncLat,
            double? syncLong,
            String? eventImage,
            String? extEventImage,
            int? useFbImage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RunListModel() when $default != null:
        return $default(
            _that.publicEventId,
            _that.eventStartDatetime,
            _that.publicKennelId,
            _that.isVisible,
            _that.isCountedRun,
            _that.eventGeographicScope,
            _that.eventNumber,
            _that.eventName,
            _that.kennelShortName,
            _that.kennelLogo,
            _that.daysUntilEvent,
            _that.searchText,
            _that.kennelName,
            _that.eventCityAndCountry,
            _that.resolvableLocation,
            _that.eventChatMessageCount,
            _that.locationOneLineDesc,
            _that.hares,
            _that.syncLat,
            _that.syncLong,
            _that.eventImage,
            _that.extEventImage,
            _that.useFbImage);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String publicEventId,
            DateTime eventStartDatetime,
            String publicKennelId,
            int isVisible,
            int isCountedRun,
            int eventGeographicScope,
            int eventNumber,
            String eventName,
            String kennelShortName,
            String kennelLogo,
            int daysUntilEvent,
            String searchText,
            String kennelName,
            String eventCityAndCountry,
            String resolvableLocation,
            int eventChatMessageCount,
            String? locationOneLineDesc,
            String? hares,
            double? syncLat,
            double? syncLong,
            String? eventImage,
            String? extEventImage,
            int? useFbImage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunListModel():
        return $default(
            _that.publicEventId,
            _that.eventStartDatetime,
            _that.publicKennelId,
            _that.isVisible,
            _that.isCountedRun,
            _that.eventGeographicScope,
            _that.eventNumber,
            _that.eventName,
            _that.kennelShortName,
            _that.kennelLogo,
            _that.daysUntilEvent,
            _that.searchText,
            _that.kennelName,
            _that.eventCityAndCountry,
            _that.resolvableLocation,
            _that.eventChatMessageCount,
            _that.locationOneLineDesc,
            _that.hares,
            _that.syncLat,
            _that.syncLong,
            _that.eventImage,
            _that.extEventImage,
            _that.useFbImage);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String publicEventId,
            DateTime eventStartDatetime,
            String publicKennelId,
            int isVisible,
            int isCountedRun,
            int eventGeographicScope,
            int eventNumber,
            String eventName,
            String kennelShortName,
            String kennelLogo,
            int daysUntilEvent,
            String searchText,
            String kennelName,
            String eventCityAndCountry,
            String resolvableLocation,
            int eventChatMessageCount,
            String? locationOneLineDesc,
            String? hares,
            double? syncLat,
            double? syncLong,
            String? eventImage,
            String? extEventImage,
            int? useFbImage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RunListModel() when $default != null:
        return $default(
            _that.publicEventId,
            _that.eventStartDatetime,
            _that.publicKennelId,
            _that.isVisible,
            _that.isCountedRun,
            _that.eventGeographicScope,
            _that.eventNumber,
            _that.eventName,
            _that.kennelShortName,
            _that.kennelLogo,
            _that.daysUntilEvent,
            _that.searchText,
            _that.kennelName,
            _that.eventCityAndCountry,
            _that.resolvableLocation,
            _that.eventChatMessageCount,
            _that.locationOneLineDesc,
            _that.hares,
            _that.syncLat,
            _that.syncLong,
            _that.eventImage,
            _that.extEventImage,
            _that.useFbImage);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RunListModel with DiagnosticableTreeMixin implements RunListModel {
  _RunListModel(
      {required this.publicEventId,
      required this.eventStartDatetime,
      required this.publicKennelId,
      required this.isVisible,
      required this.isCountedRun,
      required this.eventGeographicScope,
      required this.eventNumber,
      required this.eventName,
      required this.kennelShortName,
      required this.kennelLogo,
      required this.daysUntilEvent,
      required this.searchText,
      required this.kennelName,
      required this.eventCityAndCountry,
      required this.resolvableLocation,
      required this.eventChatMessageCount,
      required this.locationOneLineDesc,
      this.hares,
      this.syncLat,
      this.syncLong,
      this.eventImage,
      this.extEventImage,
      this.useFbImage});
  factory _RunListModel.fromJson(Map<String, dynamic> json) =>
      _$RunListModelFromJson(json);

  @override
  final String publicEventId;
  @override
  final DateTime eventStartDatetime;
  @override
  final String publicKennelId;
  @override
  final int isVisible;
  @override
  final int isCountedRun;
  @override
  final int eventGeographicScope;
  @override
  final int eventNumber;
  @override
  final String eventName;
  @override
  final String kennelShortName;
  @override
  final String kennelLogo;
  @override
  final int daysUntilEvent;
  @override
  final String searchText;
  @override
  final String kennelName;
  @override
  final String eventCityAndCountry;
  @override
  final String resolvableLocation;
  @override
  final int eventChatMessageCount;
  @override
  final String? locationOneLineDesc;
  @override
  final String? hares;
  @override
  final double? syncLat;
  @override
  final double? syncLong;
  @override
  final String? eventImage;
  @override
  final String? extEventImage;
  @override
  final int? useFbImage;

  /// Create a copy of RunListModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RunListModelCopyWith<_RunListModel> get copyWith =>
      __$RunListModelCopyWithImpl<_RunListModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RunListModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RunListModel'))
      ..add(DiagnosticsProperty('publicEventId', publicEventId))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty('publicKennelId', publicKennelId))
      ..add(DiagnosticsProperty('isVisible', isVisible))
      ..add(DiagnosticsProperty('isCountedRun', isCountedRun))
      ..add(DiagnosticsProperty('eventGeographicScope', eventGeographicScope))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('daysUntilEvent', daysUntilEvent))
      ..add(DiagnosticsProperty('searchText', searchText))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('eventCityAndCountry', eventCityAndCountry))
      ..add(DiagnosticsProperty('resolvableLocation', resolvableLocation))
      ..add(DiagnosticsProperty('eventChatMessageCount', eventChatMessageCount))
      ..add(DiagnosticsProperty('locationOneLineDesc', locationOneLineDesc))
      ..add(DiagnosticsProperty('hares', hares))
      ..add(DiagnosticsProperty('syncLat', syncLat))
      ..add(DiagnosticsProperty('syncLong', syncLong))
      ..add(DiagnosticsProperty('eventImage', eventImage))
      ..add(DiagnosticsProperty('extEventImage', extEventImage))
      ..add(DiagnosticsProperty('useFbImage', useFbImage));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RunListModel &&
            (identical(other.publicEventId, publicEventId) ||
                other.publicEventId == publicEventId) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.publicKennelId, publicKennelId) ||
                other.publicKennelId == publicKennelId) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isCountedRun, isCountedRun) ||
                other.isCountedRun == isCountedRun) &&
            (identical(other.eventGeographicScope, eventGeographicScope) ||
                other.eventGeographicScope == eventGeographicScope) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.daysUntilEvent, daysUntilEvent) ||
                other.daysUntilEvent == daysUntilEvent) &&
            (identical(other.searchText, searchText) ||
                other.searchText == searchText) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.eventCityAndCountry, eventCityAndCountry) ||
                other.eventCityAndCountry == eventCityAndCountry) &&
            (identical(other.resolvableLocation, resolvableLocation) ||
                other.resolvableLocation == resolvableLocation) &&
            (identical(other.eventChatMessageCount, eventChatMessageCount) ||
                other.eventChatMessageCount == eventChatMessageCount) &&
            (identical(other.locationOneLineDesc, locationOneLineDesc) ||
                other.locationOneLineDesc == locationOneLineDesc) &&
            (identical(other.hares, hares) || other.hares == hares) &&
            (identical(other.syncLat, syncLat) || other.syncLat == syncLat) &&
            (identical(other.syncLong, syncLong) ||
                other.syncLong == syncLong) &&
            (identical(other.eventImage, eventImage) ||
                other.eventImage == eventImage) &&
            (identical(other.extEventImage, extEventImage) ||
                other.extEventImage == extEventImage) &&
            (identical(other.useFbImage, useFbImage) ||
                other.useFbImage == useFbImage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        publicEventId,
        eventStartDatetime,
        publicKennelId,
        isVisible,
        isCountedRun,
        eventGeographicScope,
        eventNumber,
        eventName,
        kennelShortName,
        kennelLogo,
        daysUntilEvent,
        searchText,
        kennelName,
        eventCityAndCountry,
        resolvableLocation,
        eventChatMessageCount,
        locationOneLineDesc,
        hares,
        syncLat,
        syncLong,
        eventImage,
        extEventImage,
        useFbImage
      ]);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunListModel(publicEventId: $publicEventId, eventStartDatetime: $eventStartDatetime, publicKennelId: $publicKennelId, isVisible: $isVisible, isCountedRun: $isCountedRun, eventGeographicScope: $eventGeographicScope, eventNumber: $eventNumber, eventName: $eventName, kennelShortName: $kennelShortName, kennelLogo: $kennelLogo, daysUntilEvent: $daysUntilEvent, searchText: $searchText, kennelName: $kennelName, eventCityAndCountry: $eventCityAndCountry, resolvableLocation: $resolvableLocation, eventChatMessageCount: $eventChatMessageCount, locationOneLineDesc: $locationOneLineDesc, hares: $hares, syncLat: $syncLat, syncLong: $syncLong, eventImage: $eventImage, extEventImage: $extEventImage, useFbImage: $useFbImage)';
  }
}

/// @nodoc
abstract mixin class _$RunListModelCopyWith<$Res>
    implements $RunListModelCopyWith<$Res> {
  factory _$RunListModelCopyWith(
          _RunListModel value, $Res Function(_RunListModel) _then) =
      __$RunListModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String publicEventId,
      DateTime eventStartDatetime,
      String publicKennelId,
      int isVisible,
      int isCountedRun,
      int eventGeographicScope,
      int eventNumber,
      String eventName,
      String kennelShortName,
      String kennelLogo,
      int daysUntilEvent,
      String searchText,
      String kennelName,
      String eventCityAndCountry,
      String resolvableLocation,
      int eventChatMessageCount,
      String? locationOneLineDesc,
      String? hares,
      double? syncLat,
      double? syncLong,
      String? eventImage,
      String? extEventImage,
      int? useFbImage});
}

/// @nodoc
class __$RunListModelCopyWithImpl<$Res>
    implements _$RunListModelCopyWith<$Res> {
  __$RunListModelCopyWithImpl(this._self, this._then);

  final _RunListModel _self;
  final $Res Function(_RunListModel) _then;

  /// Create a copy of RunListModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? publicEventId = null,
    Object? eventStartDatetime = null,
    Object? publicKennelId = null,
    Object? isVisible = null,
    Object? isCountedRun = null,
    Object? eventGeographicScope = null,
    Object? eventNumber = null,
    Object? eventName = null,
    Object? kennelShortName = null,
    Object? kennelLogo = null,
    Object? daysUntilEvent = null,
    Object? searchText = null,
    Object? kennelName = null,
    Object? eventCityAndCountry = null,
    Object? resolvableLocation = null,
    Object? eventChatMessageCount = null,
    Object? locationOneLineDesc = freezed,
    Object? hares = freezed,
    Object? syncLat = freezed,
    Object? syncLong = freezed,
    Object? eventImage = freezed,
    Object? extEventImage = freezed,
    Object? useFbImage = freezed,
  }) {
    return _then(_RunListModel(
      publicEventId: null == publicEventId
          ? _self.publicEventId
          : publicEventId // ignore: cast_nullable_to_non_nullable
              as String,
      eventStartDatetime: null == eventStartDatetime
          ? _self.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      publicKennelId: null == publicKennelId
          ? _self.publicKennelId
          : publicKennelId // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as int,
      isCountedRun: null == isCountedRun
          ? _self.isCountedRun
          : isCountedRun // ignore: cast_nullable_to_non_nullable
              as int,
      eventGeographicScope: null == eventGeographicScope
          ? _self.eventGeographicScope
          : eventGeographicScope // ignore: cast_nullable_to_non_nullable
              as int,
      eventNumber: null == eventNumber
          ? _self.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      daysUntilEvent: null == daysUntilEvent
          ? _self.daysUntilEvent
          : daysUntilEvent // ignore: cast_nullable_to_non_nullable
              as int,
      searchText: null == searchText
          ? _self.searchText
          : searchText // ignore: cast_nullable_to_non_nullable
              as String,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      eventCityAndCountry: null == eventCityAndCountry
          ? _self.eventCityAndCountry
          : eventCityAndCountry // ignore: cast_nullable_to_non_nullable
              as String,
      resolvableLocation: null == resolvableLocation
          ? _self.resolvableLocation
          : resolvableLocation // ignore: cast_nullable_to_non_nullable
              as String,
      eventChatMessageCount: null == eventChatMessageCount
          ? _self.eventChatMessageCount
          : eventChatMessageCount // ignore: cast_nullable_to_non_nullable
              as int,
      locationOneLineDesc: freezed == locationOneLineDesc
          ? _self.locationOneLineDesc
          : locationOneLineDesc // ignore: cast_nullable_to_non_nullable
              as String?,
      hares: freezed == hares
          ? _self.hares
          : hares // ignore: cast_nullable_to_non_nullable
              as String?,
      syncLat: freezed == syncLat
          ? _self.syncLat
          : syncLat // ignore: cast_nullable_to_non_nullable
              as double?,
      syncLong: freezed == syncLong
          ? _self.syncLong
          : syncLong // ignore: cast_nullable_to_non_nullable
              as double?,
      eventImage: freezed == eventImage
          ? _self.eventImage
          : eventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      extEventImage: freezed == extEventImage
          ? _self.extEventImage
          : extEventImage // ignore: cast_nullable_to_non_nullable
              as String?,
      useFbImage: freezed == useFbImage
          ? _self.useFbImage
          : useFbImage // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
