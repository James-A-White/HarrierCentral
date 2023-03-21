// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

RunHistoryModel _$RunHistoryModelFromJson(Map<String, dynamic> json) {
  return _RunHistoryModel.fromJson(json);
}

/// @nodoc
mixin _$RunHistoryModel {
  int get totalRunsThisKennel => throw _privateConstructorUsedError;
  int get totalHaringThisKennel => throw _privateConstructorUsedError;
  int get hcRunsThisKennel => throw _privateConstructorUsedError;
  int get hcHaringThisKennel => throw _privateConstructorUsedError;
  String get kennelName => throw _privateConstructorUsedError;
  String get kennelShortName => throw _privateConstructorUsedError;
  String get kennelId => throw _privateConstructorUsedError;
  String get kennelLogo => throw _privateConstructorUsedError;
  String get currencySymbol => throw _privateConstructorUsedError;
  double get kennelCredit => throw _privateConstructorUsedError;
  int get historicalHaringCount => throw _privateConstructorUsedError;
  int get historicalTotalRunCount => throw _privateConstructorUsedError;
  int get historicalCountIsEstimate => throw _privateConstructorUsedError;
  int get following => throw _privateConstructorUsedError;
  int get digitsAfterDecimal => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RunHistoryModelCopyWith<RunHistoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RunHistoryModelCopyWith<$Res> {
  factory $RunHistoryModelCopyWith(
          RunHistoryModel value, $Res Function(RunHistoryModel) then) =
      _$RunHistoryModelCopyWithImpl<$Res, RunHistoryModel>;
  @useResult
  $Res call(
      {int totalRunsThisKennel,
      int totalHaringThisKennel,
      int hcRunsThisKennel,
      int hcHaringThisKennel,
      String kennelName,
      String kennelShortName,
      String kennelId,
      String kennelLogo,
      String currencySymbol,
      double kennelCredit,
      int historicalHaringCount,
      int historicalTotalRunCount,
      int historicalCountIsEstimate,
      int following,
      int digitsAfterDecimal});
}

/// @nodoc
class _$RunHistoryModelCopyWithImpl<$Res, $Val extends RunHistoryModel>
    implements $RunHistoryModelCopyWith<$Res> {
  _$RunHistoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalRunsThisKennel = null,
    Object? totalHaringThisKennel = null,
    Object? hcRunsThisKennel = null,
    Object? hcHaringThisKennel = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelId = null,
    Object? kennelLogo = null,
    Object? currencySymbol = null,
    Object? kennelCredit = null,
    Object? historicalHaringCount = null,
    Object? historicalTotalRunCount = null,
    Object? historicalCountIsEstimate = null,
    Object? following = null,
    Object? digitsAfterDecimal = null,
  }) {
    return _then(_value.copyWith(
      totalRunsThisKennel: null == totalRunsThisKennel
          ? _value.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      totalHaringThisKennel: null == totalHaringThisKennel
          ? _value.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcRunsThisKennel: null == hcRunsThisKennel
          ? _value.hcRunsThisKennel
          : hcRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringThisKennel: null == hcHaringThisKennel
          ? _value.hcHaringThisKennel
          : hcHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      kennelName: null == kennelName
          ? _value.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _value.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelId: null == kennelId
          ? _value.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _value.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      currencySymbol: null == currencySymbol
          ? _value.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCredit: null == kennelCredit
          ? _value.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as double,
      historicalHaringCount: null == historicalHaringCount
          ? _value.historicalHaringCount
          : historicalHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalTotalRunCount: null == historicalTotalRunCount
          ? _value.historicalTotalRunCount
          : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalCountIsEstimate: null == historicalCountIsEstimate
          ? _value.historicalCountIsEstimate
          : historicalCountIsEstimate // ignore: cast_nullable_to_non_nullable
              as int,
      following: null == following
          ? _value.following
          : following // ignore: cast_nullable_to_non_nullable
              as int,
      digitsAfterDecimal: null == digitsAfterDecimal
          ? _value.digitsAfterDecimal
          : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_RunHistoryModelCopyWith<$Res>
    implements $RunHistoryModelCopyWith<$Res> {
  factory _$$_RunHistoryModelCopyWith(
          _$_RunHistoryModel value, $Res Function(_$_RunHistoryModel) then) =
      __$$_RunHistoryModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalRunsThisKennel,
      int totalHaringThisKennel,
      int hcRunsThisKennel,
      int hcHaringThisKennel,
      String kennelName,
      String kennelShortName,
      String kennelId,
      String kennelLogo,
      String currencySymbol,
      double kennelCredit,
      int historicalHaringCount,
      int historicalTotalRunCount,
      int historicalCountIsEstimate,
      int following,
      int digitsAfterDecimal});
}

/// @nodoc
class __$$_RunHistoryModelCopyWithImpl<$Res>
    extends _$RunHistoryModelCopyWithImpl<$Res, _$_RunHistoryModel>
    implements _$$_RunHistoryModelCopyWith<$Res> {
  __$$_RunHistoryModelCopyWithImpl(
      _$_RunHistoryModel _value, $Res Function(_$_RunHistoryModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalRunsThisKennel = null,
    Object? totalHaringThisKennel = null,
    Object? hcRunsThisKennel = null,
    Object? hcHaringThisKennel = null,
    Object? kennelName = null,
    Object? kennelShortName = null,
    Object? kennelId = null,
    Object? kennelLogo = null,
    Object? currencySymbol = null,
    Object? kennelCredit = null,
    Object? historicalHaringCount = null,
    Object? historicalTotalRunCount = null,
    Object? historicalCountIsEstimate = null,
    Object? following = null,
    Object? digitsAfterDecimal = null,
  }) {
    return _then(_$_RunHistoryModel(
      totalRunsThisKennel: null == totalRunsThisKennel
          ? _value.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      totalHaringThisKennel: null == totalHaringThisKennel
          ? _value.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcRunsThisKennel: null == hcRunsThisKennel
          ? _value.hcRunsThisKennel
          : hcRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringThisKennel: null == hcHaringThisKennel
          ? _value.hcHaringThisKennel
          : hcHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      kennelName: null == kennelName
          ? _value.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _value.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelId: null == kennelId
          ? _value.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _value.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      currencySymbol: null == currencySymbol
          ? _value.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCredit: null == kennelCredit
          ? _value.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as double,
      historicalHaringCount: null == historicalHaringCount
          ? _value.historicalHaringCount
          : historicalHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalTotalRunCount: null == historicalTotalRunCount
          ? _value.historicalTotalRunCount
          : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalCountIsEstimate: null == historicalCountIsEstimate
          ? _value.historicalCountIsEstimate
          : historicalCountIsEstimate // ignore: cast_nullable_to_non_nullable
              as int,
      following: null == following
          ? _value.following
          : following // ignore: cast_nullable_to_non_nullable
              as int,
      digitsAfterDecimal: null == digitsAfterDecimal
          ? _value.digitsAfterDecimal
          : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_RunHistoryModel implements _RunHistoryModel {
  _$_RunHistoryModel(
      {required this.totalRunsThisKennel,
      required this.totalHaringThisKennel,
      required this.hcRunsThisKennel,
      required this.hcHaringThisKennel,
      required this.kennelName,
      required this.kennelShortName,
      required this.kennelId,
      required this.kennelLogo,
      required this.currencySymbol,
      required this.kennelCredit,
      required this.historicalHaringCount,
      required this.historicalTotalRunCount,
      required this.historicalCountIsEstimate,
      required this.following,
      required this.digitsAfterDecimal});

  factory _$_RunHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$$_RunHistoryModelFromJson(json);

  @override
  final int totalRunsThisKennel;
  @override
  final int totalHaringThisKennel;
  @override
  final int hcRunsThisKennel;
  @override
  final int hcHaringThisKennel;
  @override
  final String kennelName;
  @override
  final String kennelShortName;
  @override
  final String kennelId;
  @override
  final String kennelLogo;
  @override
  final String currencySymbol;
  @override
  final double kennelCredit;
  @override
  final int historicalHaringCount;
  @override
  final int historicalTotalRunCount;
  @override
  final int historicalCountIsEstimate;
  @override
  final int following;
  @override
  final int digitsAfterDecimal;

  @override
  String toString() {
    return 'RunHistoryModel(totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, hcRunsThisKennel: $hcRunsThisKennel, hcHaringThisKennel: $hcHaringThisKennel, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelId: $kennelId, kennelLogo: $kennelLogo, currencySymbol: $currencySymbol, kennelCredit: $kennelCredit, historicalHaringCount: $historicalHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalCountIsEstimate: $historicalCountIsEstimate, following: $following, digitsAfterDecimal: $digitsAfterDecimal)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_RunHistoryModel &&
            (identical(other.totalRunsThisKennel, totalRunsThisKennel) ||
                other.totalRunsThisKennel == totalRunsThisKennel) &&
            (identical(other.totalHaringThisKennel, totalHaringThisKennel) ||
                other.totalHaringThisKennel == totalHaringThisKennel) &&
            (identical(other.hcRunsThisKennel, hcRunsThisKennel) ||
                other.hcRunsThisKennel == hcRunsThisKennel) &&
            (identical(other.hcHaringThisKennel, hcHaringThisKennel) ||
                other.hcHaringThisKennel == hcHaringThisKennel) &&
            (identical(other.kennelName, kennelName) ||
                other.kennelName == kennelName) &&
            (identical(other.kennelShortName, kennelShortName) ||
                other.kennelShortName == kennelShortName) &&
            (identical(other.kennelId, kennelId) ||
                other.kennelId == kennelId) &&
            (identical(other.kennelLogo, kennelLogo) ||
                other.kennelLogo == kennelLogo) &&
            (identical(other.currencySymbol, currencySymbol) ||
                other.currencySymbol == currencySymbol) &&
            (identical(other.kennelCredit, kennelCredit) ||
                other.kennelCredit == kennelCredit) &&
            (identical(other.historicalHaringCount, historicalHaringCount) ||
                other.historicalHaringCount == historicalHaringCount) &&
            (identical(
                    other.historicalTotalRunCount, historicalTotalRunCount) ||
                other.historicalTotalRunCount == historicalTotalRunCount) &&
            (identical(other.historicalCountIsEstimate,
                    historicalCountIsEstimate) ||
                other.historicalCountIsEstimate == historicalCountIsEstimate) &&
            (identical(other.following, following) ||
                other.following == following) &&
            (identical(other.digitsAfterDecimal, digitsAfterDecimal) ||
                other.digitsAfterDecimal == digitsAfterDecimal));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalRunsThisKennel,
      totalHaringThisKennel,
      hcRunsThisKennel,
      hcHaringThisKennel,
      kennelName,
      kennelShortName,
      kennelId,
      kennelLogo,
      currencySymbol,
      kennelCredit,
      historicalHaringCount,
      historicalTotalRunCount,
      historicalCountIsEstimate,
      following,
      digitsAfterDecimal);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_RunHistoryModelCopyWith<_$_RunHistoryModel> get copyWith =>
      __$$_RunHistoryModelCopyWithImpl<_$_RunHistoryModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_RunHistoryModelToJson(
      this,
    );
  }
}

abstract class _RunHistoryModel implements RunHistoryModel {
  factory _RunHistoryModel(
      {required final int totalRunsThisKennel,
      required final int totalHaringThisKennel,
      required final int hcRunsThisKennel,
      required final int hcHaringThisKennel,
      required final String kennelName,
      required final String kennelShortName,
      required final String kennelId,
      required final String kennelLogo,
      required final String currencySymbol,
      required final double kennelCredit,
      required final int historicalHaringCount,
      required final int historicalTotalRunCount,
      required final int historicalCountIsEstimate,
      required final int following,
      required final int digitsAfterDecimal}) = _$_RunHistoryModel;

  factory _RunHistoryModel.fromJson(Map<String, dynamic> json) =
      _$_RunHistoryModel.fromJson;

  @override
  int get totalRunsThisKennel;
  @override
  int get totalHaringThisKennel;
  @override
  int get hcRunsThisKennel;
  @override
  int get hcHaringThisKennel;
  @override
  String get kennelName;
  @override
  String get kennelShortName;
  @override
  String get kennelId;
  @override
  String get kennelLogo;
  @override
  String get currencySymbol;
  @override
  double get kennelCredit;
  @override
  int get historicalHaringCount;
  @override
  int get historicalTotalRunCount;
  @override
  int get historicalCountIsEstimate;
  @override
  int get following;
  @override
  int get digitsAfterDecimal;
  @override
  @JsonKey(ignore: true)
  _$$_RunHistoryModelCopyWith<_$_RunHistoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}
