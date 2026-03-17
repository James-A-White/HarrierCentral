// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'email_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmailModel {
  String get subject;
  String get body;
  String get sendTo;
  int get intTest;
  String? get sendFrom;
  String? get cc;
  String? get bcc;
  String? get replyTo;
  String? get attachmentFileName;
  String? get attachmentFileContentBase64;

  /// Create a copy of EmailModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EmailModelCopyWith<EmailModel> get copyWith =>
      _$EmailModelCopyWithImpl<EmailModel>(this as EmailModel, _$identity);

  /// Serializes this EmailModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EmailModel &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.sendTo, sendTo) || other.sendTo == sendTo) &&
            (identical(other.intTest, intTest) || other.intTest == intTest) &&
            (identical(other.sendFrom, sendFrom) ||
                other.sendFrom == sendFrom) &&
            (identical(other.cc, cc) || other.cc == cc) &&
            (identical(other.bcc, bcc) || other.bcc == bcc) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo) &&
            (identical(other.attachmentFileName, attachmentFileName) ||
                other.attachmentFileName == attachmentFileName) &&
            (identical(other.attachmentFileContentBase64,
                    attachmentFileContentBase64) ||
                other.attachmentFileContentBase64 ==
                    attachmentFileContentBase64));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      subject,
      body,
      sendTo,
      intTest,
      sendFrom,
      cc,
      bcc,
      replyTo,
      attachmentFileName,
      attachmentFileContentBase64);

  @override
  String toString() {
    return 'EmailModel(subject: $subject, body: $body, sendTo: $sendTo, intTest: $intTest, sendFrom: $sendFrom, cc: $cc, bcc: $bcc, replyTo: $replyTo, attachmentFileName: $attachmentFileName, attachmentFileContentBase64: $attachmentFileContentBase64)';
  }
}

/// @nodoc
abstract mixin class $EmailModelCopyWith<$Res> {
  factory $EmailModelCopyWith(
          EmailModel value, $Res Function(EmailModel) _then) =
      _$EmailModelCopyWithImpl;
  @useResult
  $Res call(
      {String subject,
      String body,
      String sendTo,
      int intTest,
      String? sendFrom,
      String? cc,
      String? bcc,
      String? replyTo,
      String? attachmentFileName,
      String? attachmentFileContentBase64});
}

/// @nodoc
class _$EmailModelCopyWithImpl<$Res> implements $EmailModelCopyWith<$Res> {
  _$EmailModelCopyWithImpl(this._self, this._then);

  final EmailModel _self;
  final $Res Function(EmailModel) _then;

