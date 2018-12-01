import 'dart:core';

abstract class Enum<T> {
  final T _value;
  const Enum(this._value);
  T get value => _value;
}


class EnumRsvpType<int> extends Enum<int> {
   const EnumRsvpType(int val) : super (val);
}

 EnumRsvpType rsvpUnknown =  EnumRsvpType<int>(0);
 EnumRsvpType rsvpNo =  EnumRsvpType<int>(1);
 EnumRsvpType rsvpMaybe =  EnumRsvpType<int>(2);
 EnumRsvpType rsvpYes =  EnumRsvpType<int>(3);
 EnumRsvpType rsvpHare =  EnumRsvpType<int>(4);