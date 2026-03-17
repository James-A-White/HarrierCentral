// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_data_integration_monitor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UdIntegrationMonitorModel implements DiagnosticableTreeMixin {
  int get integrationId;
  int get recordsRead;
  int get recordsWritten; // required String recordSuccessInfo,
  String get recordsFailedInfo;
  int get errorCount;
  String get errorInfo;
  int get kennelsSucceeded;
  String get kennelsSucceededInfo;
  int get kennelsFailed;
  String get kennelsFailedInfo;
  String get integrationAbbreviation;
  int get integrationEnabled;
  int get interval; // required DateTime strtedAt,
  DateTime get endedAt;
  int get minutesAgo;
  int get futureRunCount;

  /// Create a copy of UdIntegrationMonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UdIntegrationMonitorModelCopyWith<UdIntegrationMonitorModel> get copyWith =>
      _$UdIntegrationMonitorModelCopyWithImpl<UdIntegrationMonitorModel>(
          this as UdIntegrationMonitorModel, _$identity);

  /// Serializes this UdIntegrationMonitorModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdIntegrationMonitorModel'))
      ..add(DiagnosticsProperty('integrationId', integrationId))
      ..add(DiagnosticsProperty('recordsRead', recordsRead))
      ..add(DiagnosticsProperty('recordsWritten', recordsWritten))
      ..add(DiagnosticsProperty('recordsFailedInfo', recordsFailedInfo))
      ..add(DiagnosticsProperty('errorCount', errorCount))
      ..add(DiagnosticsProperty('errorInfo', errorInfo))
      ..add(DiagnosticsProperty('kennelsSucceeded', kennelsSucceeded))
      ..add(DiagnosticsProperty('kennelsSucceededInfo', kennelsSucceededInfo))
      ..add(DiagnosticsProperty('kennelsFailed', kennelsFailed))
      ..add(DiagnosticsProperty('kennelsFailedInfo', kennelsFailedInfo))
      ..add(DiagnosticsProperty(
          'integrationAbbreviation', integrationAbbreviation))
      ..add(DiagnosticsProperty('integrationEnabled', integrationEnabled))
      ..add(DiagnosticsProperty('interval', interval))
      ..add(DiagnosticsProperty('endedAt', endedAt))
      ..add(DiagnosticsProperty('minutesAgo', minutesAgo))
      ..add(DiagnosticsProperty('futureRunCount', futureRunCount));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UdIntegrationMonitorModel &&
            (identical(other.integrationId, integrationId) ||
                other.integrationId == integrationId) &&
            (identical(other.recordsRead, recordsRead) ||
                other.recordsRead == recordsRead) &&
            (identical(other.recordsWritten, recordsWritten) ||
                other.recordsWritten == recordsWritten) &&
            (identical(other.recordsFailedInfo, recordsFailedInfo) ||
                other.recordsFailedInfo == recordsFailedInfo) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            (identical(other.errorInfo, errorInfo) ||
                other.errorInfo == errorInfo) &&
            (identical(other.kennelsSucceeded, kennelsSucceeded) ||
                other.kennelsSucceeded == kennelsSucceeded) &&
            (identical(other.kennelsSucceededInfo, kennelsSucceededInfo) ||
                other.kennelsSucceededInfo == kennelsSucceededInfo) &&
            (identical(other.kennelsFailed, kennelsFailed) ||
                other.kennelsFailed == kennelsFailed) &&
            (identical(other.kennelsFailedInfo, kennelsFailedInfo) ||
                other.kennelsFailedInfo == kennelsFailedInfo) &&
            (identical(
                    other.integrationAbbreviation, integrationAbbreviation) ||
                other.integrationAbbreviation == integrationAbbreviation) &&
            (identical(other.integrationEnabled, integrationEnabled) ||
                other.integrationEnabled == integrationEnabled) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.minutesAgo, minutesAgo) ||
                other.minutesAgo == minutesAgo) &&
            (identical(other.futureRunCount, futureRunCount) ||
                other.futureRunCount == futureRunCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      integrationId,
      recordsRead,
      recordsWritten,
      recordsFailedInfo,
      errorCount,
      errorInfo,
      kennelsSucceeded,
      kennelsSucceededInfo,
      kennelsFailed,
      kennelsFailedInfo,
      integrationAbbreviation,
      integrationEnabled,
      interval,
      endedAt,
      minutesAgo,
      futureRunCount);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdIntegrationMonitorModel(integrationId: $integrationId, recordsRead: $recordsRead, recordsWritten: $recordsWritten, recordsFailedInfo: $recordsFailedInfo, errorCount: $errorCount, errorInfo: $errorInfo, kennelsSucceeded: $kennelsSucceeded, kennelsSucceededInfo: $kennelsSucceededInfo, kennelsFailed: $kennelsFailed, kennelsFailedInfo: $kennelsFailedInfo, integrationAbbreviation: $integrationAbbreviation, integrationEnabled: $integrationEnabled, interval: $interval, endedAt: $endedAt, minutesAgo: $minutesAgo, futureRunCount: $futureRunCount)';
  }
}

