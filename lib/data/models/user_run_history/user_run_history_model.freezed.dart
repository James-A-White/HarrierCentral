// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_run_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserRunHistoryModel implements DiagnosticableTreeMixin {
  String get eventId;
  String get eventName;
  int get eventNumber;
  DateTime get eventStartDatetime;
  int get canEditRunAttendence;
  String? get hemId;
  int get attendenceState;
  int get isHare;
  double? get creditAmount;
  double? get debitAmount;
  double? get creditAvailable;
  int? get paymentType;
  String? get extrasDescription;
  double? get extrasPrice;
  int? get doPayForExtras;
  int? get totalRunsThisKennel;
  int? get totalHaringThisKennel;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isUpdating;

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserRunHistoryModelCopyWith<UserRunHistoryModel> get copyWith =>
      _$UserRunHistoryModelCopyWithImpl<UserRunHistoryModel>(
          this as UserRunHistoryModel, _$identity);

  /// Serializes this UserRunHistoryModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UserRunHistoryModel'))
      ..add(DiagnosticsProperty('eventId', eventId))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))
      ..add(DiagnosticsProperty('hemId', hemId))
      ..add(DiagnosticsProperty('attendenceState', attendenceState))
      ..add(DiagnosticsProperty('isHare', isHare))
      ..add(DiagnosticsProperty('creditAmount', creditAmount))
      ..add(DiagnosticsProperty('debitAmount', debitAmount))
      ..add(DiagnosticsProperty('creditAvailable', creditAvailable))
      ..add(DiagnosticsProperty('paymentType', paymentType))
      ..add(DiagnosticsProperty('extrasDescription', extrasDescription))
      ..add(DiagnosticsProperty('extrasPrice', extrasPrice))
      ..add(DiagnosticsProperty('doPayForExtras', doPayForExtras))
      ..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))
      ..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))
      ..add(DiagnosticsProperty('isUpdating', isUpdating));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserRunHistoryModel &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.canEditRunAttendence, canEditRunAttendence) ||
                other.canEditRunAttendence == canEditRunAttendence) &&
            (identical(other.hemId, hemId) || other.hemId == hemId) &&
            (identical(other.attendenceState, attendenceState) ||
                other.attendenceState == attendenceState) &&
            (identical(other.isHare, isHare) || other.isHare == isHare) &&
            (identical(other.creditAmount, creditAmount) ||
                other.creditAmount == creditAmount) &&
            (identical(other.debitAmount, debitAmount) ||
                other.debitAmount == debitAmount) &&
            (identical(other.creditAvailable, creditAvailable) ||
                other.creditAvailable == creditAvailable) &&
            (identical(other.paymentType, paymentType) ||
                other.paymentType == paymentType) &&
            (identical(other.extrasDescription, extrasDescription) ||
                other.extrasDescription == extrasDescription) &&
            (identical(other.extrasPrice, extrasPrice) ||
                other.extrasPrice == extrasPrice) &&
            (identical(other.doPayForExtras, doPayForExtras) ||
                other.doPayForExtras == doPayForExtras) &&
            (identical(other.totalRunsThisKennel, totalRunsThisKennel) ||
                other.totalRunsThisKennel == totalRunsThisKennel) &&
            (identical(other.totalHaringThisKennel, totalHaringThisKennel) ||
                other.totalHaringThisKennel == totalHaringThisKennel) &&
            (identical(other.isUpdating, isUpdating) ||
                other.isUpdating == isUpdating));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      eventId,
      eventName,
      eventNumber,
      eventStartDatetime,
      canEditRunAttendence,
      hemId,
      attendenceState,
      isHare,
      creditAmount,
      debitAmount,
      creditAvailable,
      paymentType,
      extrasDescription,
      extrasPrice,
      doPayForExtras,
      totalRunsThisKennel,
      totalHaringThisKennel,
      isUpdating);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UserRunHistoryModel(eventId: $eventId, eventName: $eventName, eventNumber: $eventNumber, eventStartDatetime: $eventStartDatetime, canEditRunAttendence: $canEditRunAttendence, hemId: $hemId, attendenceState: $attendenceState, isHare: $isHare, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paymentType: $paymentType, extrasDescription: $extrasDescription, extrasPrice: $extrasPrice, doPayForExtras: $doPayForExtras, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, isUpdating: $isUpdating)';
  }
}

