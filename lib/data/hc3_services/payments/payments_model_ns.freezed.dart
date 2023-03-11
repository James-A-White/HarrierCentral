// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payments_model_ns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

PaymentsModel _$PaymentsModelFromJson(Map<String, dynamic> json) {
  return _PaymentsModel.fromJson(json);
}

/// @nodoc
mixin _$PaymentsModel {
  String get paymentId => throw _privateConstructorUsedError;
  String get kennelId => throw _privateConstructorUsedError;
  String get paidBy => throw _privateConstructorUsedError;
  String get hemId => throw _privateConstructorUsedError;
  String get eventId => throw _privateConstructorUsedError;
  String get paidTo => throw _privateConstructorUsedError;
  num get creditAmount => throw _privateConstructorUsedError;
  num get debitAmount => throw _privateConstructorUsedError;
  num get creditAvailable => throw _privateConstructorUsedError;
  DateTime get paidDate => throw _privateConstructorUsedError;
  int get paymentType => throw _privateConstructorUsedError;
  int get productType => throw _privateConstructorUsedError;
  DateTime? get cancelledDate => throw _privateConstructorUsedError;
  String? get cancelledBy => throw _privateConstructorUsedError;
  DateTime? get confirmedDate => throw _privateConstructorUsedError;
  String? get confirmedBy => throw _privateConstructorUsedError;
  String? get paymentReference => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get doPayForExtras => throw _privateConstructorUsedError;
  num get surcharge => throw _privateConstructorUsedError;
  String? get paymentProvider => throw _privateConstructorUsedError;
  num get discountAmount => throw _privateConstructorUsedError;
  int get discountPercent => throw _privateConstructorUsedError;
  String get discountDescription => throw _privateConstructorUsedError;
  String get specialRunPriceReason => throw _privateConstructorUsedError;
  int get removed => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaymentsModelCopyWith<PaymentsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentsModelCopyWith<$Res> {
  factory $PaymentsModelCopyWith(
          PaymentsModel value, $Res Function(PaymentsModel) then) =
      _$PaymentsModelCopyWithImpl<$Res, PaymentsModel>;
  @useResult
  $Res call(
      {String paymentId,
      String kennelId,
      String paidBy,
      String hemId,
      String eventId,
      String paidTo,
      num creditAmount,
      num debitAmount,
      num creditAvailable,
      DateTime paidDate,
      int paymentType,
      int productType,
      DateTime? cancelledDate,
      String? cancelledBy,
      DateTime? confirmedDate,
      String? confirmedBy,
      String? paymentReference,
      String? notes,
      int doPayForExtras,
      num surcharge,
      String? paymentProvider,
      num discountAmount,
      int discountPercent,
      String discountDescription,
      String specialRunPriceReason,
      int removed,
      DateTime updatedAt});
}

/// @nodoc
class _$PaymentsModelCopyWithImpl<$Res, $Val extends PaymentsModel>
    implements $PaymentsModelCopyWith<$Res> {
  _$PaymentsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paymentId = null,
    Object? kennelId = null,
    Object? paidBy = null,
    Object? hemId = null,
    Object? eventId = null,
    Object? paidTo = null,
    Object? creditAmount = null,
    Object? debitAmount = null,
    Object? creditAvailable = null,
    Object? paidDate = null,
    Object? paymentType = null,
    Object? productType = null,
    Object? cancelledDate = freezed,
    Object? cancelledBy = freezed,
    Object? confirmedDate = freezed,
    Object? confirmedBy = freezed,
    Object? paymentReference = freezed,
    Object? notes = freezed,
    Object? doPayForExtras = null,
    Object? surcharge = null,
    Object? paymentProvider = freezed,
    Object? discountAmount = null,
    Object? discountPercent = null,
    Object? discountDescription = null,
    Object? specialRunPriceReason = null,
    Object? removed = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      paymentId: null == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelId: null == kennelId
          ? _value.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      paidBy: null == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as String,
      hemId: null == hemId
          ? _value.hemId
          : hemId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      paidTo: null == paidTo
          ? _value.paidTo
          : paidTo // ignore: cast_nullable_to_non_nullable
              as String,
      creditAmount: null == creditAmount
          ? _value.creditAmount
          : creditAmount // ignore: cast_nullable_to_non_nullable
              as num,
      debitAmount: null == debitAmount
          ? _value.debitAmount
          : debitAmount // ignore: cast_nullable_to_non_nullable
              as num,
      creditAvailable: null == creditAvailable
          ? _value.creditAvailable
          : creditAvailable // ignore: cast_nullable_to_non_nullable
              as num,
      paidDate: null == paidDate
          ? _value.paidDate
          : paidDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int,
      productType: null == productType
          ? _value.productType
          : productType // ignore: cast_nullable_to_non_nullable
              as int,
      cancelledDate: freezed == cancelledDate
          ? _value.cancelledDate
          : cancelledDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledBy: freezed == cancelledBy
          ? _value.cancelledBy
          : cancelledBy // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedDate: freezed == confirmedDate
          ? _value.confirmedDate
          : confirmedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmedBy: freezed == confirmedBy
          ? _value.confirmedBy
          : confirmedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentReference: freezed == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      doPayForExtras: null == doPayForExtras
          ? _value.doPayForExtras
          : doPayForExtras // ignore: cast_nullable_to_non_nullable
              as int,
      surcharge: null == surcharge
          ? _value.surcharge
          : surcharge // ignore: cast_nullable_to_non_nullable
              as num,
      paymentProvider: freezed == paymentProvider
          ? _value.paymentProvider
          : paymentProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num,
      discountPercent: null == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as int,
      discountDescription: null == discountDescription
          ? _value.discountDescription
          : discountDescription // ignore: cast_nullable_to_non_nullable
              as String,
      specialRunPriceReason: null == specialRunPriceReason
          ? _value.specialRunPriceReason
          : specialRunPriceReason // ignore: cast_nullable_to_non_nullable
              as String,
      removed: null == removed
          ? _value.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_PaymentsModelCopyWith<$Res>
    implements $PaymentsModelCopyWith<$Res> {
  factory _$$_PaymentsModelCopyWith(
          _$_PaymentsModel value, $Res Function(_$_PaymentsModel) then) =
      __$$_PaymentsModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String paymentId,
      String kennelId,
      String paidBy,
      String hemId,
      String eventId,
      String paidTo,
      num creditAmount,
      num debitAmount,
      num creditAvailable,
      DateTime paidDate,
      int paymentType,
      int productType,
      DateTime? cancelledDate,
      String? cancelledBy,
      DateTime? confirmedDate,
      String? confirmedBy,
      String? paymentReference,
      String? notes,
      int doPayForExtras,
      num surcharge,
      String? paymentProvider,
      num discountAmount,
      int discountPercent,
      String discountDescription,
      String specialRunPriceReason,
      int removed,
      DateTime updatedAt});
}