  /// Create a copy of EmailModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? body = null,
    Object? sendTo = null,
    Object? intTest = null,
    Object? sendFrom = freezed,
    Object? cc = freezed,
    Object? bcc = freezed,
    Object? replyTo = freezed,
    Object? attachmentFileName = freezed,
    Object? attachmentFileContentBase64 = freezed,
  }) {
    return _then(_self.copyWith(
      subject: null == subject
          ? _self.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _self.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      sendTo: null == sendTo
          ? _self.sendTo
          : sendTo // ignore: cast_nullable_to_non_nullable
              as String,
      intTest: null == intTest
          ? _self.intTest
          : intTest // ignore: cast_nullable_to_non_nullable
              as int,
      sendFrom: freezed == sendFrom
          ? _self.sendFrom
          : sendFrom // ignore: cast_nullable_to_non_nullable
              as String?,
      cc: freezed == cc
          ? _self.cc
          : cc // ignore: cast_nullable_to_non_nullable
              as String?,
      bcc: freezed == bcc
          ? _self.bcc
          : bcc // ignore: cast_nullable_to_non_nullable
              as String?,
      replyTo: freezed == replyTo
          ? _self.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as String?,
      attachmentFileName: freezed == attachmentFileName
          ? _self.attachmentFileName
          : attachmentFileName // ignore: cast_nullable_to_non_nullable
              as String?,
      attachmentFileContentBase64: freezed == attachmentFileContentBase64
          ? _self.attachmentFileContentBase64
          : attachmentFileContentBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [EmailModel].
extension EmailModelPatterns on EmailModel {
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
    TResult Function(_EmailModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EmailModel() when $default != null:
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
    TResult Function(_EmailModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EmailModel():
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
    TResult? Function(_EmailModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EmailModel() when $default != null:
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
            String subject,
            String body,
            String sendTo,
            int intTest,
            String? sendFrom,
            String? cc,
            String? bcc,
            String? replyTo,
            String? attachmentFileName,
            String? attachmentFileContentBase64)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EmailModel() when $default != null:
        return $default(
            _that.subject,
            _that.body,
            _that.sendTo,
            _that.intTest,
            _that.sendFrom,
            _that.cc,
            _that.bcc,
            _that.replyTo,
            _that.attachmentFileName,
            _that.attachmentFileContentBase64);
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
            String subject,
            String body,
            String sendTo,
            int intTest,
            String? sendFrom,
            String? cc,
            String? bcc,
            String? replyTo,
            String? attachmentFileName,
            String? attachmentFileContentBase64)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EmailModel():
        return $default(
            _that.subject,
            _that.body,
            _that.sendTo,
            _that.intTest,
            _that.sendFrom,
            _that.cc,
            _that.bcc,
            _that.replyTo,
            _that.attachmentFileName,
            _that.attachmentFileContentBase64);
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
            String subject,
            String body,
            String sendTo,
            int intTest,
            String? sendFrom,
            String? cc,
            String? bcc,
            String? replyTo,
            String? attachmentFileName,
            String? attachmentFileContentBase64)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EmailModel() when $default != null:
        return $default(
            _that.subject,
            _that.body,
            _that.sendTo,
            _that.intTest,
            _that.sendFrom,
            _that.cc,
            _that.bcc,
            _that.replyTo,
            _that.attachmentFileName,
            _that.attachmentFileContentBase64);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _EmailModel implements EmailModel {
  const _EmailModel(
      {required this.subject,
      required this.body,
      required this.sendTo,
      required this.intTest,
      this.sendFrom,
      this.cc,
      this.bcc,
      this.replyTo,
      this.attachmentFileName,
      this.attachmentFileContentBase64});
  factory _EmailModel.fromJson(Map<String, dynamic> json) =>
      _$EmailModelFromJson(json);

  @override
  final String subject;
  @override
  final String body;
  @override
  final String sendTo;
  @override
  final int intTest;
  @override
  final String? sendFrom;
  @override
  final String? cc;
  @override
  final String? bcc;
  @override
  final String? replyTo;
  @override
  final String? attachmentFileName;
  @override
  final String? attachmentFileContentBase64;

  /// Create a copy of EmailModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EmailModelCopyWith<_EmailModel> get copyWith =>
      __$EmailModelCopyWithImpl<_EmailModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EmailModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EmailModel &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.sendTo, sendTo) || other.sendTo == sendTo) &&
            (identical(other.intTest, intTest) || other.intTest == intTest) &&
            (identical(other.sendFrom, sendFrom) ||
                other.sendFrom == sendFrom) &&
            (identical(other.cc, cc) || other.cc == cc) &&
            (identical(other.bcc, bcc) || other.bcc == bcc) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo) &&
            (identical(other.attachmentFileName, attachmentFileName) ||
                other.attachmentFileName == attachmentFileName) &&
            (identical(other.attachmentFileContentBase64,
                    attachmentFileContentBase64) ||
                other.attachmentFileContentBase64 ==
                    attachmentFileContentBase64));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      subject,
      body,
      sendTo,
      intTest,
      sendFrom,
      cc,
      bcc,
      replyTo,
      attachmentFileName,
      attachmentFileContentBase64);

  @override
  String toString() {
    return 'EmailModel(subject: $subject, body: $body, sendTo: $sendTo, intTest: $intTest, sendFrom: $sendFrom, cc: $cc, bcc: $bcc, replyTo: $replyTo, attachmentFileName: $attachmentFileName, attachmentFileContentBase64: $attachmentFileContentBase64)';
  }
}

/// @nodoc
abstract mixin class _$EmailModelCopyWith<$Res>
    implements $EmailModelCopyWith<$Res> {
  factory _$EmailModelCopyWith(
          _EmailModel value, $Res Function(_EmailModel) _then) =
      __$EmailModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String subject,
      String body,
      String sendTo,
      int intTest,
      String? sendFrom,
      String? cc,
      String? bcc,
      String? replyTo,
      String? attachmentFileName,
      String? attachmentFileContentBase64});
}

/// @nodoc
class __$EmailModelCopyWithImpl<$Res> implements _$EmailModelCopyWith<$Res> {
  __$EmailModelCopyWithImpl(this._self, this._then);

  final _EmailModel _self;
  final $Res Function(_EmailModel) _then;

  /// Create a copy of EmailModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? subject = null,
    Object? body = null,
    Object? sendTo = null,
    Object? intTest = null,
    Object? sendFrom = freezed,
    Object? cc = freezed,
    Object? bcc = freezed,
    Object? replyTo = freezed,
    Object? attachmentFileName = freezed,
    Object? attachmentFileContentBase64 = freezed,
  }) {
    return _then(_EmailModel(
      subject: null == subject
          ? _self.subject
          : subject // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _self.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      sendTo: null == sendTo
          ? _self.sendTo
          : sendTo // ignore: cast_nullable_to_non_nullable
              as String,
      intTest: null == intTest
          ? _self.intTest
          : intTest // ignore: cast_nullable_to_non_nullable
              as int,
      sendFrom: freezed == sendFrom
          ? _self.sendFrom
          : sendFrom // ignore: cast_nullable_to_non_nullable
              as String?,
      cc: freezed == cc
          ? _self.cc
          : cc // ignore: cast_nullable_to_non_nullable
              as String?,
      bcc: freezed == bcc
          ? _self.bcc
          : bcc // ignore: cast_nullable_to_non_nullable
              as String?,
      replyTo: freezed == replyTo
          ? _self.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as String?,
      attachmentFileName: freezed == attachmentFileName
          ? _self.attachmentFileName
          : attachmentFileName // ignore: cast_nullable_to_non_nullable
              as String?,
      attachmentFileContentBase64: freezed == attachmentFileContentBase64
          ? _self.attachmentFileContentBase64
          : attachmentFileContentBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
