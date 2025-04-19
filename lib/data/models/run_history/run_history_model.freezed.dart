// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RunHistoryModel implements DiagnosticableTreeMixin {
  int get totalRunsThisKennel;
  int get totalHaringThisKennel;
  int get hcRunsThisKennel;
  int get hcHaringThisKennel;
  String get kennelName;
  String get kennelShortName;
  String get kennelId;
  String get kennelLogo;
  String get currencySymbol;
  double get kennelCredit;
  int get historicalHaringCount;
  int get historicalTotalRunCount;
  int get historicalCountIsEstimate;
  int get following;
  int get digitsAfterDecimal;

  /// Create a copy of RunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RunHistoryModelCopyWith<RunHistoryModel> get copyWith =>
      _$RunHistoryModelCopyWithImpl<RunHistoryModel>(
          this as RunHistoryModel, _$identity);

  /// Serializes this RunHistoryModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RunHistoryModel'))
      ..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))
      ..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))
      ..add(DiagnosticsProperty('hcRunsThisKennel', hcRunsThisKennel))
      ..add(DiagnosticsProperty('hcHaringThisKennel', hcHaringThisKennel))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelId', kennelId))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('currencySymbol', currencySymbol))
      ..add(DiagnosticsProperty('kennelCredit', kennelCredit))
      ..add(DiagnosticsProperty('historicalHaringCount', historicalHaringCount))
      ..add(DiagnosticsProperty(
          'historicalTotalRunCount', historicalTotalRunCount))
      ..add(DiagnosticsProperty(
          'historicalCountIsEstimate', historicalCountIsEstimate))
      ..add(DiagnosticsProperty('following', following))
      ..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RunHistoryModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunHistoryModel(totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, hcRunsThisKennel: $hcRunsThisKennel, hcHaringThisKennel: $hcHaringThisKennel, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelId: $kennelId, kennelLogo: $kennelLogo, currencySymbol: $currencySymbol, kennelCredit: $kennelCredit, historicalHaringCount: $historicalHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalCountIsEstimate: $historicalCountIsEstimate, following: $following, digitsAfterDecimal: $digitsAfterDecimal)';
  }
}