/// @nodoc
abstract mixin class $UdIntegrationMonitorModelCopyWith<$Res> {
  factory $UdIntegrationMonitorModelCopyWith(UdIntegrationMonitorModel value,
          $Res Function(UdIntegrationMonitorModel) _then) =
      _$UdIntegrationMonitorModelCopyWithImpl;
  @useResult
  $Res call(
      {int integrationId,
      int recordsRead,
      int recordsWritten,
      String recordsFailedInfo,
      int errorCount,
      String errorInfo,
      int kennelsSucceeded,
      String kennelsSucceededInfo,
      int kennelsFailed,
      String kennelsFailedInfo,
      String integrationAbbreviation,
      int integrationEnabled,
      int interval,
      DateTime endedAt,
      int minutesAgo,
      int futureRunCount});
}

/// @nodoc
class _$UdIntegrationMonitorModelCopyWithImpl<$Res>
    implements $UdIntegrationMonitorModelCopyWith<$Res> {
  _$UdIntegrationMonitorModelCopyWithImpl(this._self, this._then);

  final UdIntegrationMonitorModel _self;
  final $Res Function(UdIntegrationMonitorModel) _then;

  /// Create a copy of UdIntegrationMonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? integrationId = null,
    Object? recordsRead = null,
    Object? recordsWritten = null,
    Object? recordsFailedInfo = null,
    Object? errorCount = null,
    Object? errorInfo = null,
    Object? kennelsSucceeded = null,
    Object? kennelsSucceededInfo = null,
    Object? kennelsFailed = null,
    Object? kennelsFailedInfo = null,
    Object? integrationAbbreviation = null,
    Object? integrationEnabled = null,
    Object? interval = null,
    Object? endedAt = null,
    Object? minutesAgo = null,
    Object? futureRunCount = null,
  }) {
    return _then(_self.copyWith(
      integrationId: null == integrationId
          ? _self.integrationId
          : integrationId // ignore: cast_nullable_to_non_nullable
              as int,
      recordsRead: null == recordsRead
          ? _self.recordsRead
          : recordsRead // ignore: cast_nullable_to_non_nullable
              as int,
      recordsWritten: null == recordsWritten
          ? _self.recordsWritten
          : recordsWritten // ignore: cast_nullable_to_non_nullable
              as int,
      recordsFailedInfo: null == recordsFailedInfo
          ? _self.recordsFailedInfo
          : recordsFailedInfo // ignore: cast_nullable_to_non_nullable
              as String,
      errorCount: null == errorCount
          ? _self.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorInfo: null == errorInfo
          ? _self.errorInfo
          : errorInfo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelsSucceeded: null == kennelsSucceeded
          ? _self.kennelsSucceeded
          : kennelsSucceeded // ignore: cast_nullable_to_non_nullable
              as int,
      kennelsSucceededInfo: null == kennelsSucceededInfo
          ? _self.kennelsSucceededInfo
          : kennelsSucceededInfo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelsFailed: null == kennelsFailed
          ? _self.kennelsFailed
          : kennelsFailed // ignore: cast_nullable_to_non_nullable
              as int,
      kennelsFailedInfo: null == kennelsFailedInfo
          ? _self.kennelsFailedInfo
          : kennelsFailedInfo // ignore: cast_nullable_to_non_nullable
              as String,
      integrationAbbreviation: null == integrationAbbreviation
          ? _self.integrationAbbreviation
          : integrationAbbreviation // ignore: cast_nullable_to_non_nullable
              as String,
      integrationEnabled: null == integrationEnabled
          ? _self.integrationEnabled
          : integrationEnabled // ignore: cast_nullable_to_non_nullable
              as int,
      interval: null == interval
          ? _self.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int,
      endedAt: null == endedAt
          ? _self.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      minutesAgo: null == minutesAgo
          ? _self.minutesAgo
          : minutesAgo // ignore: cast_nullable_to_non_nullable
              as int,
      futureRunCount: null == futureRunCount
          ? _self.futureRunCount
          : futureRunCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [UdIntegrationMonitorModel].
extension UdIntegrationMonitorModelPatterns on UdIntegrationMonitorModel {
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
    TResult Function(_UdIntegrationMonitorModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdIntegrationMonitorModel() when $default != null:
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
    TResult Function(_UdIntegrationMonitorModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdIntegrationMonitorModel():
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
    TResult? Function(_UdIntegrationMonitorModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdIntegrationMonitorModel() when $default != null:
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
            int integrationId,
            int recordsRead,
            int recordsWritten,
            String recordsFailedInfo,
            int errorCount,
            String errorInfo,
            int kennelsSucceeded,
            String kennelsSucceededInfo,
            int kennelsFailed,
            String kennelsFailedInfo,
            String integrationAbbreviation,
            int integrationEnabled,
            int interval,
            DateTime endedAt,
            int minutesAgo,
            int futureRunCount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UdIntegrationMonitorModel() when $default != null:
        return $default(
            _that.integrationId,
            _that.recordsRead,
            _that.recordsWritten,
            _that.recordsFailedInfo,
            _that.errorCount,
            _that.errorInfo,
            _that.kennelsSucceeded,
            _that.kennelsSucceededInfo,
            _that.kennelsFailed,
            _that.kennelsFailedInfo,
            _that.integrationAbbreviation,
            _that.integrationEnabled,
            _that.interval,
            _that.endedAt,
            _that.minutesAgo,
            _that.futureRunCount);
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
            int integrationId,
            int recordsRead,
            int recordsWritten,
            String recordsFailedInfo,
            int errorCount,
            String errorInfo,
            int kennelsSucceeded,
            String kennelsSucceededInfo,
            int kennelsFailed,
            String kennelsFailedInfo,
            String integrationAbbreviation,
            int integrationEnabled,
            int interval,
            DateTime endedAt,
            int minutesAgo,
            int futureRunCount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdIntegrationMonitorModel():
        return $default(
            _that.integrationId,
            _that.recordsRead,
            _that.recordsWritten,
            _that.recordsFailedInfo,
            _that.errorCount,
            _that.errorInfo,
            _that.kennelsSucceeded,
            _that.kennelsSucceededInfo,
            _that.kennelsFailed,
            _that.kennelsFailedInfo,
            _that.integrationAbbreviation,
            _that.integrationEnabled,
            _that.interval,
            _that.endedAt,
            _that.minutesAgo,
            _that.futureRunCount);
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
            int integrationId,
            int recordsRead,
            int recordsWritten,
            String recordsFailedInfo,
            int errorCount,
            String errorInfo,
            int kennelsSucceeded,
            String kennelsSucceededInfo,
            int kennelsFailed,
            String kennelsFailedInfo,
            String integrationAbbreviation,
            int integrationEnabled,
            int interval,
            DateTime endedAt,
            int minutesAgo,
            int futureRunCount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UdIntegrationMonitorModel() when $default != null:
        return $default(
            _that.integrationId,
            _that.recordsRead,
            _that.recordsWritten,
            _that.recordsFailedInfo,
            _that.errorCount,
            _that.errorInfo,
            _that.kennelsSucceeded,
            _that.kennelsSucceededInfo,
            _that.kennelsFailed,
            _that.kennelsFailedInfo,
            _that.integrationAbbreviation,
            _that.integrationEnabled,
            _that.interval,
            _that.endedAt,
            _that.minutesAgo,
            _that.futureRunCount);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UdIntegrationMonitorModel
    with DiagnosticableTreeMixin
    implements UdIntegrationMonitorModel {
  _UdIntegrationMonitorModel(
      {required this.integrationId,
      required this.recordsRead,
      required this.recordsWritten,
      required this.recordsFailedInfo,
      required this.errorCount,
      required this.errorInfo,
      required this.kennelsSucceeded,
      required this.kennelsSucceededInfo,
      required this.kennelsFailed,
      required this.kennelsFailedInfo,
      required this.integrationAbbreviation,
      required this.integrationEnabled,
      required this.interval,
      required this.endedAt,
      required this.minutesAgo,
      required this.futureRunCount});
  factory _UdIntegrationMonitorModel.fromJson(Map<String, dynamic> json) =>
      _$UdIntegrationMonitorModelFromJson(json);

  @override
  final int integrationId;
  @override
  final int recordsRead;
  @override
  final int recordsWritten;
// required String recordSuccessInfo,
  @override
  final String recordsFailedInfo;
  @override
  final int errorCount;
  @override
  final String errorInfo;
  @override
  final int kennelsSucceeded;
  @override
  final String kennelsSucceededInfo;
  @override
  final int kennelsFailed;
  @override
  final String kennelsFailedInfo;
  @override
  final String integrationAbbreviation;
  @override
  final int integrationEnabled;
  @override
  final int interval;
// required DateTime strtedAt,
  @override
  final DateTime endedAt;
  @override
  final int minutesAgo;
  @override
  final int futureRunCount;

  /// Create a copy of UdIntegrationMonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UdIntegrationMonitorModelCopyWith<_UdIntegrationMonitorModel>
      get copyWith =>
          __$UdIntegrationMonitorModelCopyWithImpl<_UdIntegrationMonitorModel>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UdIntegrationMonitorModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UdIntegrationMonitorModel'))
      ..add(DiagnosticsProperty('integrationId', integrationId))
      ..add(DiagnosticsProperty('recordsRead', recordsRead))
      ..add(DiagnosticsProperty('recordsWritten', recordsWritten))
      ..add(DiagnosticsProperty('recordsFailedInfo', recordsFailedInfo))
      ..add(DiagnosticsProperty('errorCount', errorCount))
      ..add(DiagnosticsProperty('errorInfo', errorInfo))
      ..add(DiagnosticsProperty('kennelsSucceeded', kennelsSucceeded))
      ..add(DiagnosticsProperty('kennelsSucceededInfo', kennelsSucceededInfo))
      ..add(DiagnosticsProperty('kennelsFailed', kennelsFailed))
      ..add(DiagnosticsProperty('kennelsFailedInfo', kennelsFailedInfo))
      ..add(DiagnosticsProperty(
          'integrationAbbreviation', integrationAbbreviation))
      ..add(DiagnosticsProperty('integrationEnabled', integrationEnabled))
      ..add(DiagnosticsProperty('interval', interval))
      ..add(DiagnosticsProperty('endedAt', endedAt))
      ..add(DiagnosticsProperty('minutesAgo', minutesAgo))
      ..add(DiagnosticsProperty('futureRunCount', futureRunCount));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UdIntegrationMonitorModel &&
            (identical(other.integrationId, integrationId) ||
                other.integrationId == integrationId) &&
            (identical(other.recordsRead, recordsRead) ||
                other.recordsRead == recordsRead) &&
            (identical(other.recordsWritten, recordsWritten) ||
                other.recordsWritten == recordsWritten) &&
            (identical(other.recordsFailedInfo, recordsFailedInfo) ||
                other.recordsFailedInfo == recordsFailedInfo) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            (identical(other.errorInfo, errorInfo) ||
                other.errorInfo == errorInfo) &&
            (identical(other.kennelsSucceeded, kennelsSucceeded) ||
                other.kennelsSucceeded == kennelsSucceeded) &&
            (identical(other.kennelsSucceededInfo, kennelsSucceededInfo) ||
                other.kennelsSucceededInfo == kennelsSucceededInfo) &&
            (identical(other.kennelsFailed, kennelsFailed) ||
                other.kennelsFailed == kennelsFailed) &&
            (identical(other.kennelsFailedInfo, kennelsFailedInfo) ||
                other.kennelsFailedInfo == kennelsFailedInfo) &&
            (identical(
                    other.integrationAbbreviation, integrationAbbreviation) ||
                other.integrationAbbreviation == integrationAbbreviation) &&
            (identical(other.integrationEnabled, integrationEnabled) ||
                other.integrationEnabled == integrationEnabled) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.minutesAgo, minutesAgo) ||
                other.minutesAgo == minutesAgo) &&
            (identical(other.futureRunCount, futureRunCount) ||
                other.futureRunCount == futureRunCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      integrationId,
      recordsRead,
      recordsWritten,
      recordsFailedInfo,
      errorCount,
      errorInfo,
      kennelsSucceeded,
      kennelsSucceededInfo,
      kennelsFailed,
      kennelsFailedInfo,
      integrationAbbreviation,
      integrationEnabled,
      interval,
      endedAt,
      minutesAgo,
      futureRunCount);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UdIntegrationMonitorModel(integrationId: $integrationId, recordsRead: $recordsRead, recordsWritten: $recordsWritten, recordsFailedInfo: $recordsFailedInfo, errorCount: $errorCount, errorInfo: $errorInfo, kennelsSucceeded: $kennelsSucceeded, kennelsSucceededInfo: $kennelsSucceededInfo, kennelsFailed: $kennelsFailed, kennelsFailedInfo: $kennelsFailedInfo, integrationAbbreviation: $integrationAbbreviation, integrationEnabled: $integrationEnabled, interval: $interval, endedAt: $endedAt, minutesAgo: $minutesAgo, futureRunCount: $futureRunCount)';
  }
}

/// @nodoc
abstract mixin class _$UdIntegrationMonitorModelCopyWith<$Res>
    implements $UdIntegrationMonitorModelCopyWith<$Res> {
  factory _$UdIntegrationMonitorModelCopyWith(_UdIntegrationMonitorModel value,
          $Res Function(_UdIntegrationMonitorModel) _then) =
      __$UdIntegrationMonitorModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int integrationId,
      int recordsRead,
      int recordsWritten,
      String recordsFailedInfo,
      int errorCount,
      String errorInfo,
      int kennelsSucceeded,
      String kennelsSucceededInfo,
      int kennelsFailed,
      String kennelsFailedInfo,
      String integrationAbbreviation,
      int integrationEnabled,
      int interval,
      DateTime endedAt,
      int minutesAgo,
      int futureRunCount});
}

/// @nodoc
class __$UdIntegrationMonitorModelCopyWithImpl<$Res>
    implements _$UdIntegrationMonitorModelCopyWith<$Res> {
  __$UdIntegrationMonitorModelCopyWithImpl(this._self, this._then);

  final _UdIntegrationMonitorModel _self;
  final $Res Function(_UdIntegrationMonitorModel) _then;

  /// Create a copy of UdIntegrationMonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? integrationId = null,
    Object? recordsRead = null,
    Object? recordsWritten = null,
    Object? recordsFailedInfo = null,
    Object? errorCount = null,
    Object? errorInfo = null,
    Object? kennelsSucceeded = null,
    Object? kennelsSucceededInfo = null,
    Object? kennelsFailed = null,
    Object? kennelsFailedInfo = null,
    Object? integrationAbbreviation = null,
    Object? integrationEnabled = null,
    Object? interval = null,
    Object? endedAt = null,
    Object? minutesAgo = null,
    Object? futureRunCount = null,
  }) {
    return _then(_UdIntegrationMonitorModel(
      integrationId: null == integrationId
          ? _self.integrationId
          : integrationId // ignore: cast_nullable_to_non_nullable
              as int,
      recordsRead: null == recordsRead
          ? _self.recordsRead
          : recordsRead // ignore: cast_nullable_to_non_nullable
              as int,
      recordsWritten: null == recordsWritten
          ? _self.recordsWritten
          : recordsWritten // ignore: cast_nullable_to_non_nullable
              as int,
      recordsFailedInfo: null == recordsFailedInfo
          ? _self.recordsFailedInfo
          : recordsFailedInfo // ignore: cast_nullable_to_non_nullable
              as String,
      errorCount: null == errorCount
          ? _self.errorCount
          : errorCount // ignore: cast_nullable_to_non_nullable
              as int,
      errorInfo: null == errorInfo
          ? _self.errorInfo
          : errorInfo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelsSucceeded: null == kennelsSucceeded
          ? _self.kennelsSucceeded
          : kennelsSucceeded // ignore: cast_nullable_to_non_nullable
              as int,
      kennelsSucceededInfo: null == kennelsSucceededInfo
          ? _self.kennelsSucceededInfo
          : kennelsSucceededInfo // ignore: cast_nullable_to_non_nullable
              as String,
      kennelsFailed: null == kennelsFailed
          ? _self.kennelsFailed
          : kennelsFailed // ignore: cast_nullable_to_non_nullable
              as int,
      kennelsFailedInfo: null == kennelsFailedInfo
          ? _self.kennelsFailedInfo
          : kennelsFailedInfo // ignore: cast_nullable_to_non_nullable
              as String,
      integrationAbbreviation: null == integrationAbbreviation
          ? _self.integrationAbbreviation
          : integrationAbbreviation // ignore: cast_nullable_to_non_nullable
              as String,
      integrationEnabled: null == integrationEnabled
          ? _self.integrationEnabled
          : integrationEnabled // ignore: cast_nullable_to_non_nullable
              as int,
      interval: null == interval
          ? _self.interval
          : interval // ignore: cast_nullable_to_non_nullable
              as int,
      endedAt: null == endedAt
          ? _self.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      minutesAgo: null == minutesAgo
          ? _self.minutesAgo
          : minutesAgo // ignore: cast_nullable_to_non_nullable
              as int,
      futureRunCount: null == futureRunCount
          ? _self.futureRunCount
          : futureRunCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
