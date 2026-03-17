// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApplicationModel {
  @UuidConverter()
  UuidValue get applicationPublicId;
  int get challengeIndex;
  String get title;
  String get shortDescription;
  String get applicationImageAsset;
  String get tagsValid;
  bool get applicationIsSubmitable;
  PdfDocumentModel? get quadChart;
  PdfDocumentModel? get proposal; //required List<PdfDocumentModel> documents,
  String? get applicationImageUrl;
  PdfDocumentModel? get applicationCvAdmin;
  PdfDocumentModel? get applicationCvCeo;
  PdfDocumentModel? get applicationCvComm;
  PdfDocumentModel? get applicationCvTech;
  String? get applicationPicAdmin;
  String? get applicationPicCeo;
  String? get applicationPicComm;
  String? get applicationPicTech;
  String? get nameAdmin;
  String? get nameCeo;
  String? get nameComm;
  String? get nameTech;
  String? get emailAdmin;
  String? get emailCeo;
  String? get emailComm;
  String? get emailTech;
  String? get formTechnicalDescriptionValid;
  String? get formCommercialroposalValid;
  String? get formProjectPlanValid;
  String? get formOverviewValid;
  String? get formTechnicalDescription;
  String? get formCommercialViability;
  String? get formOverivew;
  String? get formProjectPlan;
  String? get tagKeys;
  String? get tagLabels;
  String? get agreeTsAndCs;
  String? get agreeTsAndCsDetails;
  String? get isSubmitted;
  String? get isSubmittedDetails;
  String? get mfaUserId;
  DateTime? get mfaLastValidated;
  String? get optInToReceivePromotions;
  String? get optOutToShareWithNations;
  DateTime? get submissionDate;
  int get progressEmptyFields;
  int get progressValidFields;
  int get progressInvalidFields;

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ApplicationModelCopyWith<ApplicationModel> get copyWith =>
      _$ApplicationModelCopyWithImpl<ApplicationModel>(
          this as ApplicationModel, _$identity);

  /// Serializes this ApplicationModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ApplicationModel &&
            (identical(other.applicationPublicId, applicationPublicId) ||
                other.applicationPublicId == applicationPublicId) &&
            (identical(other.challengeIndex, challengeIndex) ||
                other.challengeIndex == challengeIndex) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.shortDescription, shortDescription) ||
                other.shortDescription == shortDescription) &&
            (identical(other.applicationImageAsset, applicationImageAsset) ||
                other.applicationImageAsset == applicationImageAsset) &&
            (identical(other.tagsValid, tagsValid) ||
                other.tagsValid == tagsValid) &&
            (identical(other.applicationIsSubmitable, applicationIsSubmitable) ||
                other.applicationIsSubmitable == applicationIsSubmitable) &&
            (identical(other.quadChart, quadChart) ||
                other.quadChart == quadChart) &&
            (identical(other.proposal, proposal) ||
                other.proposal == proposal) &&
            (identical(other.applicationImageUrl, applicationImageUrl) ||
                other.applicationImageUrl == applicationImageUrl) &&
            (identical(other.applicationCvAdmin, applicationCvAdmin) ||
                other.applicationCvAdmin == applicationCvAdmin) &&
            (identical(other.applicationCvCeo, applicationCvCeo) ||
                other.applicationCvCeo == applicationCvCeo) &&
            (identical(other.applicationCvComm, applicationCvComm) ||
                other.applicationCvComm == applicationCvComm) &&
            (identical(other.applicationCvTech, applicationCvTech) ||
                other.applicationCvTech == applicationCvTech) &&
            (identical(other.applicationPicAdmin, applicationPicAdmin) ||
                other.applicationPicAdmin == applicationPicAdmin) &&
            (identical(other.applicationPicCeo, applicationPicCeo) ||
                other.applicationPicCeo == applicationPicCeo) &&
            (identical(other.applicationPicComm, applicationPicComm) ||
                other.applicationPicComm == applicationPicComm) &&
            (identical(other.applicationPicTech, applicationPicTech) ||
                other.applicationPicTech == applicationPicTech) &&
            (identical(other.nameAdmin, nameAdmin) ||
                other.nameAdmin == nameAdmin) &&
            (identical(other.nameCeo, nameCeo) || other.nameCeo == nameCeo) &&
            (identical(other.nameComm, nameComm) ||
                other.nameComm == nameComm) &&
            (identical(other.nameTech, nameTech) ||
                other.nameTech == nameTech) &&
            (identical(other.emailAdmin, emailAdmin) ||
                other.emailAdmin == emailAdmin) &&
            (identical(other.emailCeo, emailCeo) ||
                other.emailCeo == emailCeo) &&
            (identical(other.emailComm, emailComm) ||
                other.emailComm == emailComm) &&
            (identical(other.emailTech, emailTech) ||
                other.emailTech == emailTech) &&
            (identical(other.formTechnicalDescriptionValid, formTechnicalDescriptionValid) ||
                other.formTechnicalDescriptionValid ==
                    formTechnicalDescriptionValid) &&
            (identical(other.formCommercialroposalValid, formCommercialroposalValid) ||
                other.formCommercialroposalValid ==
                    formCommercialroposalValid) &&
            (identical(other.formProjectPlanValid, formProjectPlanValid) ||
                other.formProjectPlanValid == formProjectPlanValid) &&
            (identical(other.formOverviewValid, formOverviewValid) ||
                other.formOverviewValid == formOverviewValid) &&
            (identical(other.formTechnicalDescription, formTechnicalDescription) ||
                other.formTechnicalDescription == formTechnicalDescription) &&
            (identical(other.formCommercialViability, formCommercialViability) ||
                other.formCommercialViability == formCommercialViability) &&
            (identical(other.formOverivew, formOverivew) ||
                other.formOverivew == formOverivew) &&
            (identical(other.formProjectPlan, formProjectPlan) || other.formProjectPlan == formProjectPlan) &&
            (identical(other.tagKeys, tagKeys) || other.tagKeys == tagKeys) &&
            (identical(other.tagLabels, tagLabels) || other.tagLabels == tagLabels) &&
            (identical(other.agreeTsAndCs, agreeTsAndCs) || other.agreeTsAndCs == agreeTsAndCs) &&
            (identical(other.agreeTsAndCsDetails, agreeTsAndCsDetails) || other.agreeTsAndCsDetails == agreeTsAndCsDetails) &&
            (identical(other.isSubmitted, isSubmitted) || other.isSubmitted == isSubmitted) &&
            (identical(other.isSubmittedDetails, isSubmittedDetails) || other.isSubmittedDetails == isSubmittedDetails) &&
            (identical(other.mfaUserId, mfaUserId) || other.mfaUserId == mfaUserId) &&
            (identical(other.mfaLastValidated, mfaLastValidated) || other.mfaLastValidated == mfaLastValidated) &&
            (identical(other.optInToReceivePromotions, optInToReceivePromotions) || other.optInToReceivePromotions == optInToReceivePromotions) &&
            (identical(other.optOutToShareWithNations, optOutToShareWithNations) || other.optOutToShareWithNations == optOutToShareWithNations) &&
            (identical(other.submissionDate, submissionDate) || other.submissionDate == submissionDate) &&
            (identical(other.progressEmptyFields, progressEmptyFields) || other.progressEmptyFields == progressEmptyFields) &&
            (identical(other.progressValidFields, progressValidFields) || other.progressValidFields == progressValidFields) &&
            (identical(other.progressInvalidFields, progressInvalidFields) || other.progressInvalidFields == progressInvalidFields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        applicationPublicId,
        challengeIndex,
        title,
        shortDescription,
        applicationImageAsset,
        tagsValid,
        applicationIsSubmitable,
        quadChart,
        proposal,
        applicationImageUrl,
        applicationCvAdmin,
        applicationCvCeo,
        applicationCvComm,
        applicationCvTech,
        applicationPicAdmin,
        applicationPicCeo,
        applicationPicComm,
        applicationPicTech,
        nameAdmin,
        nameCeo,
        nameComm,
        nameTech,
        emailAdmin,
        emailCeo,
        emailComm,
        emailTech,
        formTechnicalDescriptionValid,
        formCommercialroposalValid,
        formProjectPlanValid,
        formOverviewValid,
        formTechnicalDescription,
        formCommercialViability,
        formOverivew,
        formProjectPlan,
        tagKeys,
        tagLabels,
        agreeTsAndCs,
        agreeTsAndCsDetails,
        isSubmitted,
        isSubmittedDetails,
        mfaUserId,
        mfaLastValidated,
        optInToReceivePromotions,
        optOutToShareWithNations,
        submissionDate,
        progressEmptyFields,
        progressValidFields,
        progressInvalidFields
      ]);

  @override
  String toString() {
    return 'ApplicationModel(applicationPublicId: $applicationPublicId, challengeIndex: $challengeIndex, title: $title, shortDescription: $shortDescription, applicationImageAsset: $applicationImageAsset, tagsValid: $tagsValid, applicationIsSubmitable: $applicationIsSubmitable, quadChart: $quadChart, proposal: $proposal, applicationImageUrl: $applicationImageUrl, applicationCvAdmin: $applicationCvAdmin, applicationCvCeo: $applicationCvCeo, applicationCvComm: $applicationCvComm, applicationCvTech: $applicationCvTech, applicationPicAdmin: $applicationPicAdmin, applicationPicCeo: $applicationPicCeo, applicationPicComm: $applicationPicComm, applicationPicTech: $applicationPicTech, nameAdmin: $nameAdmin, nameCeo: $nameCeo, nameComm: $nameComm, nameTech: $nameTech, emailAdmin: $emailAdmin, emailCeo: $emailCeo, emailComm: $emailComm, emailTech: $emailTech, formTechnicalDescriptionValid: $formTechnicalDescriptionValid, formCommercialroposalValid: $formCommercialroposalValid, formProjectPlanValid: $formProjectPlanValid, formOverviewValid: $formOverviewValid, formTechnicalDescription: $formTechnicalDescription, formCommercialViability: $formCommercialViability, formOverivew: $formOverivew, formProjectPlan: $formProjectPlan, tagKeys: $tagKeys, tagLabels: $tagLabels, agreeTsAndCs: $agreeTsAndCs, agreeTsAndCsDetails: $agreeTsAndCsDetails, isSubmitted: $isSubmitted, isSubmittedDetails: $isSubmittedDetails, mfaUserId: $mfaUserId, mfaLastValidated: $mfaLastValidated, optInToReceivePromotions: $optInToReceivePromotions, optOutToShareWithNations: $optOutToShareWithNations, submissionDate: $submissionDate, progressEmptyFields: $progressEmptyFields, progressValidFields: $progressValidFields, progressInvalidFields: $progressInvalidFields)';
  }
}