/// @nodoc
abstract mixin class $RunHistoryModelCopyWith<$Res> {
  factory $RunHistoryModelCopyWith(
          RunHistoryModel value, $Res Function(RunHistoryModel) _then) =
      _$RunHistoryModelCopyWithImpl;
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
class _$RunHistoryModelCopyWithImpl<$Res>
    implements $RunHistoryModelCopyWith<$Res> {
  _$RunHistoryModelCopyWithImpl(this._self, this._then);

  final RunHistoryModel _self;
  final $Res Function(RunHistoryModel) _then;

  /// Create a copy of RunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      totalRunsThisKennel: null == totalRunsThisKennel
          ? _self.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      totalHaringThisKennel: null == totalHaringThisKennel
          ? _self.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcRunsThisKennel: null == hcRunsThisKennel
          ? _self.hcRunsThisKennel
          : hcRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringThisKennel: null == hcHaringThisKennel
          ? _self.hcHaringThisKennel
          : hcHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelId: null == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      currencySymbol: null == currencySymbol
          ? _self.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCredit: null == kennelCredit
          ? _self.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as double,
      historicalHaringCount: null == historicalHaringCount
          ? _self.historicalHaringCount
          : historicalHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalTotalRunCount: null == historicalTotalRunCount
          ? _self.historicalTotalRunCount
          : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalCountIsEstimate: null == historicalCountIsEstimate
          ? _self.historicalCountIsEstimate
          : historicalCountIsEstimate // ignore: cast_nullable_to_non_nullable
              as int,
      following: null == following
          ? _self.following
          : following // ignore: cast_nullable_to_non_nullable
              as int,
      digitsAfterDecimal: null == digitsAfterDecimal
          ? _self.digitsAfterDecimal
          : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _RunHistoryModel with DiagnosticableTreeMixin implements RunHistoryModel {
  _RunHistoryModel(
      {this.totalRunsThisKennel = 0,
      this.totalHaringThisKennel = 0,
      this.hcRunsThisKennel = 0,
      this.hcHaringThisKennel = 0,
      required this.kennelName,
      required this.kennelShortName,
      required this.kennelId,
      required this.kennelLogo,
      this.currencySymbol = r'$^',
      this.kennelCredit = 0.0,
      this.historicalHaringCount = 0,
      this.historicalTotalRunCount = 0,
      this.historicalCountIsEstimate = 0,
      this.following = 0,
      this.digitsAfterDecimal = 2});
  factory _RunHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$RunHistoryModelFromJson(json);

  @override
  @JsonKey()
  final int totalRunsThisKennel;
  @override
  @JsonKey()
  final int totalHaringThisKennel;
  @override
  @JsonKey()
  final int hcRunsThisKennel;
  @override
  @JsonKey()
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
  @JsonKey()
  final String currencySymbol;
  @override
  @JsonKey()
  final double kennelCredit;
  @override
  @JsonKey()
  final int historicalHaringCount;
  @override
  @JsonKey()
  final int historicalTotalRunCount;
  @override
  @JsonKey()
  final int historicalCountIsEstimate;
  @override
  @JsonKey()
  final int following;
  @override
  @JsonKey()
  final int digitsAfterDecimal;

  /// Create a copy of RunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RunHistoryModelCopyWith<_RunHistoryModel> get copyWith =>
      __$RunHistoryModelCopyWithImpl<_RunHistoryModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RunHistoryModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RunHistoryModel'))
      ..add(DiagnosticsProperty('totalRunsThisKennel', totalRunsThisKennel))
      ..add(DiagnosticsProperty('totalHaringThisKennel', totalHaringThisKennel))
      ..add(DiagnosticsProperty('hcRunsThisKennel', hcRunsThisKennel))
      ..add(DiagnosticsProperty('hcHaringThisKennel', hcHaringThisKennel))
      ..add(DiagnosticsProperty('kennelName', kennelName))
      ..add(DiagnosticsProperty('kennelShortName', kennelShortName))
      ..add(DiagnosticsProperty('kennelId', kennelId))
      ..add(DiagnosticsProperty('kennelLogo', kennelLogo))
      ..add(DiagnosticsProperty('currencySymbol', currencySymbol))
      ..add(DiagnosticsProperty('kennelCredit', kennelCredit))
      ..add(DiagnosticsProperty('historicalHaringCount', historicalHaringCount))
      ..add(DiagnosticsProperty(
          'historicalTotalRunCount', historicalTotalRunCount))
      ..add(DiagnosticsProperty(
          'historicalCountIsEstimate', historicalCountIsEstimate))
      ..add(DiagnosticsProperty('following', following))
      ..add(DiagnosticsProperty('digitsAfterDecimal', digitsAfterDecimal));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RunHistoryModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunHistoryModel(totalRunsThisKennel: $totalRunsThisKennel, totalHaringThisKennel: $totalHaringThisKennel, hcRunsThisKennel: $hcRunsThisKennel, hcHaringThisKennel: $hcHaringThisKennel, kennelName: $kennelName, kennelShortName: $kennelShortName, kennelId: $kennelId, kennelLogo: $kennelLogo, currencySymbol: $currencySymbol, kennelCredit: $kennelCredit, historicalHaringCount: $historicalHaringCount, historicalTotalRunCount: $historicalTotalRunCount, historicalCountIsEstimate: $historicalCountIsEstimate, following: $following, digitsAfterDecimal: $digitsAfterDecimal)';
  }
}

/// @nodoc
abstract mixin class _$RunHistoryModelCopyWith<$Res>
    implements $RunHistoryModelCopyWith<$Res> {
  factory _$RunHistoryModelCopyWith(
          _RunHistoryModel value, $Res Function(_RunHistoryModel) _then) =
      __$RunHistoryModelCopyWithImpl;
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
class __$RunHistoryModelCopyWithImpl<$Res>
    implements _$RunHistoryModelCopyWith<$Res> {
  __$RunHistoryModelCopyWithImpl(this._self, this._then);

  final _RunHistoryModel _self;
  final $Res Function(_RunHistoryModel) _then;

  /// Create a copy of RunHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_RunHistoryModel(
      totalRunsThisKennel: null == totalRunsThisKennel
          ? _self.totalRunsThisKennel
          : totalRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      totalHaringThisKennel: null == totalHaringThisKennel
          ? _self.totalHaringThisKennel
          : totalHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcRunsThisKennel: null == hcRunsThisKennel
          ? _self.hcRunsThisKennel
          : hcRunsThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      hcHaringThisKennel: null == hcHaringThisKennel
          ? _self.hcHaringThisKennel
          : hcHaringThisKennel // ignore: cast_nullable_to_non_nullable
              as int,
      kennelName: null == kennelName
          ? _self.kennelName
          : kennelName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelShortName: null == kennelShortName
          ? _self.kennelShortName
          : kennelShortName // ignore: cast_nullable_to_non_nullable
              as String,
      kennelId: null == kennelId
          ? _self.kennelId
          : kennelId // ignore: cast_nullable_to_non_nullable
              as String,
      kennelLogo: null == kennelLogo
          ? _self.kennelLogo
          : kennelLogo // ignore: cast_nullable_to_non_nullable
              as String,
      currencySymbol: null == currencySymbol
          ? _self.currencySymbol
          : currencySymbol // ignore: cast_nullable_to_non_nullable
              as String,
      kennelCredit: null == kennelCredit
          ? _self.kennelCredit
          : kennelCredit // ignore: cast_nullable_to_non_nullable
              as double,
      historicalHaringCount: null == historicalHaringCount
          ? _self.historicalHaringCount
          : historicalHaringCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalTotalRunCount: null == historicalTotalRunCount
          ? _self.historicalTotalRunCount
          : historicalTotalRunCount // ignore: cast_nullable_to_non_nullable
              as int,
      historicalCountIsEstimate: null == historicalCountIsEstimate
          ? _self.historicalCountIsEstimate
          : historicalCountIsEstimate // ignore: cast_nullable_to_non_nullable
              as int,
      following: null == following
          ? _self.following
          : following // ignore: cast_nullable_to_non_nullable
              as int,
      digitsAfterDecimal: null == digitsAfterDecimal
          ? _self.digitsAfterDecimal
          : digitsAfterDecimal // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
