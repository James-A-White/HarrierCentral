//import 'package:hcportal/imports.dart';

enum TabStatus {
  unknown, // empty box
  isCompleteAndValid, // green box with check
  isEmpty, // empty box
  isInvalid, // warning sign
  isInProgress, // there are a mix of fields that are complete and incomplete, but no fields that are invalid
}

enum TabLocked {
  unknown, // empty box
  tabLocked, // force locked icon
  tabUnlocked, // choose an icon based on TabStatus
}

enum ControlValidity {
  unknown, // the validity has not yet been determined
  validEmpty, // the field is empty and is not required
  invalidEmpty, // the field is empty and is required
  invalid, // at least one field is empty or invalid on the tab
  valid, // all required fields are valid
}

enum UiControlType {
  string,
  intValue,
  dropdown,
  imageUpload,
  pdfUpload,
  invisible,
  checkbox,
  button,
}

// enum BlobStorageFolder {
//   cvs,
//   proposals,
//   application_images,
//   stakeholder_images,
// }

enum DocumentType {
  none(
    'Not a document',
    '',
    '',
  ),
  quadChart(
    'Quad Chart',
    'images/other/quad_chart.png',
    'images/other/quad_chart_uploaded.png',
  ),
  proposal(
    'Proposal',
    'images/other/proposal.png',
    'images/other/proposal_uploaded.png',
  ),
  cv(
    'CV',
    'images/other/cv.png',
    'images/other/cv_uploaded.png',
  ),
  diagram('Diagram', '', ''),
  applicationImage(
    'Application Image',
    '',
    '',
  ),
  stakeholderImage(
    'Stakeholder Image',
    'images/other/upload_image.png',
    '',
  ),
  eventImage(
    'Event Image',
    'images/other/upload_image.png',
    '',
  ),
  kennelLogo(
    'Kennel Logo',
    'images/other/upload_image.png',
    '',
  ),
  newsflashImage(
    'Newsflash Image',
    'images/other/upload_image.png',
    '',
  ),
  ;

  const DocumentType(
    this.fullName,
    this.documentNotPresentAsset,
    this.documentPresentAsset,
  );

  final String fullName;
  final String documentPresentAsset;
  final String documentNotPresentAsset;
}

// // all tabs defined here
// enum ChallengeEnum {
//   none(
//       idx: 0,
//       fullName: 'none',
//       abbreviation: '--',
//       challengeImage: '',
//       icon: MaterialCommunityIcons.border_none_variant),

//   energyReselience(
//       idx: 1,
//       fullName: 'Energy Resilience',
//       abbreviation: 'ER',
//       challengeImage: 'er.webp',
//       icon: MaterialIcons.electrical_services),
//   dataAndInfoSharing(
//     idx: 2,
//     fullName: 'Data & Info Sharing',
//     abbreviation: 'DIS',
//     challengeImage: 'dis.webp',
//     icon: FontAwesome.share_alt,
//   ),
//   sensingAndSurveillance(
//     idx: 3,
//     fullName: 'Sensing & Surveillance',
//     abbreviation: 'SND',
//     challengeImage: 'sns.webp',
//     icon: FontAwesome.assistive_listening_systems,
//   ),
//   criticalInfrastructure(
//     idx: 4,
//     fullName: 'Critical Infrastructure',
//     abbreviation: 'CI',
//     challengeImage: 'ci.webp',
//     icon: MaterialCommunityIcons.pipe_disconnected,
//   ),
//   healthAndHumanAugmentation(
//       idx: 5,
//       fullName: 'Human Health & Augmentation',
//       abbreviation: 'HHA',
//       challengeImage: 'hha.webp',
//       icon: MaterialCommunityIcons.human_queue);

//   const ChallengeEnum(
//       {required this.idx,
//       required this.fullName,
//       required this.abbreviation,
//       required this.challengeImage,
//       required this.icon});

//   final int idx;
//   final String fullName;
//   final String abbreviation;
//   final String challengeImage;
//   final IconData icon;
// }
