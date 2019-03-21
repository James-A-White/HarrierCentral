import 'dart:convert';
import 'dart:core';

class UserModel {
  UserModel({
    this.allowNegativeCredit,
    this.atHashCount,
    this.attendenceState,
    this.credit,
    this.currencySymbol,
    this.digitsAfterDecimal,
    this.displayName,
    this.email,
    this.eventId,
    this.eventLocale,
    this.eventPrice,
    this.facebookId,
    this.firstName,
    this.hasherEventMapId,
    this.hasherId,
    this.hashName,
    this.isFollowing,
    this.isHare,
    this.isMember,
    this.isPaid,
    this.lastName,
    this.onInCount,
    this.onTrailCount,
    this.paidCount,
    this.paymentType,
    this.photo,
    this.qrCode,
    this.qrSecretCode,
    this.rsvpState,
    this.userEndEvent,
    this.userRunCount,
    this.userStartEvent,
    this.virginVisitorType,
    this.waitingForCount,
  });

  DateTime userEndEvent;
  DateTime userStartEvent;
  double credit;
  double eventPrice;
  int allowNegativeCredit;
  int atHashCount;
  int digitsAfterDecimal;
  int isFollowing;
  int isMember;
  int onInCount;
  int onTrailCount;
  int paidCount;
  int virginVisitorType;
  int waitingForCount;
  String currencySymbol;
  String displayName;
  String email;
  String eventId;
  String eventLocale;
  String facebookId;
  String firstName;
  String hasherId;
  String hashName;
  String lastName;
  String photo;
  String qrCode;
  String qrSecretCode;
  int attendenceState;
  int isHare;
  int isPaid;
  int paymentType;
  int rsvpState;
  int userRunCount;
  String hasherEventMapId;

  static List<UserModel> listFromJson(String jsonResult) {
    final List<UserModel> items = <UserModel>[];

    UserModel item;
    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = UserModel(
          // isRsvped: jsonItem['isRsvped'],
          allowNegativeCredit: jsonItem['allowNegativeCredit'],
          atHashCount: jsonItem['atHashCount'],
          attendenceState: jsonItem['attendenceState'],
          credit: jsonItem['credit'] * 1.0,
          currencySymbol: jsonItem['currencySymbol'],
          digitsAfterDecimal: jsonItem['digitsAfterDecimal'],
          displayName: jsonItem['displayName'],
          email: jsonItem['eMail'],
          eventId: jsonItem['eventId'],
          eventLocale: jsonItem['eventLocale'],
          eventPrice: jsonItem['eventPrice'] * 1.0,
          facebookId: jsonItem['facebookId'],
          firstName: jsonItem['firstName'],
          hasherEventMapId: jsonItem['hasherEventMapId'],
          hasherId: jsonItem['userId'],
          isFollowing: jsonItem['isFollowing'],
          isHare: jsonItem['isHare'],
          isMember: jsonItem['isMember'],
          isPaid: jsonItem['isPaid'],
          lastName: jsonItem['lastName'],
          onInCount: jsonItem['onInCount'],
          onTrailCount: jsonItem['onTrailCount'],
          paidCount: jsonItem['paidCount'],
          paymentType: jsonItem['paymentType'],
          photo: jsonItem['photo'],
          qrCode: jsonItem['qrCode'],
          qrSecretCode: jsonItem['qrSecretCode'],
          rsvpState: jsonItem['rsvpState'],
          userEndEvent:
              DateTime.parse(jsonItem['userEndEvent'] ?? '2000-01-01 19:00:00'),
          userRunCount: jsonItem['userRunCount'],
          userStartEvent: DateTime.parse(
              jsonItem['userStartEvent'] ?? '2000-01-01 19:00:00'),
          virginVisitorType: jsonItem['virginVisitorType'],
          waitingForCount: jsonItem['waitingForCount'],
        );

        items.add(item);
      },
    );

    return items;
  }

  @override
  String toString() => '$displayName';

  int requestedRsvpState = -1;
  int requestedHaringState = -1;
  int requestedAttendenceState = -1;
}
