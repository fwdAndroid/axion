import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String email;
  String uuid;
  String password;
  String confrimPassword;
  String phoneNumber;
  String fullName;

  UserModel({
    required this.uuid,
    required this.email,
    required this.fullName,
    required this.password,
    required this.phoneNumber,
    required this.confrimPassword,
  });

  ///Converting OBject into Json Object
  Map<String, dynamic> toJson() => {
    'email': email,
    'uid': uuid,
    'password': password,
    'confrimPassword': confrimPassword,
    'phoneNumber': phoneNumber,
    'fullName': fullName,
  };

  ///
  static UserModel fromSnap(DocumentSnapshot snaps) {
    var snapshot = snaps.data() as Map<String, dynamic>;

    return UserModel(
      email: snapshot['email'],
      uuid: snapshot['uid'],
      password: snapshot['password'],
      confrimPassword: snapshot['confrimPassword'],
      phoneNumber: snapshot['phoneNumber'],

      fullName: snapshot['fullName'],
    );
  }
}
