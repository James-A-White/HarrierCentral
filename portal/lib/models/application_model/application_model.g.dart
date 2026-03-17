// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApplicationModel _$ApplicationModelFromJson(Map<String, dynamic> json) =>
    _ApplicationModel(
      applicationPublicId:
          const UuidConverter().fromJson(json['applicationPublicId'] as String),
      challengeIndex: (json['challengeIndex'] as num).toInt(),
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String,
      applicationImageAsset: json['applicationImageAsset'] as String,
      tagsValid: json['tagsValid'] as String? ?? BOOL_TRUE,
      applicationIsSubmitable:
          json['applicationIsSubmitable'] as bool? ?? false,
      quadChart: json['quadChart'] == null
          ? null
          : PdfDocumentModel.fromJson(
              json['quadChart'] as Map<String, dynamic>),
      proposal: json['proposal'] == null
          ? null
          : PdfDocumentModel.fromJson(json['proposal'] as Map<String, dynamic>),
      applicationImageUrl: json['applicationImageUrl'] as String?,
      applicationCvAdmin: json['applicationCvAdmin'] == null
          ? null
          : PdfDocumentModel.fromJson(
              json['applicationCvAdmin'] as Map<String, dynamic>),
      applicationCvCeo: json['applicationCvCeo'] == null
          ? null
          : PdfDocumentModel.fromJson(
              json['applicationCvCeo'] as Map<String, dynamic>),
      applicationCvComm: json['applicationCvComm'] == null
          ? null
          : PdfDocumentModel.fromJson(
              json['applicationCvComm'] as Map<String, dynamic>),
      applicationCvTech: json['applicationCvTech'] == null
          ? null
          : PdfDocumentModel.fromJson(
              json['applicationCvTech'] as Map<String, dynamic>),
      applicationPicAdmin: json['applicationPicAdmin'] as String?,
      applicationPicCeo: json['applicationPicCeo'] as String?,
      applicationPicComm: json['applicationPicComm'] as String?,
      applicationPicTech: json['applicationPicTech'] as String?,
      nameAdmin: json['nameAdmin'] as String?,
      nameCeo: json['nameCeo'] as String?,
      nameComm: json['nameComm'] as String?,
      nameTech: json['nameTech'] as String?,
      emailAdmin: json['emailAdmin'] as String?,
      emailCeo: json['emailCeo'] as String?,
      emailComm: json['emailComm'] as String?,
      emailTech: json['emailTech'] as String?,
      formTechnicalDescriptionValid:
          json['formTechnicalDescriptionValid'] as String?,
      formCommercialroposalValid: json['formCommercialroposalValid'] as String?,
      formProjectPlanValid: json['formProjectPlanValid'] as String?,
      formOverviewValid: json['formOverviewValid'] as String?,
      formTechnicalDescription: json['formTechnicalDescription'] as String?,
      formCommercialViability: json['formCommercialViability'] as String?,
      formOverivew: json['formOverivew'] as String?,
      formProjectPlan: json['formProjectPlan'] as String?,
      tagKeys: json['tagKeys'] as String?,
      tagLabels: json['tagLabels'] as String?,
      agreeTsAndCs: json['agreeTsAndCs'] as String?,
      agreeTsAndCsDetails: json['agreeTsAndCsDetails'] as String?,
      isSubmitted: json['isSubmitted'] as String?,
      isSubmittedDetails: json['isSubmittedDetails'] as String?,
      mfaUserId: json['mfaUserId'] as String?,
      mfaLastValidated: json['mfaLastValidated'] == null
          ? null
          : DateTime.parse(json['mfaLastValidated'] as String),
      optInToReceivePromotions:
          json['optInToReceivePromotions'] as String? ?? "0",
      optOutToShareWithNations:
          json['optOutToShareWithNations'] as String? ?? "1",
      submissionDate: json['submissionDate'] == null
          ? null
          : DateTime.parse(json['submissionDate'] as String),
      progressEmptyFields: (json['progressEmptyFields'] as num?)?.toInt() ?? 0,
      progressValidFields: (json['progressValidFields'] as num?)?.toInt() ?? 0,
      progressInvalidFields:
          (json['progressInvalidFields'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ApplicationModelToJson(_ApplicationModel instance) =>
    <String, dynamic>{
      'applicationPublicId':
          const UuidConverter().toJson(instance.applicationPublicId),
      'challengeIndex': instance.challengeIndex,
      'title': instance.title,
      'shortDescription': instance.shortDescription,
      'applicationImageAsset': instance.applicationImageAsset,
      'tagsValid': instance.tagsValid,
      'applicationIsSubmitable': instance.applicationIsSubmitable,
      'quadChart': instance.quadChart,
      'proposal': instance.proposal,
      'applicationImageUrl': instance.applicationImageUrl,
      'applicationCvAdmin': instance.applicationCvAdmin,
      'applicationCvCeo': instance.applicationCvCeo,
      'applicationCvComm': instance.applicationCvComm,
      'applicationCvTech': instance.applicationCvTech,
      'applicationPicAdmin': instance.applicationPicAdmin,
      'applicationPicCeo': instance.applicationPicCeo,
      'applicationPicComm': instance.applicationPicComm,
      'applicationPicTech': instance.applicationPicTech,
      'nameAdmin': instance.nameAdmin,
      'nameCeo': instance.nameCeo,
      'nameComm': instance.nameComm,
      'nameTech': instance.nameTech,
      'emailAdmin': instance.emailAdmin,
      'emailCeo': instance.emailCeo,
      'emailComm': instance.emailComm,
      'emailTech': instance.emailTech,
      'formTechnicalDescriptionValid': instance.formTechnicalDescriptionValid,
      'formCommercialroposalValid': instance.formCommercialroposalValid,
      'formProjectPlanValid': instance.formProjectPlanValid,
      'formOverviewValid': instance.formOverviewValid,
      'formTechnicalDescription': instance.formTechnicalDescription,
      'formCommercialViability': instance.formCommercialViability,
      'formOverivew': instance.formOverivew,
      'formProjectPlan': instance.formProjectPlan,
      'tagKeys': instance.tagKeys,
      'tagLabels': instance.tagLabels,
      'agreeTsAndCs': instance.agreeTsAndCs,
      'agreeTsAndCsDetails': instance.agreeTsAndCsDetails,
      'isSubmitted': instance.isSubmitted,
      'isSubmittedDetails': instance.isSubmittedDetails,
      'mfaUserId': instance.mfaUserId,
      'mfaLastValidated': instance.mfaLastValidated?.toIso8601String(),
      'optInToReceivePromotions': instance.optInToReceivePromotions,
      'optOutToShareWithNations': instance.optOutToShareWithNations,
      'submissionDate': instance.submissionDate?.toIso8601String(),
      'progressEmptyFields': instance.progressEmptyFields,
      'progressValidFields': instance.progressValidFields,
      'progressInvalidFields': instance.progressInvalidFields,
    };

_PdfDocumentModel _$PdfDocumentModelFromJson(Map<String, dynamic> json) =>
    _PdfDocumentModel(
      pdfDocumentPublicId:
          const UuidConverter().fromJson(json['pdfDocumentPublicId'] as String),
      fkApplicationPublicId: const UuidConverter()
          .fromJson(json['fkApplicationPublicId'] as String),
      documentUrl: json['documentUrl'] as String,
      documentType: $enumDecode(_$DocumentTypeEnumMap, json['documentType']),
    );

Map<String, dynamic> _$PdfDocumentModelToJson(_PdfDocumentModel instance) =>
    <String, dynamic>{
      'pdfDocumentPublicId':
          const UuidConverter().toJson(instance.pdfDocumentPublicId),
      'fkApplicationPublicId':
          const UuidConverter().toJson(instance.fkApplicationPublicId),
      'documentUrl': instance.documentUrl,
      'documentType': _$DocumentTypeEnumMap[instance.documentType]!,
    };

const _$DocumentTypeEnumMap = {
  DocumentType.none: 'none',
  DocumentType.quadChart: 'quadChart',
  DocumentType.proposal: 'proposal',
  DocumentType.cv: 'cv',
  DocumentType.diagram: 'diagram',
  DocumentType.applicationImage: 'applicationImage',
  DocumentType.stakeholderImage: 'stakeholderImage',
  DocumentType.eventImage: 'eventImage',
};
