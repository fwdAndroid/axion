import 'package:axion/models/user_models.dart';
import 'package:axion/screen/main/main_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthMethods {
  Future<String> signUpUser({
    required BuildContext context, // Add BuildContext
    required String confirmPassword,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    String res = 'An error occurred';
    try {
      // Check if email is already registered
      List<String> methods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        // Show error message in Scaffold
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is already registered')),
        );
        return 'Email is already registered';
      } else {
        if (email.isNotEmpty && password.isNotEmpty && fullName.isNotEmpty) {
          UserCredential cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          // Add User to the database with model
          UserModel userModel = UserModel(
            uuid: cred.user!.uid,
            phoneNumber: phoneNumber,

            confrimPassword: confirmPassword,

            fullName: fullName,
            email: email,
            password: password,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set(userModel.toJson());

          res = 'success';
          Navigator.push(
            context,
            MaterialPageRoute(builder: (builder) => MainDashboard()),
          );
        }
      }
    } catch (e) {
      res = e.toString();
      // Optionally display the error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
    }
    return res;
  }
}
