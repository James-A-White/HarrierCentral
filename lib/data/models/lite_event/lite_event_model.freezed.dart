// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lite_event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiteEventModel implements DiagnosticableTreeMixin {
  String get eventId;
  int get isVisible;
  int get isCountedRun;
  int? get absoluteEventNumber;
  String? get externalIntegrationId;
  String get eventName;
  int get eventNumber;
  DateTime get eventStartDatetime;
  int? get eventInboundIntegrationId;
  int get appAccessFlags;
  int get canEditRunAttendance;

  /// Create a copy of LiteEventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiteEventModelCopyWith<LiteEventModel> get copyWith =>
      _$LiteEventModelCopyWithImpl<LiteEventModel>(
          this as LiteEventModel, _$identity);

  /// Serializes this LiteEventModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'LiteEventModel'))
      ..add(DiagnosticsProperty('eventId', eventId))
      ..add(DiagnosticsProperty('isVisible', isVisible))
      ..add(DiagnosticsProperty('isCountedRun', isCountedRun))
      ..add(DiagnosticsProperty('absoluteEventNumber', absoluteEventNumber))
      ..add(DiagnosticsProperty('externalIntegrationId', externalIntegrationId))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty(
          'eventInboundIntegrationId', eventInboundIntegrationId))
      ..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))
      ..add(DiagnosticsProperty('canEditRunAttendance', canEditRunAttendance));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiteEventModel &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isCountedRun, isCountedRun) ||
                other.isCountedRun == isCountedRun) &&
            (identical(other.absoluteEventNumber, absoluteEventNumber) ||
                other.absoluteEventNumber == absoluteEventNumber) &&
            (identical(other.externalIntegrationId, externalIntegrationId) ||
                other.externalIntegrationId == externalIntegrationId) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.eventInboundIntegrationId,
                    eventInboundIntegrationId) ||
                other.eventInboundIntegrationId == eventInboundIntegrationId) &&
            (identical(other.appAccessFlags, appAccessFlags) ||
                other.appAccessFlags == appAccessFlags) &&
            (identical(other.canEditRunAttendance, canEditRunAttendance) ||
                other.canEditRunAttendance == canEditRunAttendance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      eventId,
      isVisible,
      isCountedRun,
      absoluteEventNumber,
      externalIntegrationId,
      eventName,
      eventNumber,
      eventStartDatetime,
      eventInboundIntegrationId,
      appAccessFlags,
      canEditRunAttendance);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LiteEventModel(eventId: $eventId, isVisible: $isVisible, isCountedRun: $isCountedRun, absoluteEventNumber: $absoluteEventNumber, externalIntegrationId: $externalIntegrationId, eventName: $eventName, eventNumber: $eventNumber, eventStartDatetime: $eventStartDatetime, eventInboundIntegrationId: $eventInboundIntegrationId, appAccessFlags: $appAccessFlags, canEditRunAttendance: $canEditRunAttendance)';
  }
}

/// @nodoc
abstract mixin class $LiteEventModelCopyWith<$Res> {
  factory $LiteEventModelCopyWith(
          LiteEventModel value, $Res Function(LiteEventModel) _then) =
      _$LiteEventModelCopyWithImpl;
  @useResult
  $Res call(
      {String eventId,
      int isVisible,
      int isCountedRun,
      int? absoluteEventNumber,
      String? externalIntegrationId,
      String eventName,
      int eventNumber,
      DateTime eventStartDatetime,
      int? eventInboundIntegrationId,
      int appAccessFlags,
      int canEditRunAttendance});
}

