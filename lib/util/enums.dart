import 'dart:core';

abstract class Enum<T> {
  final T _value;
  const Enum(this._value);
  T get value => _value;
}


class EnumRsvpState<int> extends Enum<int> {
   const EnumRsvpState(int val) : super (val);
}

const EnumRsvpState<int> rsvpUnknown =  EnumRsvpState<int>(0);
const EnumRsvpState<int> rsvpNo =  EnumRsvpState<int>(1);
const EnumRsvpState<int> rsvpMaybe =  EnumRsvpState<int>(2);
const EnumRsvpState<int> rsvpYes =  EnumRsvpState<int>(3);

//////////////////////////

class EnumIsHare<int> extends Enum<int> {
   const EnumIsHare(int val) : super (val);
}

 const EnumIsHare<int> isHareNo =  EnumIsHare<int>(0);
 const EnumIsHare<int> isHareYes =  EnumIsHare<int>(1);

/////////////////////////


class EnumAttendenceState<int> extends Enum<int> {
   const EnumAttendenceState(int val) : super (val);
}

 const EnumAttendenceState<int> attndenceUnknown =  EnumAttendenceState<int>(0);
 const EnumAttendenceState<int> attendenceNo =  EnumAttendenceState<int>(10);
 const EnumAttendenceState<int> attendenceAtHash =  EnumAttendenceState<int>(20);
 const EnumAttendenceState<int> attendenceOnIn =  EnumAttendenceState<int>(30); 
 const EnumAttendenceState<int> attendenceGone =  EnumAttendenceState<int>(40);

 //////////////////////////

class EnumIsPaid<int> extends Enum<int> {
   const EnumIsPaid(int val) : super (val);
}

 const EnumIsPaid<int> isPaidNo =  EnumIsPaid<int>(0);
 const EnumIsPaid<int> isPaidYes =  EnumIsPaid<int>(1);