/// @nodoc
abstract mixin class $UserRunHistoryModelCopyWith<$Res> {
  factory $UserRunHistoryModelCopyWith(
          UserRunHistoryModel value, $Res Function(UserRunHistoryModel) _then) =
      _$UserRunHistoryModelCopyWithImpl;
  @useResult
  $Res call(
      {String eventId,
      String eventName,
      int eventNumber,
      DateTime eventStartDatetime,
      int canEditRunAttendence,
      String? hemId,
      int attendenceState,
      int isHare,
      double? creditAmount,
      double? debitAmount,
      double? creditAvailable,
      int? paymentType,
      String? extrasDescription,
      double? extrasPrice,
      int? doPayForExtras,
      int? totalRunsThisKennel,
      int? totalHaringThisKennel,
      @JsonKey(includeFromJson: false, includeToJson: false) bool isUpdating});
}

/// @nodoc
class _$UserRunHistoryModelCopyWithImpl<$Res>
    implements $UserRunHistoryModelCopyWith<$Res> {
  _$UserRunHistoryModelCopyWithImpl(this._self, this._then);

  final UserRunHistoryModel _self;
  final $Res Function(UserRunHistoryModel) _then;

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? eventName = null,
    Object? eventNumber = null,
    Object? eventStartDatetime = null,
    Object? canEditRunAttendence = null,
    Object? hemId = freezed,
    Object? attendenceState = null,
    Object? isHare = null,
    Object? creditAmount = freezed,
    Object? debitAmount = freezed,
    Object? creditAvailable = freezed,
    Object? paymentType = freezed,
    Object? extrasDescription = freezed,
    Object? extrasPrice = freezed,
    Object? doPayForExtras = freezed,
    Object? totalRunsThisKennel = freezed,
    Object? totalHaringThisKennel = freezed,
    Object? isUpdating = null,
  }) {
    return _then(_self.copyWith(
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
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
      canEditRunAttendence: null == canEditRunAttendence
          ? _self.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int,
      hemId: freezed == hemId
          ? _self.hemId
          : hemId // ignore: cast_nullable_to_non_nullable
              as String?,
      attendenceState: null == attendenceState
          ? _self.attendenceState
          : attendenceState // ignore: cast_nullable_to_non_nullable
              as int,
      isHare: null == isHare
          ? _self.isHare
          : isHare // ignore: cast_nullable_to_non_nullable
              as int,
      creditAmount: freezed == creditAmount
          ? _self.creditAmount
          : creditAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      debitAmount: freezed == debitAmount
          ? _self.debitAmount
          : debitAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      creditAvailable: freezed == creditAvailable
          ? _self.creditAvailable
          : creditAvailable // ignore: cast_nullable_to_non_nullable
              as double?,
      paymentType: freezed == paymentType
          ? _self.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int?,
      extrasDescription: freezed == extrasDescription
          ? _self.extrasDescription
          : extrasDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      extrasPrice: freezed == extrasPrice
          ? _self.extrasPrice
          : extrasPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      doPayForExtras: freezed == doPayForExtras
          ? _self.doPayForExtras
          : doPayForExtras // ignore: cast_nullable_to_non_nullable
              as int?,
      totalRunsThisKennel: freezed == totalRunsThisKennel
          ? _self.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      totalHaringThisKennel: freezed == totalHaringThisKennel
          ? _self.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      isUpdating: null == isUpdating
          ? _self.isUpdating
          : isUpdating // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _UserRunHistoryModel
    with DiagnosticableTreeMixin
    implements UserRunHistoryModel {
  _UserRunHistoryModel(
      {required this.eventId,
      required this.eventName,
      required this.eventNumber,
      required this.eventStartDatetime,
      this.canEditRunAttendence = 0,
      this.hemId,
      this.attendenceState = 0,
      this.isHare = 0,
      this.creditAmount,
      this.debitAmount,
      this.creditAvailable,
      this.paymentType,
      this.extrasDescription,
      this.extrasPrice,
      this.doPayForExtras,
      this.totalRunsThisKennel,
      this.totalHaringThisKennel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.isUpdating = false});
  factory _UserRunHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$UserRunHistoryModelFromJson(json);

  @override
  final String eventId;
  @override
  final String eventName;
  @override
  final int eventNumber;
  @override
  final DateTime eventStartDatetime;
  @override
  @JsonKey()
  final int canEditRunAttendence;
  @override
  final String? hemId;
  @override
  @JsonKey()
  final int attendenceState;
  @override
  @JsonKey()
  final int isHare;
  @override
  final double? creditAmount;
  @override
  final double? debitAmount;
  @override
  final double? creditAvailable;
  @override
  final int? paymentType;
  @override
  final String? extrasDescription;
  @override
  final double? extrasPrice;
  @override
  final int? doPayForExtras;
  @override
  final int? totalRunsThisKennel;
  @override
  final int? totalHaringThisKennel;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isUpdating;

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserRunHistoryModelCopyWith<_UserRunHistoryModel> get copyWith =>
      __$UserRunHistoryModelCopyWithImpl<_UserRunHistoryModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserRunHistoryModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UserRunHistoryModel'))
      ..add(DiagnosticsProperty('eventId', eventId))
      ..add(DiagnosticsProperty('eventName', eventName))
      ..add(DiagnosticsProperty('eventNumber', eventNumber))
      ..add(DiagnosticsProperty('eventStartDatetime', eventStartDatetime))
      ..add(DiagnosticsProperty('canEditRunAttendence', canEditRunAttendence))
      ..add(DiagnosticsProperty('hemId', hemId))
      ..add(DiagnosticsProperty('attendenceState', attendenceState))
      ..add(DiagnosticsProperty('isHare', isHare))
      ..add(DiagnosticsProperty('creditAmount', creditAmount))
      ..add(DiagnosticsProperty('debitAmount', debitAmount))
      ..add(DiagnosticsProperty('creditAvailable', creditAvailable))
      ..add(DiagnosticsProperty('paymentType', paymentType))
      ..add(DiagnosticsProperty('extrasDescription', extrasDescription))
      ..add(DiagnosticsProperty('extrasPrice', extrasPrice))
      ..add(DiagnosticsProperty('doPayForExtras', doPayForExtras))
      ..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))
      ..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))
      ..add(DiagnosticsProperty('isUpdating', isUpdating));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserRunHistoryModel &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.eventNumber, eventNumber) ||
                other.eventNumber == eventNumber) &&
            (identical(other.eventStartDatetime, eventStartDatetime) ||
                other.eventStartDatetime == eventStartDatetime) &&
            (identical(other.canEditRunAttendence, canEditRunAttendence) ||
                other.canEditRunAttendence == canEditRunAttendence) &&
            (identical(other.hemId, hemId) || other.hemId == hemId) &&
            (identical(other.attendenceState, attendenceState) ||
                other.attendenceState == attendenceState) &&
            (identical(other.isHare, isHare) || other.isHare == isHare) &&
            (identical(other.creditAmount, creditAmount) ||
                other.creditAmount == creditAmount) &&
            (identical(other.debitAmount, debitAmount) ||
                other.debitAmount == debitAmount) &&
            (identical(other.creditAvailable, creditAvailable) ||
                other.creditAvailable == creditAvailable) &&
            (identical(other.paymentType, paymentType) ||
                other.paymentType == paymentType) &&
            (identical(other.extrasDescription, extrasDescription) ||
                other.extrasDescription == extrasDescription) &&
            (identical(other.extrasPrice, extrasPrice) ||
                other.extrasPrice == extrasPrice) &&
            (identical(other.doPayForExtras, doPayForExtras) ||
                other.doPayForExtras == doPayForExtras) &&
            (identical(other.totalRunsThisKennel, totalRunsThisKennel) ||
                other.totalRunsThisKennel == totalRunsThisKennel) &&
            (identical(other.totalHaringThisKennel, totalHaringThisKennel) ||
                other.totalHaringThisKennel == totalHaringThisKennel) &&
            (identical(other.isUpdating, isUpdating) ||
                other.isUpdating == isUpdating));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      eventId,
      eventName,
      eventNumber,
      eventStartDatetime,
      canEditRunAttendence,
      hemId,
      attendenceState,
      isHare,
      creditAmount,
      debitAmount,
      creditAvailable,
      paymentType,
      extrasDescription,
      extrasPrice,
      doPayForExtras,
      totalRunsThisKennel,
      totalHaringThisKennel,
      isUpdating);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UserRunHistoryModel(eventId: $eventId, eventName: $eventName, eventNumber: $eventNumber, eventStartDatetime: $eventStartDatetime, canEditRunAttendence: $canEditRunAttendence, hemId: $hemId, attendenceState: $attendenceState, isHare: $isHare, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paymentType: $paymentType, extrasDescription: $extrasDescription, extrasPrice: $extrasPrice, doPayForExtras: $doPayForExtras, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, isUpdating: $isUpdating)';
  }
}

