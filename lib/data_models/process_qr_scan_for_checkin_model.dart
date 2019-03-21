import 'dart:core';

class ProcessQrScanForCheckinModel {
  ProcessQrScanForCheckinModel(
      {this.result,
      this.resultStr,
      this.currencySymbol,
      this.paymentInstructions,
      this.scannedUserName,
      this.targetUserId,
      this.hasherEventMapId,
      this.userRunCountThisKennel,
      this.isPaid,
      this.paymentType,
      this.isCreditAllowed,
      this.currencyDigitsAfterDecimal,
      this.runPriceThisUser,
      this.remainingCredit,
      this.photo,
      this.attendenceState,
      this.rsvpState,
      this.isMember,
      this.isHare,
      this.virginVisitorType,
      this.userStartEvent,
      this.userEndEvent,
      this.isFollowing,
      this.allowNegativeCredit});

  final int result;
  final String resultStr;
  final String currencySymbol;
  final String paymentInstructions;
  final String scannedUserName;
  final String targetUserId;
  final String hasherEventMapId;
  final int userRunCountThisKennel;
  final int isPaid;
  final int paymentType;
  final int isCreditAllowed;
  final int currencyDigitsAfterDecimal;
  final double runPriceThisUser;
  final double remainingCredit;
  final String photo;
  final int attendenceState;
  final int rsvpState;
  final int isMember;
  final int isHare;
  final int virginVisitorType;
  final DateTime userStartEvent;
  final DateTime userEndEvent;
  final int isFollowing;
  final int allowNegativeCredit;
}