/// @nodoc
class _$LiteEventModelCopyWithImpl<$Res>
    implements $LiteEventModelCopyWith<$Res> {
  _$LiteEventModelCopyWithImpl(this._self, this._then);

  final LiteEventModel _self;
  final $Res Function(LiteEventModel) _then;

  /// Create a copy of LiteEventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? isVisible = null,
    Object? isCountedRun = null,
    Object? absoluteEventNumber = freezed,
    Object? externalIntegrationId = freezed,
    Object? eventName = null,
    Object? eventNumber = null,
    Object? eventStartDatetime = null,
    Object? eventInboundIntegrationId = freezed,
    Object? appAccessFlags = null,
    Object? canEditRunAttendance = null,
  }) {
    return _then(_self.copyWith(
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as int,
      isCountedRun: null == isCountedRun
          ? _self.isCountedRun
          : isCountedRun // ignore: cast_nullable_to_non_nullable
              as int,
      absoluteEventNumber: freezed == absoluteEventNumber
          ? _self.absoluteEventNumber
          : absoluteEventNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      externalIntegrationId: freezed == externalIntegrationId
          ? _self.externalIntegrationId
          : externalIntegrationId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      eventNumber: null == eventNumber
          ? _self.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventStartDatetime: null == eventStartDatetime
          ? _self.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      eventInboundIntegrationId: freezed == eventInboundIntegrationId
          ? _self.eventInboundIntegrationId
          : eventInboundIntegrationId // ignore: cast_nullable_to_non_nullable
              as int?,
      appAccessFlags: null == appAccessFlags
          ? _self.appAccessFlags
          : appAccessFlags // ignore: cast_nullable_to_non_nullable
              as int,
      canEditRunAttendance: null == canEditRunAttendance
          ? _self.canEditRunAttendance
          : canEditRunAttendance // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LiteEventModel with DiagnosticableTreeMixin implements LiteEventModel {
  _LiteEventModel(
      {required this.eventId,
      this.isVisible = 1,
      this.isCountedRun = 1,
      this.absoluteEventNumber,
      this.externalIntegrationId,
      required this.eventName,
      required this.eventNumber,
      required this.eventStartDatetime,
      this.eventInboundIntegrationId,
      this.appAccessFlags = 0,
      this.canEditRunAttendance = 0});
  factory _LiteEventModel.fromJson(Map<String, dynamic> json) =>
      _$LiteEventModelFromJson(json);

  @override
  final String eventId;
  @override
  @JsonKey()
  final int isVisible;
  @override
  @JsonKey()
  final int isCountedRun;
  @override
  final int? absoluteEventNumber;
  @override
  final String? externalIntegrationId;
  @override
  final String eventName;
  @override
  final int eventNumber;
  @override
  final DateTime eventStartDatetime;
  @override
  final int? eventInboundIntegrationId;
  @override
  @JsonKey()
  final int appAccessFlags;
  @override
  @JsonKey()
  final int canEditRunAttendance;

  /// Create a copy of LiteEventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiteEventModelCopyWith<_LiteEventModel> get copyWith =>
      __$LiteEventModelCopyWithImpl<_LiteEventModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiteEventModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'LiteEventModel'))
      ..add(DiagnosticsProperty('eventId', eventId))
      ..add(DiagnosticsProperty('isVisible', isVisible))
      ..add(DiagnosticsProperty('isCountedRun', isCountedRun))
      ..add(DiagnosticsProperty('absoluteEventNumber', absoluteEventNumber))
      ..add(DiagnosticsProperty('externalIntegrationId', externalIntegrationId))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty(
          'eventInboundIntegrationId', eventInboundIntegrationId))
      ..add(DiagnosticsProperty('appAccessFlags', appAccessFlags))
      ..add(DiagnosticsProperty('canEditRunAttendance', canEditRunAttendance));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiteEventModel &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isCountedRun, isCountedRun) ||
                other.isCountedRun == isCountedRun) &&
            (identical(other.absoluteEventNumber, absoluteEventNumber) ||
                other.absoluteEventNumber == absoluteEventNumber) &&
            (identical(other.externalIntegrationId, externalIntegrationId) ||
                other.externalIntegrationId == externalIntegrationId) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.eventInboundIntegrationId,
                    eventInboundIntegrationId) ||
                other.eventInboundIntegrationId == eventInboundIntegrationId) &&
            (identical(other.appAccessFlags, appAccessFlags) ||
                other.appAccessFlags == appAccessFlags) &&
            (identical(other.canEditRunAttendance, canEditRunAttendance) ||
                other.canEditRunAttendance == canEditRunAttendance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      eventId,
      isVisible,
      isCountedRun,
      absoluteEventNumber,
      externalIntegrationId,
      eventName,
      eventNumber,
      eventStartDatetime,
      eventInboundIntegrationId,
      appAccessFlags,
      canEditRunAttendance);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LiteEventModel(eventId: $eventId, isVisible: $isVisible, isCountedRun: $isCountedRun, absoluteEventNumber: $absoluteEventNumber, externalIntegrationId: $externalIntegrationId, eventName: $eventName, eventNumber: $eventNumber, eventStartDatetime: $eventStartDatetime, eventInboundIntegrationId: $eventInboundIntegrationId, appAccessFlags: $appAccessFlags, canEditRunAttendance: $canEditRunAttendance)';
  }
}

/// @nodoc
abstract mixin class _$LiteEventModelCopyWith<$Res>
    implements $LiteEventModelCopyWith<$Res> {
  factory _$LiteEventModelCopyWith(
          _LiteEventModel value, $Res Function(_LiteEventModel) _then) =
      __$LiteEventModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String eventId,
      int isVisible,
      int isCountedRun,
      int? absoluteEventNumber,
      String? externalIntegrationId,
      String eventName,
      int eventNumber,
      DateTime eventStartDatetime,
      int? eventInboundIntegrationId,
      int appAccessFlags,
      int canEditRunAttendance});
}

/// @nodoc
class __$LiteEventModelCopyWithImpl<$Res>
    implements _$LiteEventModelCopyWith<$Res> {
  __$LiteEventModelCopyWithImpl(this._self, this._then);

  final _LiteEventModel _self;
  final $Res Function(_LiteEventModel) _then;

  /// Create a copy of LiteEventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? eventId = null,
    Object? isVisible = null,
    Object? isCountedRun = null,
    Object? absoluteEventNumber = freezed,
    Object? externalIntegrationId = freezed,
    Object? eventName = null,
    Object? eventNumber = null,
    Object? eventStartDatetime = null,
    Object? eventInboundIntegrationId = freezed,
    Object? appAccessFlags = null,
    Object? canEditRunAttendance = null,
  }) {
    return _then(_LiteEventModel(
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      isVisible: null == isVisible
          ? _self.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as int,
      isCountedRun: null == isCountedRun
          ? _self.isCountedRun
          : isCountedRun // ignore: cast_nullable_to_non_nullable
              as int,
      absoluteEventNumber: freezed == absoluteEventNumber
          ? _self.absoluteEventNumber
          : absoluteEventNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      externalIntegrationId: freezed == externalIntegrationId
          ? _self.externalIntegrationId
          : externalIntegrationId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventName: null == eventName
          ? _self.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      eventNumber: null == eventNumber
          ? _self.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventStartDatetime: null == eventStartDatetime
          ? _self.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      eventInboundIntegrationId: freezed == eventInboundIntegrationId
          ? _self.eventInboundIntegrationId
          : eventInboundIntegrationId // ignore: cast_nullable_to_non_nullable
              as int?,
      appAccessFlags: null == appAccessFlags
          ? _self.appAccessFlags
          : appAccessFlags // ignore: cast_nullable_to_non_nullable
              as int,
      canEditRunAttendance: null == canEditRunAttendance
          ? _self.canEditRunAttendance
          : canEditRunAttendance // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