/// @nodoc
abstract mixin class _$UserRunHistoryModelCopyWith<$Res>
    implements $UserRunHistoryModelCopyWith<$Res> {
  factory _$UserRunHistoryModelCopyWith(_UserRunHistoryModel value,
          $Res Function(_UserRunHistoryModel) _then) =
      __$UserRunHistoryModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String eventId,
      String eventName,
      int eventNumber,
      DateTime eventStartDatetime,
      int canEditRunAttendence,
      String? hemId,
      int attendenceState,
      int isHare,
      double? creditAmount,
      double? debitAmount,
      double? creditAvailable,
      int? paymentType,
      String? extrasDescription,
      double? extrasPrice,
      int? doPayForExtras,
      int? totalRunsThisKennel,
      int? totalHaringThisKennel,
      @JsonKey(includeFromJson: false, includeToJson: false) bool isUpdating});
}

/// @nodoc
class __$UserRunHistoryModelCopyWithImpl<$Res>
    implements _$UserRunHistoryModelCopyWith<$Res> {
  __$UserRunHistoryModelCopyWithImpl(this._self, this._then);

  final _UserRunHistoryModel _self;
  final $Res Function(_UserRunHistoryModel) _then;

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? eventId = null,
    Object? eventName = null,
    Object? eventNumber = null,
    Object? eventStartDatetime = null,
    Object? canEditRunAttendence = null,
    Object? hemId = freezed,
    Object? attendenceState = null,
    Object? isHare = null,
    Object? creditAmount = freezed,
    Object? debitAmount = freezed,
    Object? creditAvailable = freezed,
    Object? paymentType = freezed,
    Object? extrasDescription = freezed,
    Object? extrasPrice = freezed,
    Object? doPayForExtras = freezed,
    Object? totalRunsThisKennel = freezed,
    Object? totalHaringThisKennel = freezed,
    Object? isUpdating = null,
  }) {
    return _then(_UserRunHistoryModel(
      eventId: null == eventId
          ? _self.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
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
      canEditRunAttendence: null == canEditRunAttendence
          ? _self.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int,
      hemId: freezed == hemId
          ? _self.hemId
          : hemId // ignore: cast_nullable_to_non_nullable
              as String?,
      attendenceState: null == attendenceState
          ? _self.attendenceState
          : attendenceState // ignore: cast_nullable_to_non_nullable
              as int,
      isHare: null == isHare
          ? _self.isHare
          : isHare // ignore: cast_nullable_to_non_nullable
              as int,
      creditAmount: freezed == creditAmount
          ? _self.creditAmount
          : creditAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      debitAmount: freezed == debitAmount
          ? _self.debitAmount
          : debitAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      creditAvailable: freezed == creditAvailable
          ? _self.creditAvailable
          : creditAvailable // ignore: cast_nullable_to_non_nullable
              as double?,
      paymentType: freezed == paymentType
          ? _self.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int?,
      extrasDescription: freezed == extrasDescription
          ? _self.extrasDescription
          : extrasDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      extrasPrice: freezed == extrasPrice
          ? _self.extrasPrice
          : extrasPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      doPayForExtras: freezed == doPayForExtras
          ? _self.doPayForExtras
          : doPayForExtras // ignore: cast_nullable_to_non_nullable
              as int?,
      totalRunsThisKennel: freezed == totalRunsThisKennel
          ? _self.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      totalHaringThisKennel: freezed == totalHaringThisKennel
          ? _self.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      isUpdating: null == isUpdating
          ? _self.isUpdating
          : isUpdating // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
