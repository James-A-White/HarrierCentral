/// A request to add a kennel, as returned by hcportal_getKennelRequests
/// (E12.F1.S5). Plain Dart class — no Freezed required.
class KennelRequestModel {
  const KennelRequestModel({
    required this.id,
    required this.status,
    this.submittedOn,
    this.confirmedAt,
    required this.firstName,
    required this.lastName,
    required this.hashName,
    required this.email,
    required this.kennelName,
    required this.kennelShortName,
    required this.kennelDescription,
    this.kennelUrl,
    this.kennelFacebookUrl,
    this.countryText,
    this.regionText,
    this.cityText,
    this.countryId,
    this.regionId,
    this.cityId,
    this.countryName,
    this.regionName,
    this.cityName,
    this.hashCash,
    this.runsPerMonth,
    this.hashersPerRun,
    this.nextRunNumber,
    this.howDidYouLearn,
    this.comments,
    this.termsAnswers,
    this.submitIp,
    this.reviewNote,
    this.reviewedAt,
    this.reviewedByHashName,
    this.kennelId,
    this.approvedKennelSlug,
    this.existingHashName,
    this.similarKennels,
  });

  factory KennelRequestModel.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] as String?) ?? '';
    String? n(String k) {
      final v = (j[k] as String?)?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    String? id(String k) => (j[k] as String?)?.toLowerCase();
    DateTime? d(String k) => DateTime.tryParse((j[k] as String?) ?? '');

    return KennelRequestModel(
      id: id('KennelImportId') ?? '',
      status: (j['RequestStatus'] as num?)?.toInt() ?? 1,
      submittedOn: d('SubmittedOn'),
      confirmedAt: d('ConfirmedAt'),
      firstName: s('FirstName'),
      lastName: s('LastName'),
      hashName: s('HashName'),
      email: s('EmailAddress'),
      kennelName: s('KennelName'),
      kennelShortName: s('KennelShortName'),
      kennelDescription: s('KennelDescription'),
      kennelUrl: n('KennelUrl'),
      kennelFacebookUrl: n('KennelFacebookUrl'),
      countryText: n('Country'),
      regionText: n('Region'),
      cityText: n('City'),
      countryId: id('CountryId'),
      regionId: id('RegionId'),
      cityId: id('CityId'),
      countryName: n('CountryName'),
      regionName: n('RegionName'),
      cityName: n('CityName'),
      hashCash: n('HashCash'),
      runsPerMonth: n('NumberOfRunsPerMonth'),
      hashersPerRun: n('NumberOfHashersPerRun'),
      nextRunNumber: n('NextRunNumber'),
      howDidYouLearn: n('HowDidYouLearnAboutHc'),
      comments: n('Comments'),
      termsAnswers: n('TermsAnswers'),
      submitIp: n('SubmitIp'),
      reviewNote: n('ReviewNote'),
      reviewedAt: d('ReviewedAt'),
      reviewedByHashName: n('ReviewedByHashName'),
      kennelId: id('KennelId'),
      approvedKennelSlug: n('ApprovedKennelSlug'),
      existingHashName: n('ExistingHashName'),
      similarKennels: n('SimilarKennels'),
    );
  }

  final String id;

  /// 0 awaiting email · 1 new · 2 approved · 3 rejected · 4 spam · 5 duplicate.
  final int status;
  final DateTime? submittedOn;
  final DateTime? confirmedAt;
  final String firstName;
  final String lastName;
  final String hashName;
  final String email;
  final String kennelName;
  final String kennelShortName;
  final String kennelDescription;
  final String? kennelUrl;
  final String? kennelFacebookUrl;

  /// What the requester typed (the old forms had no picker).
  final String? countryText;
  final String? regionText;
  final String? cityText;

  /// The database's own places, when resolved.
  final String? countryId;
  final String? regionId;
  final String? cityId;
  final String? countryName;
  final String? regionName;
  final String? cityName;

  final String? hashCash;
  final String? runsPerMonth;
  final String? hashersPerRun;
  final String? nextRunNumber;
  final String? howDidYouLearn;
  final String? comments;

  /// The three opt-in answers from the hashruns.org form, '1: … | 2: … | 3: …'
  /// (null for requests from the old forms, which never kept them).
  final String? termsAnswers;
  final String? submitIp;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final String? reviewedByHashName;
  final String? kennelId;
  final String? approvedKennelSlug;

  /// The account that already holds [email]; approval makes it the admin.
  final String? existingHashName;

  /// Live kennels with the same name or short name — a possible duplicate.
  final String? similarKennels;

  bool get isOpen => status == 0 || status == 1;

  /// A short name approval will accept: letters and digits, at most 20.
  bool get shortNameIsValid => RegExp(r'^[A-Za-z0-9]{1,20}$').hasMatch(kennelShortName);

  bool get locationIsResolved => countryId != null && regionId != null && cityId != null;

  String get requesterName {
    final full = '$firstName $lastName'.trim();
    return hashName.isNotEmpty ? '$hashName ($full)' : full;
  }
}

/// The request statuses, in the order the page's filter chips show them.
enum KennelRequestStatus {
  newRequest(1, 'New'),
  awaitingEmail(0, 'Awaiting email'),
  approved(2, 'Approved'),
  rejected(3, 'Rejected'),
  spam(4, 'Spam'),
  duplicate(5, 'Duplicate');

  const KennelRequestStatus(this.code, this.label);
  final int code;
  final String label;

  static KennelRequestStatus fromCode(int code) =>
      values.firstWhere((s) => s.code == code, orElse: () => newRequest);
}
