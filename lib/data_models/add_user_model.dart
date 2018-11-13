import 'dart:core';

class AddUserModel {

  final String userId;
  final String qrCode;
  final String qrSecretCode;
  final String displayName;
  final String firstName;
  final String lastName;
  final String hashName;
  final String email;
  final String hasherKennelMapId;
  final String hasherEventMapId;
  final String facebookId;
  final int memberCount;

  AddUserModel(
    {
        this.userId,
        this.qrCode,
        this.qrSecretCode,
        this.displayName,
        this.firstName,
        this.lastName,
        this.hashName,
        this.email,
        this.hasherKennelMapId,
        this.hasherEventMapId,
        this.facebookId,
        this.memberCount

    });

  @override
  String toString() => '$displayName';

}