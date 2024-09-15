// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_run_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserRunHistoryModel _$UserRunHistoryModelFromJson(Map<String, dynamic> json) {
  return _UserRunHistoryModel.fromJson(json);
}

/// @nodoc
mixin _$UserRunHistoryModel {
  String get eventId => throw _privateConstructorUsedError;
  String get eventName => throw _privateConstructorUsedError;
  int get eventNumber => throw _privateConstructorUsedError;
  DateTime get eventStartDatetime => throw _privateConstructorUsedError;
  int get canEditRunAttendence => throw _privateConstructorUsedError;
  String? get hemId => throw _privateConstructorUsedError;
  int get attendenceState => throw _privateConstructorUsedError;
  int get isHare => throw _privateConstructorUsedError;
  double? get creditAmount => throw _privateConstructorUsedError;
  double? get debitAmount => throw _privateConstructorUsedError;
  double? get creditAvailable => throw _privateConstructorUsedError;
  int? get paymentType => throw _privateConstructorUsedError;
  String? get extrasDescription => throw _privateConstructorUsedError;
  double? get extrasPrice => throw _privateConstructorUsedError;
  int? get doPayForExtras => throw _privateConstructorUsedError;
  int? get totalRunsThisKennel => throw _privateConstructorUsedError;
  int? get totalHaringThisKennel => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isUpdating => throw _privateConstructorUsedError;

  /// Serializes this UserRunHistoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserRunHistoryModelCopyWith<UserRunHistoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRunHistoryModelCopyWith<$Res> {
  factory $UserRunHistoryModelCopyWith(
          UserRunHistoryModel value, $Res Function(UserRunHistoryModel) then) =
      _$UserRunHistoryModelCopyWithImpl<$Res, UserRunHistoryModel>;
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
class _$UserRunHistoryModelCopyWithImpl<$Res, $Val extends UserRunHistoryModel>
    implements $UserRunHistoryModelCopyWith<$Res> {
  _$UserRunHistoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      eventName: null == eventName
          ? _value.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      eventNumber: null == eventNumber
          ? _value.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventStartDatetime: null == eventStartDatetime
          ? _value.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      canEditRunAttendence: null == canEditRunAttendence
          ? _value.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int,
      hemId: freezed == hemId
          ? _value.hemId
          : hemId // ignore: cast_nullable_to_non_nullable
              as String?,
      attendenceState: null == attendenceState
          ? _value.attendenceState
          : attendenceState // ignore: cast_nullable_to_non_nullable
              as int,
      isHare: null == isHare
          ? _value.isHare
          : isHare // ignore: cast_nullable_to_non_nullable
              as int,
      creditAmount: freezed == creditAmount
          ? _value.creditAmount
          : creditAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      debitAmount: freezed == debitAmount
          ? _value.debitAmount
          : debitAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      creditAvailable: freezed == creditAvailable
          ? _value.creditAvailable
          : creditAvailable // ignore: cast_nullable_to_non_nullable
              as double?,
      paymentType: freezed == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int?,
      extrasDescription: freezed == extrasDescription
          ? _value.extrasDescription
          : extrasDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      extrasPrice: freezed == extrasPrice
          ? _value.extrasPrice
          : extrasPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      doPayForExtras: freezed == doPayForExtras
          ? _value.doPayForExtras
          : doPayForExtras // ignore: cast_nullable_to_non_nullable
              as int?,
      totalRunsThisKennel: freezed == totalRunsThisKennel
          ? _value.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      totalHaringThisKennel: freezed == totalHaringThisKennel
          ? _value.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      isUpdating: null == isUpdating
          ? _value.isUpdating
          : isUpdating // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserRunHistoryModelImplCopyWith<$Res>
    implements $UserRunHistoryModelCopyWith<$Res> {
  factory _$$UserRunHistoryModelImplCopyWith(_$UserRunHistoryModelImpl value,
          $Res Function(_$UserRunHistoryModelImpl) then) =
      __$$UserRunHistoryModelImplCopyWithImpl<$Res>;
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
class __$$UserRunHistoryModelImplCopyWithImpl<$Res>
    extends _$UserRunHistoryModelCopyWithImpl<$Res, _$UserRunHistoryModelImpl>
    implements _$$UserRunHistoryModelImplCopyWith<$Res> {
  __$$UserRunHistoryModelImplCopyWithImpl(_$UserRunHistoryModelImpl _value,
      $Res Function(_$UserRunHistoryModelImpl) _then)
      : super(_value, _then);

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
    return _then(_$UserRunHistoryModelImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      eventName: null == eventName
          ? _value.eventName
          : eventName // ignore: cast_nullable_to_non_nullable
              as String,
      eventNumber: null == eventNumber
          ? _value.eventNumber
          : eventNumber // ignore: cast_nullable_to_non_nullable
              as int,
      eventStartDatetime: null == eventStartDatetime
          ? _value.eventStartDatetime
          : eventStartDatetime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      canEditRunAttendence: null == canEditRunAttendence
          ? _value.canEditRunAttendence
          : canEditRunAttendence // ignore: cast_nullable_to_non_nullable
              as int,
      hemId: freezed == hemId
          ? _value.hemId
          : hemId // ignore: cast_nullable_to_non_nullable
              as String?,
      attendenceState: null == attendenceState
          ? _value.attendenceState
          : attendenceState // ignore: cast_nullable_to_non_nullable
              as int,
      isHare: null == isHare
          ? _value.isHare
          : isHare // ignore: cast_nullable_to_non_nullable
              as int,
      creditAmount: freezed == creditAmount
          ? _value.creditAmount
          : creditAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      debitAmount: freezed == debitAmount
          ? _value.debitAmount
          : debitAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      creditAvailable: freezed == creditAvailable
          ? _value.creditAvailable
          : creditAvailable // ignore: cast_nullable_to_non_nullable
              as double?,
      paymentType: freezed == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int?,
      extrasDescription: freezed == extrasDescription
          ? _value.extrasDescription
          : extrasDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      extrasPrice: freezed == extrasPrice
          ? _value.extrasPrice
          : extrasPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      doPayForExtras: freezed == doPayForExtras
          ? _value.doPayForExtras
          : doPayForExtras // ignore: cast_nullable_to_non_nullable
              as int?,
      totalRunsThisKennel: freezed == totalRunsThisKennel
          ? _value.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      totalHaringThisKennel: freezed == totalHaringThisKennel
          ? _value.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int?,
      isUpdating: null == isUpdating
          ? _value.isUpdating
          : isUpdating // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserRunHistoryModelImpl implements _UserRunHistoryModel {
  _$UserRunHistoryModelImpl(
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

  factory _$UserRunHistoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRunHistoryModelImplFromJson(json);

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

  @override
  String toString() {
    return 'UserRunHistoryModel(eventId: $eventId, eventName: $eventName, eventNumber: $eventNumber, eventStartDatetime: $eventStartDatetime, canEditRunAttendence: $canEditRunAttendence, hemId: $hemId, attendenceState: $attendenceState, isHare: $isHare, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paymentType: $paymentType, extrasDescription: $extrasDescription, extrasPrice: $extrasPrice, doPayForExtras: $doPayForExtras, totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, isUpdating: $isUpdating)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRunHistoryModelImpl &&
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

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRunHistoryModelImplCopyWith<_$UserRunHistoryModelImpl> get copyWith =>
      __$$UserRunHistoryModelImplCopyWithImpl<_$UserRunHistoryModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRunHistoryModelImplToJson(
      this,
    );
  }
}

abstract class _UserRunHistoryModel implements UserRunHistoryModel {
  factory _UserRunHistoryModel(
      {required final String eventId,
      required final String eventName,
      required final int eventNumber,
      required final DateTime eventStartDatetime,
      final int canEditRunAttendence,
      final String? hemId,
      final int attendenceState,
      final int isHare,
      final double? creditAmount,
      final double? debitAmount,
      final double? creditAvailable,
      final int? paymentType,
      final String? extrasDescription,
      final double? extrasPrice,
      final int? doPayForExtras,
      final int? totalRunsThisKennel,
      final int? totalHaringThisKennel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final bool isUpdating}) = _$UserRunHistoryModelImpl;

  factory _UserRunHistoryModel.fromJson(Map<String, dynamic> json) =
      _$UserRunHistoryModelImpl.fromJson;

  @override
  String get eventId;
  @override
  String get eventName;
  @override
  int get eventNumber;
  @override
  DateTime get eventStartDatetime;
  @override
  int get canEditRunAttendence;
  @override
  String? get hemId;
  @override
  int get attendenceState;
  @override
  int get isHare;
  @override
  double? get creditAmount;
  @override
  double? get debitAmount;
  @override
  double? get creditAvailable;
  @override
  int? get paymentType;
  @override
  String? get extrasDescription;
  @override
  double? get extrasPrice;
  @override
  int? get doPayForExtras;
  @override
  int? get totalRunsThisKennel;
  @override
  int? get totalHaringThisKennel;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isUpdating;

  /// Create a copy of UserRunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserRunHistoryModelImplCopyWith<_$UserRunHistoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
