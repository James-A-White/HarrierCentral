import 'dart:core';

class KennelMemberModel {
  KennelMemberModel(
      {this.hasherId,
      this.hashName,
      this.firstName,
      this.lastName,
      this.displayName,
      this.dispPref,
      this.photo,
      this.qrCode,
      this.qrSecretCode});

  final String hasherId;
  String hashName;
  String firstName;
  String lastName;
  String displayName;
  final int dispPref;
  String photo;
  String qrCode;
  String qrSecretCode;

  @override
  String toString() => '$displayName';
}
