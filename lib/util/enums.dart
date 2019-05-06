import 'dart:core';



abstract class Enum<T> {
  const Enum(this._value);
  final T _value;
  T get value => _value;
}


class EnumVirginVisitor<int> extends Enum<int> {
  const EnumVirginVisitor(int val) : super(val);
}

const EnumVirginVisitor<int> enumVirgin = EnumVirginVisitor<int>(1);
const EnumVirginVisitor<int> enumVisitor = EnumVirginVisitor<int>(2);

//////////////////////////


class EnumRsvpState<int> extends Enum<int> {
  const EnumRsvpState(int val) : super(val);
}

const EnumRsvpState<int> rsvpUnknown = EnumRsvpState<int>(0);
const EnumRsvpState<int> rsvpNo = EnumRsvpState<int>(1);
const EnumRsvpState<int> rsvpMaybe = EnumRsvpState<int>(2);
const EnumRsvpState<int> rsvpYes = EnumRsvpState<int>(3);

//////////////////////////

class EnumIsHare<int> extends Enum<int> {
  const EnumIsHare(int val) : super(val);
}

const EnumIsHare<int> isHareNo = EnumIsHare<int>(0);
const EnumIsHare<int> isHareYes = EnumIsHare<int>(1);

/////////////////////////

class EnumAttendenceState<int> extends Enum<int> {
  const EnumAttendenceState(int val) : super(val);
}

const EnumAttendenceState<int> attndenceUnknown = EnumAttendenceState<int>(0);
const EnumAttendenceState<int> attendenceNo = EnumAttendenceState<int>(10);
const EnumAttendenceState<int> attendenceAtHash = EnumAttendenceState<int>(20);
const EnumAttendenceState<int> attendenceOnIn = EnumAttendenceState<int>(30);
const EnumAttendenceState<int> attendenceGone = EnumAttendenceState<int>(40);

//////////////////////////

class EnumIsPaid<int> extends Enum<int> {
  const EnumIsPaid(int val) : super(val);
}

const EnumIsPaid<int> isPaidNo = EnumIsPaid<int>(0);
const EnumIsPaid<int> isPaidYes = EnumIsPaid<int>(1);

//////////////////////////

class EnumPaymentType<int> extends Enum<int> {
  const EnumPaymentType(int val) : super(val);
}

const EnumPaymentType<int> paymentTypeUnknown = EnumPaymentType<int>(0);
const EnumPaymentType<int> paymentNotPaid = EnumPaymentType<int>(1);
const EnumPaymentType<int> paymentFreeRun = EnumPaymentType<int>(2);
const EnumPaymentType<int> paymentCash = EnumPaymentType<int>(3);
const EnumPaymentType<int> paymentBankTransfer = EnumPaymentType<int>(4);
const EnumPaymentType<int> paymentCashOtherAmount = EnumPaymentType<int>(5);
const EnumPaymentType<int> paymentHashCredit = EnumPaymentType<int>(6);
const EnumPaymentType<int> paymentBankTransferOtherAmount =
    EnumPaymentType<int>(7);

const EnumPaymentType<int> paymentTypeUnknownTotals = EnumPaymentType<int>(100);
const EnumPaymentType<int> paymentNotPaidTotals = EnumPaymentType<int>(101);
const EnumPaymentType<int> paymentFreeRunTotals = EnumPaymentType<int>(102);
const EnumPaymentType<int> paymentCashTotals = EnumPaymentType<int>(103);
const EnumPaymentType<int> paymentBankTransferTotals =
    EnumPaymentType<int>(104);
const EnumPaymentType<int> paymentCashOtherAmountTotals =
    EnumPaymentType<int>(105);
const EnumPaymentType<int> paymentHashCreditTotals = EnumPaymentType<int>(106);
const EnumPaymentType<int> paymentBankTransferOtherAmountTotals =
    EnumPaymentType<int>(107);

//////////////////////////

class EnumCheckInType<int> extends Enum<int> {
  const EnumCheckInType(int val) : super(val);
}

const EnumCheckInType<int> checkinTypeRunStart = EnumCheckInType<int>(0);
const EnumCheckInType<int> checkinTypeRunEnd = EnumCheckInType<int>(1);

//////////////////////////

class EnumHasherType<int> extends Enum<int> {
  const EnumHasherType(int val) : super(val);
}

const EnumHasherType<int> hasherTypeMember = EnumHasherType<int>(0);
const EnumHasherType<int> hasherTypeVisitor = EnumHasherType<int>(1);
const EnumHasherType<int> hasherTypeVirgin = EnumHasherType<int>(2);

//////////////////////////

class EnumFollowType<int> extends Enum<int> {
  const EnumFollowType(int val) : super(val);
}

const EnumFollowType<int> followTypeCancel = EnumFollowType<int>(-1);
const EnumFollowType<int> followTypeAuto = EnumFollowType<int>(0);
const EnumFollowType<int> followTypeFollow = EnumFollowType<int>(1);
const EnumFollowType<int> followTypeIgnore = EnumFollowType<int>(2);

//////////////////////////

class EnumServerStatus<int> extends Enum<int> {
  const EnumServerStatus(int val) : super(val);
}

const EnumServerStatus<int> serverStatusDownForMaintenance =
    EnumServerStatus<int>(0);
const EnumServerStatus<int> serverStatusUp = EnumServerStatus<int>(1);
const EnumServerStatus<int> serverStatusDegraded = EnumServerStatus<int>(2);

//////////////////////////

class EnumLoginMessageType<int> extends Enum<int> {
  const EnumLoginMessageType(int val) : super(val);
}

const EnumLoginMessageType<int> loginMessageTypeNone =
    EnumLoginMessageType<int>(0);
const EnumLoginMessageType<int> loginMessageTypeAlert =
    EnumLoginMessageType<int>(1);
const EnumLoginMessageType<int> loginMessageTypeFullView =
    EnumLoginMessageType<int>(2);
const EnumLoginMessageType<int> loginMessageTypeFullViewWithCountdown =
    EnumLoginMessageType<int>(3);
const EnumLoginMessageType<int> loginMessageTypeImageViewNoContinue =
    EnumLoginMessageType<int>(4);
const EnumLoginMessageType<int> loginMessageTypeImageViewWithContinue =
    EnumLoginMessageType<int>(5);

//////////////////////////

class EnumLoginApproval<int> extends Enum<int> {
  const EnumLoginApproval(int val) : super(val);
}

const EnumLoginApproval<int> loginApprovalUnknown = EnumLoginApproval<int>(0);
const EnumLoginApproval<int> loginApprovalApproved = EnumLoginApproval<int>(1);
const EnumLoginApproval<int> loginApprovalUnauthorizedDevice =
    EnumLoginApproval<int>(2);
const EnumLoginApproval<int> loginApprovalUserAccountDoesNotExist =
    EnumLoginApproval<int>(3);
const EnumLoginApproval<int> loginApprovalNotAuthorized =
    EnumLoginApproval<int>(4);
