import 'dart:core';

class ProcessQrScanForCheckinModel {

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


  ProcessQrScanForCheckinModel(
    {
        this.result,
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
        this.allowNegativeCredit
    });
}

		// coalesce(@result,'') as [resultStr1], 
		// coalesce(@currencySymbol,'') as [currencySymbol],
		// coalesce(@paymentInstructions,'') as [resultStr2], 
		// coalesce(@scannedUserName,'') as [resultStr3], 
		// coalesce(@targetUserId,'00000000-0000-0000-0000-000000000000') as resultGuid1, 
		// coalesce(@hasherEventMapId,'00000000-0000-0000-0000-000000000000') as [resultGuid2], 
		// coalesce(@usersRunCountThisKennel,-1) as [resultInt1], 
		// coalesce(@activePaymentCounterThisEvent,-1) as [resultInt2],
		// coalesce(@isCreditAllowed,-1) as [resultInt3],
		// coalesce(@currencyDigitsAfterDecimal,-1) as [resultInt4],
		// coalesce(@resultDecimal1,-9999999) as [resultDecimal1],
		// coalesce(@remainingCredit,-9999999) as [resultDecimal2]