import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:judica/advocate_home.dart';
import 'package:judica/police_home.dart';
import 'package:judica/user_home.dart';


//changed document name to user email id
class AuthServices {
  final _auth = FirebaseAuth.instance;

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<UserCredential?> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth?.idToken,
        accessToken: googleAuth?.accessToken,
      );
      return await _auth.signInWithCredential(cred);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    return null;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userRoleDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
        String role = userRoleDoc['role'];
        // Navigate to the appropriate home page based on the role
        if (role == 'Citizen') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserHome()),
          );
        } else if (role == 'Advocate') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdvocateHome()),
          );
        } else if (role == 'Police') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PoliceHome()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid user role")),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during Google sign-in: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during Google sign-in: $e")),
      );
    }
  }
}
