import 'package:hcportal/imports.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'application_model.freezed.dart';
part 'application_model.g.dart';

@freezed
abstract class ApplicationModel with _$ApplicationModel {
  const factory ApplicationModel({
    @UuidConverter() required UuidValue applicationPublicId,
    required int challengeIndex,
    required String title,
    required String shortDescription,
    required String applicationImageAsset,
    @Default(BOOL_TRUE) String tagsValid,
    @Default(false) bool applicationIsSubmitable,
    PdfDocumentModel? quadChart,
    PdfDocumentModel? proposal,
    //required List<PdfDocumentModel> documents,

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
    @Default("0") String? optInToReceivePromotions,
    @Default("1") String? optOutToShareWithNations,
    DateTime? submissionDate,
    @Default(0) int progressEmptyFields,
    @Default(0) int progressValidFields,
    @Default(0) int progressInvalidFields,
  }) = _ApplicationModel;

  //  'empty=$totalEmptyStatus, valid=$totalValidStatus, invalid=$totalInvalidStatus, total=$totalTotal');

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationModelFromJson(json);

  factory ApplicationModel.empty() => ApplicationModel(
        applicationPublicId:
            UuidValue.fromString('00000000-0000-0000-0000-000000000000'),
        challengeIndex: 1,
        title: '<new application>',
        shortDescription:
            '<this is where the innovator will provide a short description that will go with the application>',
        applicationImageAsset: 'default.webp',
      );
}

@freezed
abstract class PdfDocumentModel with _$PdfDocumentModel {
  const factory PdfDocumentModel({
    @UuidConverter() required UuidValue pdfDocumentPublicId,
    @UuidConverter() required UuidValue fkApplicationPublicId,
    required String documentUrl,
    required DocumentType documentType,
  }) = _PdfDocumentModel;

  factory PdfDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$PdfDocumentModelFromJson(json);

  factory PdfDocumentModel.empty() => PdfDocumentModel(
        pdfDocumentPublicId:
            UuidValue.fromString('24c354c3-58a6-4a91-a419-57bf72e573ff'),
        fkApplicationPublicId:
            UuidValue.fromString('34c354c3-58a6-4a91-a419-57bf72e573ff'),
        documentUrl: '<new application>',
        documentType: DocumentType.diagram,
      );
}