/// @nodoc
abstract mixin class $ApplicationModelCopyWith<$Res> {
  factory $ApplicationModelCopyWith(
          ApplicationModel value, $Res Function(ApplicationModel) _then) =
      _$ApplicationModelCopyWithImpl;
  @useResult
  $Res call(
      {@UuidConverter() UuidValue applicationPublicId,
      int challengeIndex,
      String title,
      String shortDescription,
      String applicationImageAsset,
      String tagsValid,
      bool applicationIsSubmitable,
      PdfDocumentModel? quadChart,
      PdfDocumentModel? proposal,
      String? applicationImageUrl,
      PdfDocumentModel? applicationCvAdmin,
      PdfDocumentModel? applicationCvCeo,
      PdfDocumentModel? applicationCvComm,
      PdfDocumentModel? applicationCvTech,
      String? applicationPicAdmin,
      String? applicationPicCeo,
      String? applicationPicComm,
      String? applicationPicTech,
      String? nameAdmin,
      String? nameCeo,
      String? nameComm,
      String? nameTech,
      String? emailAdmin,
      String? emailCeo,
      String? emailComm,
      String? emailTech,
      String? formTechnicalDescriptionValid,
      String? formCommercialroposalValid,
      String? formProjectPlanValid,
      String? formOverviewValid,
      String? formTechnicalDescription,
      String? formCommercialViability,
      String? formOverivew,
      String? formProjectPlan,
      String? tagKeys,
      String? tagLabels,
      String? agreeTsAndCs,
      String? agreeTsAndCsDetails,
      String? isSubmitted,
      String? isSubmittedDetails,
      String? mfaUserId,
      DateTime? mfaLastValidated,
      String? optInToReceivePromotions,
      String? optOutToShareWithNations,
      DateTime? submissionDate,
      int progressEmptyFields,
      int progressValidFields,
      int progressInvalidFields});

  $PdfDocumentModelCopyWith<$Res>? get quadChart;
  $PdfDocumentModelCopyWith<$Res>? get proposal;
  $PdfDocumentModelCopyWith<$Res>? get applicationCvAdmin;
  $PdfDocumentModelCopyWith<$Res>? get applicationCvCeo;
  $PdfDocumentModelCopyWith<$Res>? get applicationCvComm;
  $PdfDocumentModelCopyWith<$Res>? get applicationCvTech;
}