/// @nodoc
class __$$_PaymentsModelCopyWithImpl<$Res>
    extends _$PaymentsModelCopyWithImpl<$Res, _$_PaymentsModel>
    implements _$$_PaymentsModelCopyWith<$Res> {
  __$$_PaymentsModelCopyWithImpl(
      _$_PaymentsModel _value, $Res Function(_$_PaymentsModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paymentId = null,
    Object? kennelId = null,
    Object? paidBy = null,
    Object? hemId = null,
    Object? eventId = null,
    Object? paidTo = null,
    Object? creditAmount = null,
    Object? debitAmount = null,
    Object? creditAvailable = null,
    Object? paidDate = null,
    Object? paymentType = null,
    Object? productType = null,
    Object? cancelledDate = freezed,
    Object? cancelledBy = freezed,
    Object? confirmedDate = freezed,
    Object? confirmedBy = freezed,
    Object? paymentReference = freezed,
    Object? notes = freezed,
    Object? doPayForExtras = null,
    Object? surcharge = null,
    Object? paymentProvider = freezed,
    Object? discountAmount = null,
    Object? discountPercent = null,
    Object? discountDescription = null,
    Object? specialRunPriceReason = null,
    Object? removed = null,
    Object? updatedAt = null,
  }) {
    return _then(_$_PaymentsModel(
      paymentId: null == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelId: null == kennelId
          ? _value.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      paidBy: null == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as String,
      hemId: null == hemId
          ? _value.hemId
          : hemId // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      paidTo: null == paidTo
          ? _value.paidTo
          : paidTo // ignore: cast_nullable_to_non_nullable
              as String,
      creditAmount: null == creditAmount
          ? _value.creditAmount
          : creditAmount // ignore: cast_nullable_to_non_nullable
              as num,
      debitAmount: null == debitAmount
          ? _value.debitAmount
          : debitAmount // ignore: cast_nullable_to_non_nullable
              as num,
      creditAvailable: null == creditAvailable
          ? _value.creditAvailable
          : creditAvailable // ignore: cast_nullable_to_non_nullable
              as num,
      paidDate: null == paidDate
          ? _value.paidDate
          : paidDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as int,
      productType: null == productType
          ? _value.productType
          : productType // ignore: cast_nullable_to_non_nullable
              as int,
      cancelledDate: freezed == cancelledDate
          ? _value.cancelledDate
          : cancelledDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledBy: freezed == cancelledBy
          ? _value.cancelledBy
          : cancelledBy // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedDate: freezed == confirmedDate
          ? _value.confirmedDate
          : confirmedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmedBy: freezed == confirmedBy
          ? _value.confirmedBy
          : confirmedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentReference: freezed == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      doPayForExtras: null == doPayForExtras
          ? _value.doPayForExtras
          : doPayForExtras // ignore: cast_nullable_to_non_nullable
              as int,
      surcharge: null == surcharge
          ? _value.surcharge
          : surcharge // ignore: cast_nullable_to_non_nullable
              as num,
      paymentProvider: freezed == paymentProvider
          ? _value.paymentProvider
          : paymentProvider // ignore: cast_nullable_to_non_nullable
              as String?,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as num,
      discountPercent: null == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as int,
      discountDescription: null == discountDescription
          ? _value.discountDescription
          : discountDescription // ignore: cast_nullable_to_non_nullable
              as String,
      specialRunPriceReason: null == specialRunPriceReason
          ? _value.specialRunPriceReason
          : specialRunPriceReason // ignore: cast_nullable_to_non_nullable
              as String,
      removed: null == removed
          ? _value.removed
          : removed // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_PaymentsModel implements _PaymentsModel {
  _$_PaymentsModel(
      {required this.paymentId,
      required this.kennelId,
      required this.paidBy,
      required this.hemId,
      required this.eventId,
      required this.paidTo,
      required this.creditAmount,
      required this.debitAmount,
      required this.creditAvailable,
      required this.paidDate,
      required this.paymentType,
      required this.productType,
      this.cancelledDate,
      this.cancelledBy,
      this.confirmedDate,
      this.confirmedBy,
      this.paymentReference,
      this.notes,
      required this.doPayForExtras,
      required this.surcharge,
      this.paymentProvider,
      required this.discountAmount,
      required this.discountPercent,
      required this.discountDescription,
      required this.specialRunPriceReason,
      required this.removed,
      required this.updatedAt});

  factory _$_PaymentsModel.fromJson(Map<String, dynamic> json) =>
      _$$_PaymentsModelFromJson(json);

  @override
  final String paymentId;
  @override
  final String kennelId;
  @override
  final String paidBy;
  @override
  final String hemId;
  @override
  final String eventId;
  @override
  final String paidTo;
  @override
  final num creditAmount;
  @override
  final num debitAmount;
  @override
  final num creditAvailable;
  @override
  final DateTime paidDate;
  @override
  final int paymentType;
  @override
  final int productType;
  @override
  final DateTime? cancelledDate;
  @override
  final String? cancelledBy;
  @override
  final DateTime? confirmedDate;
  @override
  final String? confirmedBy;
  @override
  final String? paymentReference;
  @override
  final String? notes;
  @override
  final int doPayForExtras;
  @override
  final num surcharge;
  @override
  final String? paymentProvider;
  @override
  final num discountAmount;
  @override
  final int discountPercent;
  @override
  final String discountDescription;
  @override
  final String specialRunPriceReason;
  @override
  final int removed;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'PaymentsModel(paymentId: $paymentId, kennelId: $kennelId, paidBy: $paidBy, hemId: $hemId, eventId: $eventId, paidTo: $paidTo, creditAmount: $creditAmount, debitAmount: $debitAmount, creditAvailable: $creditAvailable, paidDate: $paidDate, paymentType: $paymentType, productType: $productType, cancelledDate: $cancelledDate, cancelledBy: $cancelledBy, confirmedDate: $confirmedDate, confirmedBy: $confirmedBy, paymentReference: $paymentReference, notes: $notes, doPayForExtras: $doPayForExtras, surcharge: $surcharge, paymentProvider: $paymentProvider, discountAmount: $discountAmount, discountPercent: $discountPercent, discountDescription: $discountDescription, specialRunPriceReason: $specialRunPriceReason, removed: $removed, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_PaymentsModel &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.paidBy, paidBy) || other.paidBy == paidBy) &&
            (identical(other.hemId, hemId) || other.hemId == hemId) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.paidTo, paidTo) || other.paidTo == paidTo) &&
            (identical(other.creditAmount, creditAmount) ||
                other.creditAmount == creditAmount) &&
            (identical(other.debitAmount, debitAmount) ||
                other.debitAmount == debitAmount) &&
            (identical(other.creditAvailable, creditAvailable) ||
                other.creditAvailable == creditAvailable) &&
            (identical(other.paidDate, paidDate) ||
                other.paidDate == paidDate) &&
            (identical(other.paymentType, paymentType) ||
                other.paymentType == paymentType) &&
            (identical(other.productType, productType) ||
                other.productType == productType) &&
            (identical(other.cancelledDate, cancelledDate) ||
                other.cancelledDate == cancelledDate) &&
            (identical(other.cancelledBy, cancelledBy) ||
                other.cancelledBy == cancelledBy) &&
            (identical(other.confirmedDate, confirmedDate) ||
                other.confirmedDate == confirmedDate) &&
            (identical(other.confirmedBy, confirmedBy) ||
                other.confirmedBy == confirmedBy) &&
            (identical(other.paymentReference, paymentReference) ||
                other.paymentReference == paymentReference) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.doPayForExtras, doPayForExtras) ||
                other.doPayForExtras == doPayForExtras) &&
            (identical(other.surcharge, surcharge) ||
                other.surcharge == surcharge) &&
            (identical(other.paymentProvider, paymentProvider) ||
                other.paymentProvider == paymentProvider) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent) &&
            (identical(other.discountDescription, discountDescription) ||
                other.discountDescription == discountDescription) &&
            (identical(other.specialRunPriceReason, specialRunPriceReason) ||
                other.specialRunPriceReason == specialRunPriceReason) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        paymentId,
        kennelId,
        paidBy,
        hemId,
        eventId,
        paidTo,
        creditAmount,
        debitAmount,
        creditAvailable,
        paidDate,
        paymentType,
        productType,
        cancelledDate,
        cancelledBy,
        confirmedDate,
        confirmedBy,
        paymentReference,
        notes,
        doPayForExtras,
        surcharge,
        paymentProvider,
        discountAmount,
        discountPercent,
        discountDescription,
        specialRunPriceReason,
        removed,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_PaymentsModelCopyWith<_$_PaymentsModel> get copyWith =>
      __$$_PaymentsModelCopyWithImpl<_$_PaymentsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_PaymentsModelToJson(
      this,
    );
  }
}

abstract class _PaymentsModel implements PaymentsModel {
  factory _PaymentsModel(
      {required final String paymentId,
      required final String kennelId,
      required final String paidBy,
      required final String hemId,
      required final String eventId,
      required final String paidTo,
      required final num creditAmount,
      required final num debitAmount,
      required final num creditAvailable,
      required final DateTime paidDate,
      required final int paymentType,
      required final int productType,
      final DateTime? cancelledDate,
      final String? cancelledBy,
      final DateTime? confirmedDate,
      final String? confirmedBy,
      final String? paymentReference,
      final String? notes,
      required final int doPayForExtras,
      required final num surcharge,
      final String? paymentProvider,
      required final num discountAmount,
      required final int discountPercent,
      required final String discountDescription,
      required final String specialRunPriceReason,
      required final int removed,
      required final DateTime updatedAt}) = _$_PaymentsModel;

  factory _PaymentsModel.fromJson(Map<String, dynamic> json) =
      _$_PaymentsModel.fromJson;

  @override
  String get paymentId;
  @override
  String get kennelId;
  @override
  String get paidBy;
  @override
  String get hemId;
  @override
  String get eventId;
  @override
  String get paidTo;
  @override
  num get creditAmount;
  @override
  num get debitAmount;
  @override
  num get creditAvailable;
  @override
  DateTime get paidDate;
  @override
  int get paymentType;
  @override
  int get productType;
  @override
  DateTime? get cancelledDate;
  @override
  String? get cancelledBy;
  @override
  DateTime? get confirmedDate;
  @override
  String? get confirmedBy;
  @override
  String? get paymentReference;
  @override
  String? get notes;
  @override
  int get doPayForExtras;
  @override
  num get surcharge;
  @override
  String? get paymentProvider;
  @override
  num get discountAmount;
  @override
  int get discountPercent;
  @override
  String get discountDescription;
  @override
  String get specialRunPriceReason;
  @override
  int get removed;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$_PaymentsModelCopyWith<_$_PaymentsModel> get copyWith =>
      throw _privateConstructorUsedError;
}