/// @nodoc
class _$ApplicationModelCopyWithImpl<$Res>
    implements $ApplicationModelCopyWith<$Res> {
  _$ApplicationModelCopyWithImpl(this._self, this._then);

  final ApplicationModel _self;
  final $Res Function(ApplicationModel) _then;

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applicationPublicId = null,
    Object? challengeIndex = null,
    Object? title = null,
    Object? shortDescription = null,
    Object? applicationImageAsset = null,
    Object? tagsValid = null,
    Object? applicationIsSubmitable = null,
    Object? quadChart = freezed,
    Object? proposal = freezed,
    Object? applicationImageUrl = freezed,
    Object? applicationCvAdmin = freezed,
    Object? applicationCvCeo = freezed,
    Object? applicationCvComm = freezed,
    Object? applicationCvTech = freezed,
    Object? applicationPicAdmin = freezed,
    Object? applicationPicCeo = freezed,
    Object? applicationPicComm = freezed,
    Object? applicationPicTech = freezed,
    Object? nameAdmin = freezed,
    Object? nameCeo = freezed,
    Object? nameComm = freezed,
    Object? nameTech = freezed,
    Object? emailAdmin = freezed,
    Object? emailCeo = freezed,
    Object? emailComm = freezed,
    Object? emailTech = freezed,
    Object? formTechnicalDescriptionValid = freezed,
    Object? formCommercialroposalValid = freezed,
    Object? formProjectPlanValid = freezed,
    Object? formOverviewValid = freezed,
    Object? formTechnicalDescription = freezed,
    Object? formCommercialViability = freezed,
    Object? formOverivew = freezed,
    Object? formProjectPlan = freezed,
    Object? tagKeys = freezed,
    Object? tagLabels = freezed,
    Object? agreeTsAndCs = freezed,
    Object? agreeTsAndCsDetails = freezed,
    Object? isSubmitted = freezed,
    Object? isSubmittedDetails = freezed,
    Object? mfaUserId = freezed,
    Object? mfaLastValidated = freezed,
    Object? optInToReceivePromotions = freezed,
    Object? optOutToShareWithNations = freezed,
    Object? submissionDate = freezed,
    Object? progressEmptyFields = null,
    Object? progressValidFields = null,
    Object? progressInvalidFields = null,
  }) {
    return _then(_self.copyWith(
      applicationPublicId: null == applicationPublicId
          ? _self.applicationPublicId
          : applicationPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      challengeIndex: null == challengeIndex
          ? _self.challengeIndex
          : challengeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      shortDescription: null == shortDescription
          ? _self.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      applicationImageAsset: null == applicationImageAsset
          ? _self.applicationImageAsset
          : applicationImageAsset // ignore: cast_nullable_to_non_nullable
              as String,
      tagsValid: null == tagsValid
          ? _self.tagsValid
          : tagsValid // ignore: cast_nullable_to_non_nullable
              as String,
      applicationIsSubmitable: null == applicationIsSubmitable
          ? _self.applicationIsSubmitable
          : applicationIsSubmitable // ignore: cast_nullable_to_non_nullable
              as bool,
      quadChart: freezed == quadChart
          ? _self.quadChart
          : quadChart // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      proposal: freezed == proposal
          ? _self.proposal
          : proposal // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationImageUrl: freezed == applicationImageUrl
          ? _self.applicationImageUrl
          : applicationImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationCvAdmin: freezed == applicationCvAdmin
          ? _self.applicationCvAdmin
          : applicationCvAdmin // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationCvCeo: freezed == applicationCvCeo
          ? _self.applicationCvCeo
          : applicationCvCeo // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationCvComm: freezed == applicationCvComm
          ? _self.applicationCvComm
          : applicationCvComm // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationCvTech: freezed == applicationCvTech
          ? _self.applicationCvTech
          : applicationCvTech // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationPicAdmin: freezed == applicationPicAdmin
          ? _self.applicationPicAdmin
          : applicationPicAdmin // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationPicCeo: freezed == applicationPicCeo
          ? _self.applicationPicCeo
          : applicationPicCeo // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationPicComm: freezed == applicationPicComm
          ? _self.applicationPicComm
          : applicationPicComm // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationPicTech: freezed == applicationPicTech
          ? _self.applicationPicTech
          : applicationPicTech // ignore: cast_nullable_to_non_nullable
              as String?,
      nameAdmin: freezed == nameAdmin
          ? _self.nameAdmin
          : nameAdmin // ignore: cast_nullable_to_non_nullable
              as String?,
      nameCeo: freezed == nameCeo
          ? _self.nameCeo
          : nameCeo // ignore: cast_nullable_to_non_nullable
              as String?,
      nameComm: freezed == nameComm
          ? _self.nameComm
          : nameComm // ignore: cast_nullable_to_non_nullable
              as String?,
      nameTech: freezed == nameTech
          ? _self.nameTech
          : nameTech // ignore: cast_nullable_to_non_nullable
              as String?,
      emailAdmin: freezed == emailAdmin
          ? _self.emailAdmin
          : emailAdmin // ignore: cast_nullable_to_non_nullable
              as String?,
      emailCeo: freezed == emailCeo
          ? _self.emailCeo
          : emailCeo // ignore: cast_nullable_to_non_nullable
              as String?,
      emailComm: freezed == emailComm
          ? _self.emailComm
          : emailComm // ignore: cast_nullable_to_non_nullable
              as String?,
      emailTech: freezed == emailTech
          ? _self.emailTech
          : emailTech // ignore: cast_nullable_to_non_nullable
              as String?,
      formTechnicalDescriptionValid: freezed == formTechnicalDescriptionValid
          ? _self.formTechnicalDescriptionValid
          : formTechnicalDescriptionValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formCommercialroposalValid: freezed == formCommercialroposalValid
          ? _self.formCommercialroposalValid
          : formCommercialroposalValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formProjectPlanValid: freezed == formProjectPlanValid
          ? _self.formProjectPlanValid
          : formProjectPlanValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formOverviewValid: freezed == formOverviewValid
          ? _self.formOverviewValid
          : formOverviewValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formTechnicalDescription: freezed == formTechnicalDescription
          ? _self.formTechnicalDescription
          : formTechnicalDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      formCommercialViability: freezed == formCommercialViability
          ? _self.formCommercialViability
          : formCommercialViability // ignore: cast_nullable_to_non_nullable
              as String?,
      formOverivew: freezed == formOverivew
          ? _self.formOverivew
          : formOverivew // ignore: cast_nullable_to_non_nullable
              as String?,
      formProjectPlan: freezed == formProjectPlan
          ? _self.formProjectPlan
          : formProjectPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      tagKeys: freezed == tagKeys
          ? _self.tagKeys
          : tagKeys // ignore: cast_nullable_to_non_nullable
              as String?,
      tagLabels: freezed == tagLabels
          ? _self.tagLabels
          : tagLabels // ignore: cast_nullable_to_non_nullable
              as String?,
      agreeTsAndCs: freezed == agreeTsAndCs
          ? _self.agreeTsAndCs
          : agreeTsAndCs // ignore: cast_nullable_to_non_nullable
              as String?,
      agreeTsAndCsDetails: freezed == agreeTsAndCsDetails
          ? _self.agreeTsAndCsDetails
          : agreeTsAndCsDetails // ignore: cast_nullable_to_non_nullable
              as String?,
      isSubmitted: freezed == isSubmitted
          ? _self.isSubmitted
          : isSubmitted // ignore: cast_nullable_to_non_nullable
              as String?,
      isSubmittedDetails: freezed == isSubmittedDetails
          ? _self.isSubmittedDetails
          : isSubmittedDetails // ignore: cast_nullable_to_non_nullable
              as String?,
      mfaUserId: freezed == mfaUserId
          ? _self.mfaUserId
          : mfaUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      mfaLastValidated: freezed == mfaLastValidated
          ? _self.mfaLastValidated
          : mfaLastValidated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      optInToReceivePromotions: freezed == optInToReceivePromotions
          ? _self.optInToReceivePromotions
          : optInToReceivePromotions // ignore: cast_nullable_to_non_nullable
              as String?,
      optOutToShareWithNations: freezed == optOutToShareWithNations
          ? _self.optOutToShareWithNations
          : optOutToShareWithNations // ignore: cast_nullable_to_non_nullable
              as String?,
      submissionDate: freezed == submissionDate
          ? _self.submissionDate
          : submissionDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      progressEmptyFields: null == progressEmptyFields
          ? _self.progressEmptyFields
          : progressEmptyFields // ignore: cast_nullable_to_non_nullable
              as int,
      progressValidFields: null == progressValidFields
          ? _self.progressValidFields
          : progressValidFields // ignore: cast_nullable_to_non_nullable
              as int,
      progressInvalidFields: null == progressInvalidFields
          ? _self.progressInvalidFields
          : progressInvalidFields // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get quadChart {
    if (_self.quadChart == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.quadChart!, (value) {
      return _then(_self.copyWith(quadChart: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get proposal {
    if (_self.proposal == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.proposal!, (value) {
      return _then(_self.copyWith(proposal: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvAdmin {
    if (_self.applicationCvAdmin == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvAdmin!, (value) {
      return _then(_self.copyWith(applicationCvAdmin: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvCeo {
    if (_self.applicationCvCeo == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvCeo!, (value) {
      return _then(_self.copyWith(applicationCvCeo: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvComm {
    if (_self.applicationCvComm == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvComm!, (value) {
      return _then(_self.copyWith(applicationCvComm: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvTech {
    if (_self.applicationCvTech == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvTech!, (value) {
      return _then(_self.copyWith(applicationCvTech: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ApplicationModel].
extension ApplicationModelPatterns on ApplicationModel {
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
    TResult Function(_ApplicationModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApplicationModel() when $default != null:
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
    TResult Function(_ApplicationModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApplicationModel():
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
    TResult? Function(_ApplicationModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApplicationModel() when $default != null:
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
            @UuidConverter() UuidValue applicationPublicId,
            int challengeIndex,
            String title,
            String shortDescription,
            String applicationImageAsset,
            String tagsValid,
            bool applicationIsSubmitable,
            PdfDocumentModel? quadChart,
            PdfDocumentModel? proposal,
            String? applicationImageUrl,
            PdfDocumentModel? applicationCvAdmin,
            PdfDocumentModel? applicationCvCeo,
            PdfDocumentModel? applicationCvComm,
            PdfDocumentModel? applicationCvTech,
            String? applicationPicAdmin,
            String? applicationPicCeo,
            String? applicationPicComm,
            String? applicationPicTech,
            String? nameAdmin,
            String? nameCeo,
            String? nameComm,
            String? nameTech,
            String? emailAdmin,
            String? emailCeo,
            String? emailComm,
            String? emailTech,
            String? formTechnicalDescriptionValid,
            String? formCommercialroposalValid,
            String? formProjectPlanValid,
            String? formOverviewValid,
            String? formTechnicalDescription,
            String? formCommercialViability,
            String? formOverivew,
            String? formProjectPlan,
            String? tagKeys,
            String? tagLabels,
            String? agreeTsAndCs,
            String? agreeTsAndCsDetails,
            String? isSubmitted,
            String? isSubmittedDetails,
            String? mfaUserId,
            DateTime? mfaLastValidated,
            String? optInToReceivePromotions,
            String? optOutToShareWithNations,
            DateTime? submissionDate,
            int progressEmptyFields,
            int progressValidFields,
            int progressInvalidFields)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ApplicationModel() when $default != null:
        return $default(
            _that.applicationPublicId,
            _that.challengeIndex,
            _that.title,
            _that.shortDescription,
            _that.applicationImageAsset,
            _that.tagsValid,
            _that.applicationIsSubmitable,
            _that.quadChart,
            _that.proposal,
            _that.applicationImageUrl,
            _that.applicationCvAdmin,
            _that.applicationCvCeo,
            _that.applicationCvComm,
            _that.applicationCvTech,
            _that.applicationPicAdmin,
            _that.applicationPicCeo,
            _that.applicationPicComm,
            _that.applicationPicTech,
            _that.nameAdmin,
            _that.nameCeo,
            _that.nameComm,
            _that.nameTech,
            _that.emailAdmin,
            _that.emailCeo,
            _that.emailComm,
            _that.emailTech,
            _that.formTechnicalDescriptionValid,
            _that.formCommercialroposalValid,
            _that.formProjectPlanValid,
            _that.formOverviewValid,
            _that.formTechnicalDescription,
            _that.formCommercialViability,
            _that.formOverivew,
            _that.formProjectPlan,
            _that.tagKeys,
            _that.tagLabels,
            _that.agreeTsAndCs,
            _that.agreeTsAndCsDetails,
            _that.isSubmitted,
            _that.isSubmittedDetails,
            _that.mfaUserId,
            _that.mfaLastValidated,
            _that.optInToReceivePromotions,
            _that.optOutToShareWithNations,
            _that.submissionDate,
            _that.progressEmptyFields,
            _that.progressValidFields,
            _that.progressInvalidFields);
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
            @UuidConverter() UuidValue applicationPublicId,
            int challengeIndex,
            String title,
            String shortDescription,
            String applicationImageAsset,
            String tagsValid,
            bool applicationIsSubmitable,
            PdfDocumentModel? quadChart,
            PdfDocumentModel? proposal,
            String? applicationImageUrl,
            PdfDocumentModel? applicationCvAdmin,
            PdfDocumentModel? applicationCvCeo,
            PdfDocumentModel? applicationCvComm,
            PdfDocumentModel? applicationCvTech,
            String? applicationPicAdmin,
            String? applicationPicCeo,
            String? applicationPicComm,
            String? applicationPicTech,
            String? nameAdmin,
            String? nameCeo,
            String? nameComm,
            String? nameTech,
            String? emailAdmin,
            String? emailCeo,
            String? emailComm,
            String? emailTech,
            String? formTechnicalDescriptionValid,
            String? formCommercialroposalValid,
            String? formProjectPlanValid,
            String? formOverviewValid,
            String? formTechnicalDescription,
            String? formCommercialViability,
            String? formOverivew,
            String? formProjectPlan,
            String? tagKeys,
            String? tagLabels,
            String? agreeTsAndCs,
            String? agreeTsAndCsDetails,
            String? isSubmitted,
            String? isSubmittedDetails,
            String? mfaUserId,
            DateTime? mfaLastValidated,
            String? optInToReceivePromotions,
            String? optOutToShareWithNations,
            DateTime? submissionDate,
            int progressEmptyFields,
            int progressValidFields,
            int progressInvalidFields)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApplicationModel():
        return $default(
            _that.applicationPublicId,
            _that.challengeIndex,
            _that.title,
            _that.shortDescription,
            _that.applicationImageAsset,
            _that.tagsValid,
            _that.applicationIsSubmitable,
            _that.quadChart,
            _that.proposal,
            _that.applicationImageUrl,
            _that.applicationCvAdmin,
            _that.applicationCvCeo,
            _that.applicationCvComm,
            _that.applicationCvTech,
            _that.applicationPicAdmin,
            _that.applicationPicCeo,
            _that.applicationPicComm,
            _that.applicationPicTech,
            _that.nameAdmin,
            _that.nameCeo,
            _that.nameComm,
            _that.nameTech,
            _that.emailAdmin,
            _that.emailCeo,
            _that.emailComm,
            _that.emailTech,
            _that.formTechnicalDescriptionValid,
            _that.formCommercialroposalValid,
            _that.formProjectPlanValid,
            _that.formOverviewValid,
            _that.formTechnicalDescription,
            _that.formCommercialViability,
            _that.formOverivew,
            _that.formProjectPlan,
            _that.tagKeys,
            _that.tagLabels,
            _that.agreeTsAndCs,
            _that.agreeTsAndCsDetails,
            _that.isSubmitted,
            _that.isSubmittedDetails,
            _that.mfaUserId,
            _that.mfaLastValidated,
            _that.optInToReceivePromotions,
            _that.optOutToShareWithNations,
            _that.submissionDate,
            _that.progressEmptyFields,
            _that.progressValidFields,
            _that.progressInvalidFields);
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
            @UuidConverter() UuidValue applicationPublicId,
            int challengeIndex,
            String title,
            String shortDescription,
            String applicationImageAsset,
            String tagsValid,
            bool applicationIsSubmitable,
            PdfDocumentModel? quadChart,
            PdfDocumentModel? proposal,
            String? applicationImageUrl,
            PdfDocumentModel? applicationCvAdmin,
            PdfDocumentModel? applicationCvCeo,
            PdfDocumentModel? applicationCvComm,
            PdfDocumentModel? applicationCvTech,
            String? applicationPicAdmin,
            String? applicationPicCeo,
            String? applicationPicComm,
            String? applicationPicTech,
            String? nameAdmin,
            String? nameCeo,
            String? nameComm,
            String? nameTech,
            String? emailAdmin,
            String? emailCeo,
            String? emailComm,
            String? emailTech,
            String? formTechnicalDescriptionValid,
            String? formCommercialroposalValid,
            String? formProjectPlanValid,
            String? formOverviewValid,
            String? formTechnicalDescription,
            String? formCommercialViability,
            String? formOverivew,
            String? formProjectPlan,
            String? tagKeys,
            String? tagLabels,
            String? agreeTsAndCs,
            String? agreeTsAndCsDetails,
            String? isSubmitted,
            String? isSubmittedDetails,
            String? mfaUserId,
            DateTime? mfaLastValidated,
            String? optInToReceivePromotions,
            String? optOutToShareWithNations,
            DateTime? submissionDate,
            int progressEmptyFields,
            int progressValidFields,
            int progressInvalidFields)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ApplicationModel() when $default != null:
        return $default(
            _that.applicationPublicId,
            _that.challengeIndex,
            _that.title,
            _that.shortDescription,
            _that.applicationImageAsset,
            _that.tagsValid,
            _that.applicationIsSubmitable,
            _that.quadChart,
            _that.proposal,
            _that.applicationImageUrl,
            _that.applicationCvAdmin,
            _that.applicationCvCeo,
            _that.applicationCvComm,
            _that.applicationCvTech,
            _that.applicationPicAdmin,
            _that.applicationPicCeo,
            _that.applicationPicComm,
            _that.applicationPicTech,
            _that.nameAdmin,
            _that.nameCeo,
            _that.nameComm,
            _that.nameTech,
            _that.emailAdmin,
            _that.emailCeo,
            _that.emailComm,
            _that.emailTech,
            _that.formTechnicalDescriptionValid,
            _that.formCommercialroposalValid,
            _that.formProjectPlanValid,
            _that.formOverviewValid,
            _that.formTechnicalDescription,
            _that.formCommercialViability,
            _that.formOverivew,
            _that.formProjectPlan,
            _that.tagKeys,
            _that.tagLabels,
            _that.agreeTsAndCs,
            _that.agreeTsAndCsDetails,
            _that.isSubmitted,
            _that.isSubmittedDetails,
            _that.mfaUserId,
            _that.mfaLastValidated,
            _that.optInToReceivePromotions,
            _that.optOutToShareWithNations,
            _that.submissionDate,
            _that.progressEmptyFields,
            _that.progressValidFields,
            _that.progressInvalidFields);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ApplicationModel implements ApplicationModel {
  const _ApplicationModel(
      {@UuidConverter() required this.applicationPublicId,
      required this.challengeIndex,
      required this.title,
      required this.shortDescription,
      required this.applicationImageAsset,
      this.tagsValid = BOOL_TRUE,
      this.applicationIsSubmitable = false,
      this.quadChart,
      this.proposal,
      this.applicationImageUrl,
      this.applicationCvAdmin,
      this.applicationCvCeo,
      this.applicationCvComm,
      this.applicationCvTech,
      this.applicationPicAdmin,
      this.applicationPicCeo,
      this.applicationPicComm,
      this.applicationPicTech,
      this.nameAdmin,
      this.nameCeo,
      this.nameComm,
      this.nameTech,
      this.emailAdmin,
      this.emailCeo,
      this.emailComm,
      this.emailTech,
      this.formTechnicalDescriptionValid,
      this.formCommercialroposalValid,
      this.formProjectPlanValid,
      this.formOverviewValid,
      this.formTechnicalDescription,
      this.formCommercialViability,
      this.formOverivew,
      this.formProjectPlan,
      this.tagKeys,
      this.tagLabels,
      this.agreeTsAndCs,
      this.agreeTsAndCsDetails,
      this.isSubmitted,
      this.isSubmittedDetails,
      this.mfaUserId,
      this.mfaLastValidated,
      this.optInToReceivePromotions = "0",
      this.optOutToShareWithNations = "1",
      this.submissionDate,
      this.progressEmptyFields = 0,
      this.progressValidFields = 0,
      this.progressInvalidFields = 0});
  factory _ApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationModelFromJson(json);

  @override
  @UuidConverter()
  final UuidValue applicationPublicId;
  @override
  final int challengeIndex;
  @override
  final String title;
  @override
  final String shortDescription;
  @override
  final String applicationImageAsset;
  @override
  @JsonKey()
  final String tagsValid;
  @override
  @JsonKey()
  final bool applicationIsSubmitable;
  @override
  final PdfDocumentModel? quadChart;
  @override
  final PdfDocumentModel? proposal;
//required List<PdfDocumentModel> documents,
  @override
  final String? applicationImageUrl;
  @override
  final PdfDocumentModel? applicationCvAdmin;
  @override
  final PdfDocumentModel? applicationCvCeo;
  @override
  final PdfDocumentModel? applicationCvComm;
  @override
  final PdfDocumentModel? applicationCvTech;
  @override
  final String? applicationPicAdmin;
  @override
  final String? applicationPicCeo;
  @override
  final String? applicationPicComm;
  @override
  final String? applicationPicTech;
  @override
  final String? nameAdmin;
  @override
  final String? nameCeo;
  @override
  final String? nameComm;
  @override
  final String? nameTech;
  @override
  final String? emailAdmin;
  @override
  final String? emailCeo;
  @override
  final String? emailComm;
  @override
  final String? emailTech;
  @override
  final String? formTechnicalDescriptionValid;
  @override
  final String? formCommercialroposalValid;
  @override
  final String? formProjectPlanValid;
  @override
  final String? formOverviewValid;
  @override
  final String? formTechnicalDescription;
  @override
  final String? formCommercialViability;
  @override
  final String? formOverivew;
  @override
  final String? formProjectPlan;
  @override
  final String? tagKeys;
  @override
  final String? tagLabels;
  @override
  final String? agreeTsAndCs;
  @override
  final String? agreeTsAndCsDetails;
  @override
  final String? isSubmitted;
  @override
  final String? isSubmittedDetails;
  @override
  final String? mfaUserId;
  @override
  final DateTime? mfaLastValidated;
  @override
  @JsonKey()
  final String? optInToReceivePromotions;
  @override
  @JsonKey()
  final String? optOutToShareWithNations;
  @override
  final DateTime? submissionDate;
  @override
  @JsonKey()
  final int progressEmptyFields;
  @override
  @JsonKey()
  final int progressValidFields;
  @override
  @JsonKey()
  final int progressInvalidFields;

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ApplicationModelCopyWith<_ApplicationModel> get copyWith =>
      __$ApplicationModelCopyWithImpl<_ApplicationModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ApplicationModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ApplicationModel &&
            (identical(other.applicationPublicId, applicationPublicId) ||
                other.applicationPublicId == applicationPublicId) &&
            (identical(other.challengeIndex, challengeIndex) ||
                other.challengeIndex == challengeIndex) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.shortDescription, shortDescription) ||
                other.shortDescription == shortDescription) &&
            (identical(other.applicationImageAsset, applicationImageAsset) ||
                other.applicationImageAsset == applicationImageAsset) &&
            (identical(other.tagsValid, tagsValid) ||
                other.tagsValid == tagsValid) &&
            (identical(other.applicationIsSubmitable, applicationIsSubmitable) ||
                other.applicationIsSubmitable == applicationIsSubmitable) &&
            (identical(other.quadChart, quadChart) ||
                other.quadChart == quadChart) &&
            (identical(other.proposal, proposal) ||
                other.proposal == proposal) &&
            (identical(other.applicationImageUrl, applicationImageUrl) ||
                other.applicationImageUrl == applicationImageUrl) &&
            (identical(other.applicationCvAdmin, applicationCvAdmin) ||
                other.applicationCvAdmin == applicationCvAdmin) &&
            (identical(other.applicationCvCeo, applicationCvCeo) ||
                other.applicationCvCeo == applicationCvCeo) &&
            (identical(other.applicationCvComm, applicationCvComm) ||
                other.applicationCvComm == applicationCvComm) &&
            (identical(other.applicationCvTech, applicationCvTech) ||
                other.applicationCvTech == applicationCvTech) &&
            (identical(other.applicationPicAdmin, applicationPicAdmin) ||
                other.applicationPicAdmin == applicationPicAdmin) &&
            (identical(other.applicationPicCeo, applicationPicCeo) ||
                other.applicationPicCeo == applicationPicCeo) &&
            (identical(other.applicationPicComm, applicationPicComm) ||
                other.applicationPicComm == applicationPicComm) &&
            (identical(other.applicationPicTech, applicationPicTech) ||
                other.applicationPicTech == applicationPicTech) &&
            (identical(other.nameAdmin, nameAdmin) ||
                other.nameAdmin == nameAdmin) &&
            (identical(other.nameCeo, nameCeo) || other.nameCeo == nameCeo) &&
            (identical(other.nameComm, nameComm) ||
                other.nameComm == nameComm) &&
            (identical(other.nameTech, nameTech) ||
                other.nameTech == nameTech) &&
            (identical(other.emailAdmin, emailAdmin) ||
                other.emailAdmin == emailAdmin) &&
            (identical(other.emailCeo, emailCeo) ||
                other.emailCeo == emailCeo) &&
            (identical(other.emailComm, emailComm) ||
                other.emailComm == emailComm) &&
            (identical(other.emailTech, emailTech) ||
                other.emailTech == emailTech) &&
            (identical(other.formTechnicalDescriptionValid, formTechnicalDescriptionValid) ||
                other.formTechnicalDescriptionValid ==
                    formTechnicalDescriptionValid) &&
            (identical(other.formCommercialroposalValid, formCommercialroposalValid) ||
                other.formCommercialroposalValid ==
                    formCommercialroposalValid) &&
            (identical(other.formProjectPlanValid, formProjectPlanValid) ||
                other.formProjectPlanValid == formProjectPlanValid) &&
            (identical(other.formOverviewValid, formOverviewValid) ||
                other.formOverviewValid == formOverviewValid) &&
            (identical(other.formTechnicalDescription, formTechnicalDescription) ||
                other.formTechnicalDescription == formTechnicalDescription) &&
            (identical(other.formCommercialViability, formCommercialViability) ||
                other.formCommercialViability == formCommercialViability) &&
            (identical(other.formOverivew, formOverivew) ||
                other.formOverivew == formOverivew) &&
            (identical(other.formProjectPlan, formProjectPlan) || other.formProjectPlan == formProjectPlan) &&
            (identical(other.tagKeys, tagKeys) || other.tagKeys == tagKeys) &&
            (identical(other.tagLabels, tagLabels) || other.tagLabels == tagLabels) &&
            (identical(other.agreeTsAndCs, agreeTsAndCs) || other.agreeTsAndCs == agreeTsAndCs) &&
            (identical(other.agreeTsAndCsDetails, agreeTsAndCsDetails) || other.agreeTsAndCsDetails == agreeTsAndCsDetails) &&
            (identical(other.isSubmitted, isSubmitted) || other.isSubmitted == isSubmitted) &&
            (identical(other.isSubmittedDetails, isSubmittedDetails) || other.isSubmittedDetails == isSubmittedDetails) &&
            (identical(other.mfaUserId, mfaUserId) || other.mfaUserId == mfaUserId) &&
            (identical(other.mfaLastValidated, mfaLastValidated) || other.mfaLastValidated == mfaLastValidated) &&
            (identical(other.optInToReceivePromotions, optInToReceivePromotions) || other.optInToReceivePromotions == optInToReceivePromotions) &&
            (identical(other.optOutToShareWithNations, optOutToShareWithNations) || other.optOutToShareWithNations == optOutToShareWithNations) &&
            (identical(other.submissionDate, submissionDate) || other.submissionDate == submissionDate) &&
            (identical(other.progressEmptyFields, progressEmptyFields) || other.progressEmptyFields == progressEmptyFields) &&
            (identical(other.progressValidFields, progressValidFields) || other.progressValidFields == progressValidFields) &&
            (identical(other.progressInvalidFields, progressInvalidFields) || other.progressInvalidFields == progressInvalidFields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        applicationPublicId,
        challengeIndex,
        title,
        shortDescription,
        applicationImageAsset,
        tagsValid,
        applicationIsSubmitable,
        quadChart,
        proposal,
        applicationImageUrl,
        applicationCvAdmin,
        applicationCvCeo,
        applicationCvComm,
        applicationCvTech,
        applicationPicAdmin,
        applicationPicCeo,
        applicationPicComm,
        applicationPicTech,
        nameAdmin,
        nameCeo,
        nameComm,
        nameTech,
        emailAdmin,
        emailCeo,
        emailComm,
        emailTech,
        formTechnicalDescriptionValid,
        formCommercialroposalValid,
        formProjectPlanValid,
        formOverviewValid,
        formTechnicalDescription,
        formCommercialViability,
        formOverivew,
        formProjectPlan,
        tagKeys,
        tagLabels,
        agreeTsAndCs,
        agreeTsAndCsDetails,
        isSubmitted,
        isSubmittedDetails,
        mfaUserId,
        mfaLastValidated,
        optInToReceivePromotions,
        optOutToShareWithNations,
        submissionDate,
        progressEmptyFields,
        progressValidFields,
        progressInvalidFields
      ]);

  @override
  String toString() {
    return 'ApplicationModel(applicationPublicId: $applicationPublicId, challengeIndex: $challengeIndex, title: $title, shortDescription: $shortDescription, applicationImageAsset: $applicationImageAsset, tagsValid: $tagsValid, applicationIsSubmitable: $applicationIsSubmitable, quadChart: $quadChart, proposal: $proposal, applicationImageUrl: $applicationImageUrl, applicationCvAdmin: $applicationCvAdmin, applicationCvCeo: $applicationCvCeo, applicationCvComm: $applicationCvComm, applicationCvTech: $applicationCvTech, applicationPicAdmin: $applicationPicAdmin, applicationPicCeo: $applicationPicCeo, applicationPicComm: $applicationPicComm, applicationPicTech: $applicationPicTech, nameAdmin: $nameAdmin, nameCeo: $nameCeo, nameComm: $nameComm, nameTech: $nameTech, emailAdmin: $emailAdmin, emailCeo: $emailCeo, emailComm: $emailComm, emailTech: $emailTech, formTechnicalDescriptionValid: $formTechnicalDescriptionValid, formCommercialroposalValid: $formCommercialroposalValid, formProjectPlanValid: $formProjectPlanValid, formOverviewValid: $formOverviewValid, formTechnicalDescription: $formTechnicalDescription, formCommercialViability: $formCommercialViability, formOverivew: $formOverivew, formProjectPlan: $formProjectPlan, tagKeys: $tagKeys, tagLabels: $tagLabels, agreeTsAndCs: $agreeTsAndCs, agreeTsAndCsDetails: $agreeTsAndCsDetails, isSubmitted: $isSubmitted, isSubmittedDetails: $isSubmittedDetails, mfaUserId: $mfaUserId, mfaLastValidated: $mfaLastValidated, optInToReceivePromotions: $optInToReceivePromotions, optOutToShareWithNations: $optOutToShareWithNations, submissionDate: $submissionDate, progressEmptyFields: $progressEmptyFields, progressValidFields: $progressValidFields, progressInvalidFields: $progressInvalidFields)';
  }
}

/// @nodoc
abstract mixin class _$ApplicationModelCopyWith<$Res>
    implements $ApplicationModelCopyWith<$Res> {
  factory _$ApplicationModelCopyWith(
          _ApplicationModel value, $Res Function(_ApplicationModel) _then) =
      __$ApplicationModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@UuidConverter() UuidValue applicationPublicId,
      int challengeIndex,
      String title,
      String shortDescription,
      String applicationImageAsset,
      String tagsValid,
      bool applicationIsSubmitable,
      PdfDocumentModel? quadChart,
      PdfDocumentModel? proposal,
      String? applicationImageUrl,
      PdfDocumentModel? applicationCvAdmin,
      PdfDocumentModel? applicationCvCeo,
      PdfDocumentModel? applicationCvComm,
      PdfDocumentModel? applicationCvTech,
      String? applicationPicAdmin,
      String? applicationPicCeo,
      String? applicationPicComm,
      String? applicationPicTech,
      String? nameAdmin,
      String? nameCeo,
      String? nameComm,
      String? nameTech,
      String? emailAdmin,
      String? emailCeo,
      String? emailComm,
      String? emailTech,
      String? formTechnicalDescriptionValid,
      String? formCommercialroposalValid,
      String? formProjectPlanValid,
      String? formOverviewValid,
      String? formTechnicalDescription,
      String? formCommercialViability,
      String? formOverivew,
      String? formProjectPlan,
      String? tagKeys,
      String? tagLabels,
      String? agreeTsAndCs,
      String? agreeTsAndCsDetails,
      String? isSubmitted,
      String? isSubmittedDetails,
      String? mfaUserId,
      DateTime? mfaLastValidated,
      String? optInToReceivePromotions,
      String? optOutToShareWithNations,
      DateTime? submissionDate,
      int progressEmptyFields,
      int progressValidFields,
      int progressInvalidFields});

  @override
  $PdfDocumentModelCopyWith<$Res>? get quadChart;
  @override
  $PdfDocumentModelCopyWith<$Res>? get proposal;
  @override
  $PdfDocumentModelCopyWith<$Res>? get applicationCvAdmin;
  @override
  $PdfDocumentModelCopyWith<$Res>? get applicationCvCeo;
  @override
  $PdfDocumentModelCopyWith<$Res>? get applicationCvComm;
  @override
  $PdfDocumentModelCopyWith<$Res>? get applicationCvTech;
}

/// @nodoc
class __$ApplicationModelCopyWithImpl<$Res>
    implements _$ApplicationModelCopyWith<$Res> {
  __$ApplicationModelCopyWithImpl(this._self, this._then);

  final _ApplicationModel _self;
  final $Res Function(_ApplicationModel) _then;

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? applicationPublicId = null,
    Object? challengeIndex = null,
    Object? title = null,
    Object? shortDescription = null,
    Object? applicationImageAsset = null,
    Object? tagsValid = null,
    Object? applicationIsSubmitable = null,
    Object? quadChart = freezed,
    Object? proposal = freezed,
    Object? applicationImageUrl = freezed,
    Object? applicationCvAdmin = freezed,
    Object? applicationCvCeo = freezed,
    Object? applicationCvComm = freezed,
    Object? applicationCvTech = freezed,
    Object? applicationPicAdmin = freezed,
    Object? applicationPicCeo = freezed,
    Object? applicationPicComm = freezed,
    Object? applicationPicTech = freezed,
    Object? nameAdmin = freezed,
    Object? nameCeo = freezed,
    Object? nameComm = freezed,
    Object? nameTech = freezed,
    Object? emailAdmin = freezed,
    Object? emailCeo = freezed,
    Object? emailComm = freezed,
    Object? emailTech = freezed,
    Object? formTechnicalDescriptionValid = freezed,
    Object? formCommercialroposalValid = freezed,
    Object? formProjectPlanValid = freezed,
    Object? formOverviewValid = freezed,
    Object? formTechnicalDescription = freezed,
    Object? formCommercialViability = freezed,
    Object? formOverivew = freezed,
    Object? formProjectPlan = freezed,
    Object? tagKeys = freezed,
    Object? tagLabels = freezed,
    Object? agreeTsAndCs = freezed,
    Object? agreeTsAndCsDetails = freezed,
    Object? isSubmitted = freezed,
    Object? isSubmittedDetails = freezed,
    Object? mfaUserId = freezed,
    Object? mfaLastValidated = freezed,
    Object? optInToReceivePromotions = freezed,
    Object? optOutToShareWithNations = freezed,
    Object? submissionDate = freezed,
    Object? progressEmptyFields = null,
    Object? progressValidFields = null,
    Object? progressInvalidFields = null,
  }) {
    return _then(_ApplicationModel(
      applicationPublicId: null == applicationPublicId
          ? _self.applicationPublicId
          : applicationPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      challengeIndex: null == challengeIndex
          ? _self.challengeIndex
          : challengeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      shortDescription: null == shortDescription
          ? _self.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      applicationImageAsset: null == applicationImageAsset
          ? _self.applicationImageAsset
          : applicationImageAsset // ignore: cast_nullable_to_non_nullable
              as String,
      tagsValid: null == tagsValid
          ? _self.tagsValid
          : tagsValid // ignore: cast_nullable_to_non_nullable
              as String,
      applicationIsSubmitable: null == applicationIsSubmitable
          ? _self.applicationIsSubmitable
          : applicationIsSubmitable // ignore: cast_nullable_to_non_nullable
              as bool,
      quadChart: freezed == quadChart
          ? _self.quadChart
          : quadChart // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      proposal: freezed == proposal
          ? _self.proposal
          : proposal // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationImageUrl: freezed == applicationImageUrl
          ? _self.applicationImageUrl
          : applicationImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationCvAdmin: freezed == applicationCvAdmin
          ? _self.applicationCvAdmin
          : applicationCvAdmin // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationCvCeo: freezed == applicationCvCeo
          ? _self.applicationCvCeo
          : applicationCvCeo // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationCvComm: freezed == applicationCvComm
          ? _self.applicationCvComm
          : applicationCvComm // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationCvTech: freezed == applicationCvTech
          ? _self.applicationCvTech
          : applicationCvTech // ignore: cast_nullable_to_non_nullable
              as PdfDocumentModel?,
      applicationPicAdmin: freezed == applicationPicAdmin
          ? _self.applicationPicAdmin
          : applicationPicAdmin // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationPicCeo: freezed == applicationPicCeo
          ? _self.applicationPicCeo
          : applicationPicCeo // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationPicComm: freezed == applicationPicComm
          ? _self.applicationPicComm
          : applicationPicComm // ignore: cast_nullable_to_non_nullable
              as String?,
      applicationPicTech: freezed == applicationPicTech
          ? _self.applicationPicTech
          : applicationPicTech // ignore: cast_nullable_to_non_nullable
              as String?,
      nameAdmin: freezed == nameAdmin
          ? _self.nameAdmin
          : nameAdmin // ignore: cast_nullable_to_non_nullable
              as String?,
      nameCeo: freezed == nameCeo
          ? _self.nameCeo
          : nameCeo // ignore: cast_nullable_to_non_nullable
              as String?,
      nameComm: freezed == nameComm
          ? _self.nameComm
          : nameComm // ignore: cast_nullable_to_non_nullable
              as String?,
      nameTech: freezed == nameTech
          ? _self.nameTech
          : nameTech // ignore: cast_nullable_to_non_nullable
              as String?,
      emailAdmin: freezed == emailAdmin
          ? _self.emailAdmin
          : emailAdmin // ignore: cast_nullable_to_non_nullable
              as String?,
      emailCeo: freezed == emailCeo
          ? _self.emailCeo
          : emailCeo // ignore: cast_nullable_to_non_nullable
              as String?,
      emailComm: freezed == emailComm
          ? _self.emailComm
          : emailComm // ignore: cast_nullable_to_non_nullable
              as String?,
      emailTech: freezed == emailTech
          ? _self.emailTech
          : emailTech // ignore: cast_nullable_to_non_nullable
              as String?,
      formTechnicalDescriptionValid: freezed == formTechnicalDescriptionValid
          ? _self.formTechnicalDescriptionValid
          : formTechnicalDescriptionValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formCommercialroposalValid: freezed == formCommercialroposalValid
          ? _self.formCommercialroposalValid
          : formCommercialroposalValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formProjectPlanValid: freezed == formProjectPlanValid
          ? _self.formProjectPlanValid
          : formProjectPlanValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formOverviewValid: freezed == formOverviewValid
          ? _self.formOverviewValid
          : formOverviewValid // ignore: cast_nullable_to_non_nullable
              as String?,
      formTechnicalDescription: freezed == formTechnicalDescription
          ? _self.formTechnicalDescription
          : formTechnicalDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      formCommercialViability: freezed == formCommercialViability
          ? _self.formCommercialViability
          : formCommercialViability // ignore: cast_nullable_to_non_nullable
              as String?,
      formOverivew: freezed == formOverivew
          ? _self.formOverivew
          : formOverivew // ignore: cast_nullable_to_non_nullable
              as String?,
      formProjectPlan: freezed == formProjectPlan
          ? _self.formProjectPlan
          : formProjectPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      tagKeys: freezed == tagKeys
          ? _self.tagKeys
          : tagKeys // ignore: cast_nullable_to_non_nullable
              as String?,
      tagLabels: freezed == tagLabels
          ? _self.tagLabels
          : tagLabels // ignore: cast_nullable_to_non_nullable
              as String?,
      agreeTsAndCs: freezed == agreeTsAndCs
          ? _self.agreeTsAndCs
          : agreeTsAndCs // ignore: cast_nullable_to_non_nullable
              as String?,
      agreeTsAndCsDetails: freezed == agreeTsAndCsDetails
          ? _self.agreeTsAndCsDetails
          : agreeTsAndCsDetails // ignore: cast_nullable_to_non_nullable
              as String?,
      isSubmitted: freezed == isSubmitted
          ? _self.isSubmitted
          : isSubmitted // ignore: cast_nullable_to_non_nullable
              as String?,
      isSubmittedDetails: freezed == isSubmittedDetails
          ? _self.isSubmittedDetails
          : isSubmittedDetails // ignore: cast_nullable_to_non_nullable
              as String?,
      mfaUserId: freezed == mfaUserId
          ? _self.mfaUserId
          : mfaUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      mfaLastValidated: freezed == mfaLastValidated
          ? _self.mfaLastValidated
          : mfaLastValidated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      optInToReceivePromotions: freezed == optInToReceivePromotions
          ? _self.optInToReceivePromotions
          : optInToReceivePromotions // ignore: cast_nullable_to_non_nullable
              as String?,
      optOutToShareWithNations: freezed == optOutToShareWithNations
          ? _self.optOutToShareWithNations
          : optOutToShareWithNations // ignore: cast_nullable_to_non_nullable
              as String?,
      submissionDate: freezed == submissionDate
          ? _self.submissionDate
          : submissionDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      progressEmptyFields: null == progressEmptyFields
          ? _self.progressEmptyFields
          : progressEmptyFields // ignore: cast_nullable_to_non_nullable
              as int,
      progressValidFields: null == progressValidFields
          ? _self.progressValidFields
          : progressValidFields // ignore: cast_nullable_to_non_nullable
              as int,
      progressInvalidFields: null == progressInvalidFields
          ? _self.progressInvalidFields
          : progressInvalidFields // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get quadChart {
    if (_self.quadChart == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.quadChart!, (value) {
      return _then(_self.copyWith(quadChart: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get proposal {
    if (_self.proposal == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.proposal!, (value) {
      return _then(_self.copyWith(proposal: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvAdmin {
    if (_self.applicationCvAdmin == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvAdmin!, (value) {
      return _then(_self.copyWith(applicationCvAdmin: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvCeo {
    if (_self.applicationCvCeo == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvCeo!, (value) {
      return _then(_self.copyWith(applicationCvCeo: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvComm {
    if (_self.applicationCvComm == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvComm!, (value) {
      return _then(_self.copyWith(applicationCvComm: value));
    });
  }

  /// Create a copy of ApplicationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<$Res>? get applicationCvTech {
    if (_self.applicationCvTech == null) {
      return null;
    }

    return $PdfDocumentModelCopyWith<$Res>(_self.applicationCvTech!, (value) {
      return _then(_self.copyWith(applicationCvTech: value));
    });
  }
}

/// @nodoc
mixin _$PdfDocumentModel {
  @UuidConverter()
  UuidValue get pdfDocumentPublicId;
  @UuidConverter()
  UuidValue get fkApplicationPublicId;
  String get documentUrl;
  DocumentType get documentType;

  /// Create a copy of PdfDocumentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PdfDocumentModelCopyWith<PdfDocumentModel> get copyWith =>
      _$PdfDocumentModelCopyWithImpl<PdfDocumentModel>(
          this as PdfDocumentModel, _$identity);

  /// Serializes this PdfDocumentModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PdfDocumentModel &&
            (identical(other.pdfDocumentPublicId, pdfDocumentPublicId) ||
                other.pdfDocumentPublicId == pdfDocumentPublicId) &&
            (identical(other.fkApplicationPublicId, fkApplicationPublicId) ||
                other.fkApplicationPublicId == fkApplicationPublicId) &&
            (identical(other.documentUrl, documentUrl) ||
                other.documentUrl == documentUrl) &&
            (identical(other.documentType, documentType) ||
                other.documentType == documentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pdfDocumentPublicId,
      fkApplicationPublicId, documentUrl, documentType);

  @override
  String toString() {
    return 'PdfDocumentModel(pdfDocumentPublicId: $pdfDocumentPublicId, fkApplicationPublicId: $fkApplicationPublicId, documentUrl: $documentUrl, documentType: $documentType)';
  }
}

/// @nodoc
abstract mixin class $PdfDocumentModelCopyWith<$Res> {
  factory $PdfDocumentModelCopyWith(
          PdfDocumentModel value, $Res Function(PdfDocumentModel) _then) =
      _$PdfDocumentModelCopyWithImpl;
  @useResult
  $Res call(
      {@UuidConverter() UuidValue pdfDocumentPublicId,
      @UuidConverter() UuidValue fkApplicationPublicId,
      String documentUrl,
      DocumentType documentType});
}

/// @nodoc
class _$PdfDocumentModelCopyWithImpl<$Res>
    implements $PdfDocumentModelCopyWith<$Res> {
  _$PdfDocumentModelCopyWithImpl(this._self, this._then);

  final PdfDocumentModel _self;
  final $Res Function(PdfDocumentModel) _then;

  /// Create a copy of PdfDocumentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfDocumentPublicId = null,
    Object? fkApplicationPublicId = null,
    Object? documentUrl = null,
    Object? documentType = null,
  }) {
    return _then(_self.copyWith(
      pdfDocumentPublicId: null == pdfDocumentPublicId
          ? _self.pdfDocumentPublicId
          : pdfDocumentPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      fkApplicationPublicId: null == fkApplicationPublicId
          ? _self.fkApplicationPublicId
          : fkApplicationPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      documentUrl: null == documentUrl
          ? _self.documentUrl
          : documentUrl // ignore: cast_nullable_to_non_nullable
              as String,
      documentType: null == documentType
          ? _self.documentType
          : documentType // ignore: cast_nullable_to_non_nullable
              as DocumentType,
    ));
  }
}

/// Adds pattern-matching-related methods to [PdfDocumentModel].
extension PdfDocumentModelPatterns on PdfDocumentModel {
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
    TResult Function(_PdfDocumentModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PdfDocumentModel() when $default != null:
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
    TResult Function(_PdfDocumentModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfDocumentModel():
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
    TResult? Function(_PdfDocumentModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfDocumentModel() when $default != null:
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
            @UuidConverter() UuidValue pdfDocumentPublicId,
            @UuidConverter() UuidValue fkApplicationPublicId,
            String documentUrl,
            DocumentType documentType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PdfDocumentModel() when $default != null:
        return $default(_that.pdfDocumentPublicId, _that.fkApplicationPublicId,
            _that.documentUrl, _that.documentType);
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
            @UuidConverter() UuidValue pdfDocumentPublicId,
            @UuidConverter() UuidValue fkApplicationPublicId,
            String documentUrl,
            DocumentType documentType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfDocumentModel():
        return $default(_that.pdfDocumentPublicId, _that.fkApplicationPublicId,
            _that.documentUrl, _that.documentType);
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
            @UuidConverter() UuidValue pdfDocumentPublicId,
            @UuidConverter() UuidValue fkApplicationPublicId,
            String documentUrl,
            DocumentType documentType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfDocumentModel() when $default != null:
        return $default(_that.pdfDocumentPublicId, _that.fkApplicationPublicId,
            _that.documentUrl, _that.documentType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PdfDocumentModel implements PdfDocumentModel {
  const _PdfDocumentModel(
      {@UuidConverter() required this.pdfDocumentPublicId,
      @UuidConverter() required this.fkApplicationPublicId,
      required this.documentUrl,
      required this.documentType});
  factory _PdfDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$PdfDocumentModelFromJson(json);

  @override
  @UuidConverter()
  final UuidValue pdfDocumentPublicId;
  @override
  @UuidConverter()
  final UuidValue fkApplicationPublicId;
  @override
  final String documentUrl;
  @override
  final DocumentType documentType;

  /// Create a copy of PdfDocumentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PdfDocumentModelCopyWith<_PdfDocumentModel> get copyWith =>
      __$PdfDocumentModelCopyWithImpl<_PdfDocumentModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PdfDocumentModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PdfDocumentModel &&
            (identical(other.pdfDocumentPublicId, pdfDocumentPublicId) ||
                other.pdfDocumentPublicId == pdfDocumentPublicId) &&
            (identical(other.fkApplicationPublicId, fkApplicationPublicId) ||
                other.fkApplicationPublicId == fkApplicationPublicId) &&
            (identical(other.documentUrl, documentUrl) ||
                other.documentUrl == documentUrl) &&
            (identical(other.documentType, documentType) ||
                other.documentType == documentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pdfDocumentPublicId,
      fkApplicationPublicId, documentUrl, documentType);

  @override
  String toString() {
    return 'PdfDocumentModel(pdfDocumentPublicId: $pdfDocumentPublicId, fkApplicationPublicId: $fkApplicationPublicId, documentUrl: $documentUrl, documentType: $documentType)';
  }
}

/// @nodoc
abstract mixin class _$PdfDocumentModelCopyWith<$Res>
    implements $PdfDocumentModelCopyWith<$Res> {
  factory _$PdfDocumentModelCopyWith(
          _PdfDocumentModel value, $Res Function(_PdfDocumentModel) _then) =
      __$PdfDocumentModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@UuidConverter() UuidValue pdfDocumentPublicId,
      @UuidConverter() UuidValue fkApplicationPublicId,
      String documentUrl,
      DocumentType documentType});
}

/// @nodoc
class __$PdfDocumentModelCopyWithImpl<$Res>
    implements _$PdfDocumentModelCopyWith<$Res> {
  __$PdfDocumentModelCopyWithImpl(this._self, this._then);

  final _PdfDocumentModel _self;
  final $Res Function(_PdfDocumentModel) _then;

  /// Create a copy of PdfDocumentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pdfDocumentPublicId = null,
    Object? fkApplicationPublicId = null,
    Object? documentUrl = null,
    Object? documentType = null,
  }) {
    return _then(_PdfDocumentModel(
      pdfDocumentPublicId: null == pdfDocumentPublicId
          ? _self.pdfDocumentPublicId
          : pdfDocumentPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      fkApplicationPublicId: null == fkApplicationPublicId
          ? _self.fkApplicationPublicId
          : fkApplicationPublicId // ignore: cast_nullable_to_non_nullable
              as UuidValue,
      documentUrl: null == documentUrl
          ? _self.documentUrl
          : documentUrl // ignore: cast_nullable_to_non_nullable
              as String,
      documentType: null == documentType
          ? _self.documentType
          : documentType // ignore: cast_nullable_to_non_nullable
              as DocumentType,
    ));
  }
}

// dart format on
